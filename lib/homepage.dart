import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:user_app/firebase_services.dart';
import 'package:toastification/toastification.dart';
// import 'package:flutter_application_2/history_page.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/notification_service.dart';

class HomePage extends StatefulWidget {
  final bool openAddForm;
  final String? selectedCategoryFromOutside;
  final bool openBorrowDialogOnStart;
  final Map<String, dynamic>? borrowDialogData;
  const HomePage({
    super.key,
    this.openAddForm = false,
    this.openBorrowDialogOnStart = false,
    this.borrowDialogData,
    this.selectedCategoryFromOutside,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController controller = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  TextEditingController skuController = TextEditingController();
  TextEditingController imageUrlController = TextEditingController();
  TextEditingController borrowQuantityController = TextEditingController();
  TextEditingController borrowNotesController = TextEditingController();
  TextEditingController takeQuantityController = TextEditingController();
  TextEditingController takeNotesController = TextEditingController();

  String searchText = '';
  String? selectedFilterCategory;
  String selectedCategory = '';
  String? role;
  String? imageUrl;
  String? currentUsername;
  final picker = ImagePicker();
  bool _isInitialLoading = true;

  FirestoreServices firestoreServices = FirestoreServices();
  List<String> categories = [];

  // Get User
  Future<String> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? 'Unknown';
  }

  // Show Borrow Dialog
  Future<void> showBorrowDialog(
    String productName,
    String docId,
    int availableQuantity,
    String sku,
    String category,
    String imageUrl,
  ) async {
    borrowQuantityController.clear();
    borrowNotesController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.shopping_bag_outlined, color: Colors.indigo[600]),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pinjam Barang',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo[800],
                  ),
                ),
              ),
            ],
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Info Card
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tersedia: $availableQuantity unit',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Quantity Input
              TextField(
                controller: borrowQuantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jumlah yang dipinjam',
                  hintText: 'Masukkan jumlah (max: $availableQuantity)',
                  prefixIcon: Icon(Icons.numbers, color: Colors.indigo[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.indigo[600]!,
                      width: 2,
                    ),
                  ),
                ),
                style: GoogleFonts.poppins(),
              ),
              SizedBox(height: 16),

              // Notes Input
              TextField(
                controller: borrowNotesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Catatan (opsional)',
                  hintText: 'Keperluan peminjaman...',
                  prefixIcon: Icon(
                    Icons.note_alt_outlined,
                    color: Colors.indigo[600],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.indigo[600]!,
                      width: 2,
                    ),
                  ),
                ),
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final borrowQty =
                    int.tryParse(borrowQuantityController.text.trim()) ?? 0;
                final notes = borrowNotesController.text.trim();

                if (borrowQty <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Masukkan jumlah yang valid'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (borrowQty > availableQuantity) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Jumlah melebihi stok tersedia'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final borrowerName = await getCurrentUsername();

                  // Add borrow record
                  await FirebaseFirestore.instance.collection('borrowed').add({
                    'productName': productName,
                    'productId': docId,
                    'sku': sku,
                    'category': category,
                    'amount': borrowQty,
                    'by': borrowerName,
                    'borrowDate': Timestamp.now(),
                    'status': 'dipinjam',
                    'notes': notes,
                    'imageUrl': imageUrl,
                  });

                  // Update product quantity
                  await firestoreServices.borrowProduct(
                    categoryId: category,
                    docId: sku,
                    borrowAmount: borrowQty,
                  );

                  final username = await getCurrentUsername();

                  // Scheduler
                  // NotificationService().cancelNotification(100);
                  // NotificationService().cancelNotification(101);
                  NotificationService().cancelAllNotifications();
                  NotificationService().scheduleBorrowingNotifications(
                    username: username, testing: true
                  );
                  // NotificationService().updateReminderNotification(username);

                  if (!context.mounted) return;
                  Navigator.pop(context); // borrowQty, productName
                  toastification.show(
                    style: ToastificationStyle.flatColored,
                    icon: Icon(Icons.check),
                    backgroundColor: Colors.green[200],
                    foregroundColor: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                    context: context,
                    title: Text('Berhasil meminjam $borrowQty $productName'),
                    autoCloseDuration: const Duration(seconds: 3),
                    dragToClose: true,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal meminjam barang: $e'),
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: EdgeInsets.all(12),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[500],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.check_circle_outline),
              label: Text(
                'Pinjam',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show Take Dialog
  Future<void> showTakeDialog(
    String productName,
    String docId,
    int availableQuantity,
    String sku,
    String category,
    String imageUrl,
  ) async {
    takeQuantityController.clear();
    takeNotesController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.shopping_bag_outlined, color: Colors.indigo[500]),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ambil Barang',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo[800],
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Info Card
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tersedia: $availableQuantity unit',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Quantity Input
              TextField(
                controller: takeQuantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jumlah yang dipinjam',
                  hintText: 'Masukkan jumlah (max: $availableQuantity)',
                  prefixIcon: Icon(Icons.numbers, color: Colors.indigo[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.indigo[600]!,
                      width: 2,
                    ),
                  ),
                ),
                style: GoogleFonts.poppins(),
              ),
              SizedBox(height: 16),

              // Notes Input
              TextField(
                controller: takeNotesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Catatan (opsional)',
                  hintText: 'Keperluan peminjaman...',
                  prefixIcon: Icon(
                    Icons.note_alt_outlined,
                    color: Colors.indigo[600],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.indigo[600]!,
                      width: 2,
                    ),
                  ),
                ),
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final takeQty =
                    int.tryParse(takeQuantityController.text.trim()) ?? 0;
                // final notes = takeNotesController.text.trim();

                if (takeQty <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Masukkan jumlah yang valid'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (takeQty > availableQuantity) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Jumlah melebihi stok tersedia'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  // Delete product quantity
                  await firestoreServices.takeProduct(
                    categoryId: category,
                    docId: sku,
                    borrowAmount: takeQty,
                  );

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Berhasil ambil $takeQty $productName'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal ambil barang: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[500],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.check_circle_outline),
              label: Text(
                'Ambil',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    getCurrentUsername();

    // Load categories
    firestoreServices.getCategories().listen((catList) {
      setState(() {
        categories = catList.map((cat) => cat.name).toList();
        if (widget.selectedCategoryFromOutside != null &&
            categories.contains(widget.selectedCategoryFromOutside)) {
          selectedFilterCategory = widget.selectedCategoryFromOutside!;
        }
      });
    });

    firestoreServices.seedDefaultCategories();
    _loadRole();
  }

  void _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      role = prefs.getString('role') ?? 'user';
    });

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    });

    // Showborrow dialog outside
    if (widget.openBorrowDialogOnStart && widget.borrowDialogData != null) {
      Future.delayed(const Duration(milliseconds: 1800), () async {
        if (mounted) {

          final docId = widget.borrowDialogData!['docId'] ?? '';
          final category = widget.borrowDialogData!['category'] ?? '';

          final docSnapshot = await FirebaseFirestore.instance
            .collection('categories')
            .doc(category)
            .collection('items')
            .doc(docId)
            .get();

          final availableQuantity = docSnapshot.data()?['amount'] ?? 0;

          showBorrowDialog(
            widget.borrowDialogData!['productName'] ?? 'Unknown',
            widget.borrowDialogData!['docId'] ?? '',
            availableQuantity,
            widget.borrowDialogData!['sku'] ?? '',
            widget.borrowDialogData!['category'] ?? '',
            widget.borrowDialogData!['imageUrl'] ?? '',
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo[500],
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          selectedFilterCategory != null
              ? 'Kategori: ${selectedFilterCategory!}'
              : 'Pinjam Barang',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Cari barang yang ingin dipinjam...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.indigo[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: GoogleFonts.poppins(),
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
            ),
          ),

          // Products Grid
          Expanded(
            child: _isInitialLoading
                ? Center(
                    child: Lottie.network(
                      'https://lottie.host/e4db3417-45c2-437f-a49f-d273726a12bf/9q4nGsLcOT.json',
                    ),
                  )
                : StreamBuilder(
                    stream: selectedFilterCategory == null
                        ? FirestoreServices().showProducts()
                        : FirestoreServices().getItemsByCategoryId(
                            selectedFilterCategory!,
                          ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        List productList = snapshot.data!.docs;

                        // Filter products
                        productList = productList.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = (data['name'] ?? data['item'] ?? '')
                              .toString()
                              .toLowerCase();
                          // final category = data['category']?.toString().toLowerCase() ?? '';
                          final quantity = data['amount'] ?? 0;

                          final matchesSearch =
                              searchText.isEmpty || name.contains(searchText);
                          final matchesCategory =
                              selectedFilterCategory == null ||
                              name.contains(searchText);
                          // category == selectedFilterCategory!.toLowerCase();
                          final hasStock = quantity > 0;

                          return matchesSearch && matchesCategory && hasStock;
                        }).toList();

                        if (productList.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Tidak ada barang tersedia',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Semua barang sedang dipinjam atau stok kosong',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        return GridView.builder(
                          padding: EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.65,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: productList.length,
                          itemBuilder: (context, index) {
                            DocumentSnapshot document = productList[index];
                            String docId = document.id;
                            Map<String, dynamic> data =
                                document.data() as Map<String, dynamic>;

                            String product =
                                data['name']?.toString() ?? 'No Name';
                            String sku = data['sku']?.toString() ?? 'No SKU';
                            String category =
                                selectedFilterCategory ??
                                (document.reference.parent.parent?.id ??
                                    'Uncategorized');
                            int quantity = data['amount'] ?? 0;
                            String imageUrl =
                                data['imageUrl']?.toString() ?? '';

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Image
                                  Expanded(
                                    flex: role == 'admin' ? 6 : 4,
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16),
                                        ),
                                      ),
                                      child: imageUrl.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                    top: Radius.circular(16),
                                                  ),
                                              child: Image.network(
                                                imageUrl,
                                                height: 140,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                loadingBuilder:
                                                    (
                                                      context,
                                                      child,
                                                      loadingProgress,
                                                    ) {
                                                      if (loadingProgress ==
                                                          null) {
                                                        return child;
                                                      } else {
                                                        return Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                                color: Colors
                                                                    .indigo[600],
                                                              ),
                                                        );
                                                      }
                                                    },
                                                errorBuilder:
                                                  (context, error, stackTrace,) => 
                                                  Icon(
                                                    Icons.image_not_supported,
                                                    size: 40,
                                                    color: Colors.grey[400],
                                                  ),
                                              ),
                                            )
                                          : Icon(
                                              Icons.inventory_2_outlined,
                                              size: 40,
                                              color: Colors.indigo[600],
                                            ),
                                    ),
                                  ),

                                  // Product Info
                                  Expanded(
                                    flex: role == 'admin' ? 10 : 4,
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product,
                                            style: GoogleFonts.poppins(
                                              fontSize: product.length > 18
                                                  ? 10
                                                  : 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[800],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),

                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: quantity > 0
                                                  ? Colors.green[50]
                                                  : Colors.red[50],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: quantity > 0
                                                    ? Colors.green[200]!
                                                    : Colors.red[200]!,
                                                width: 0.5,
                                              ),
                                            ),
                                            child: Text(
                                              'Tersedia: $quantity',
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                color: quantity > 0
                                                    ? Colors.green[600]
                                                    : Colors.red[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: product.length > 18
                                                ? 10
                                                : 8,
                                          ),

                                          // Borrow Button
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: quantity > 0
                                                  ? () {
                                                      HapticFeedback.lightImpact();
                                                      showBorrowDialog(
                                                        product,
                                                        docId,
                                                        quantity,
                                                        sku,
                                                        category,
                                                        imageUrl,
                                                      );
                                                    }
                                                  : null,

                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.indigo[500],
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 6,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              icon: Icon(
                                                Icons.shopping_bag_outlined,
                                                size: 14,
                                              ),
                                              label: Text(
                                                'Pinjam',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),

                                          // Take Button
                                          if (role == 'admin')
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                onPressed: quantity > 0
                                                    ? () {
                                                        HapticFeedback.lightImpact();
                                                        showTakeDialog(
                                                          product,
                                                          docId,
                                                          quantity,
                                                          sku,
                                                          category,
                                                          imageUrl,
                                                        );
                                                      }
                                                    : null,

                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.indigo[500],
                                                  foregroundColor: Colors.white,
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 6,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                                icon: Icon(
                                                  Icons.back_hand_outlined,
                                                  size: 14,
                                                ),
                                                label: Text(
                                                  'Ambil',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      } else {
                        return Center(
                          child: Lottie.network(
                            'https://lottie.host/e4db3417-45c2-437f-a49f-d273726a12bf/9q4nGsLcOT.json',
                          ),
                        );
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
