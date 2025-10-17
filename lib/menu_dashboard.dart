import 'package:flutter/material.dart';
import 'package:user_app/chart_page.dart';
import 'package:user_app/homepage.dart';
import 'package:user_app/history_page.dart';
import 'package:user_app/firebase_services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import 'package:intl/intl.dart';
import 'package:user_app/notification_service.dart';
import 'package:user_app/user_interface.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  TextEditingController searchController = TextEditingController();
  String searchText = '';

  // Gradient Animation
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;

  // Greeting Method
  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "Selamat Pagi";
    } else if (hour >= 12 && hour < 17) {
      return "Selamat Siang";
    } else if (hour >= 17 && hour < 19) {
      return "Selamat Sore";
    } else {
      return "Selamat Malam";
    }
  }

  List<String> categories = [];
  String? selectedFilterCategory;
  String selectedCategory = '';
  String? role;
  String? userName;
  int totalBorrowedItems = 0;
  int totalAvailableItems = 0;

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            _controller.reset();
            _controller.forward();
          }
        });
      }
    });

    _controller.forward();

    FirestoreServices().getCategories().listen((catList) {
      setState(() {
        categories = catList.map((cat) => cat.name).toList();
        categoryIcons = {for (var cat in catList) cat.name: cat.icon};
      });
    });
    _loadRole();
    _loadUserInfo();
    _loadStats();
  }

  void _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      role = prefs.getString('role') ?? 'user';
    });
  }

  void _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('username') ?? 'User';
    });
  }

  // New method to get real-time borrowed items count
  Stream<int> _getBorrowedItemsStream() async* {
    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('username') ?? '';

    yield* FirebaseFirestore.instance
        .collection('borrowed')
        .where('by', isEqualTo: currentUsername)
        .where('status', isEqualTo: 'dipinjam')
        .snapshots()
        .map((snaphsot) {
          int total = 0;
          for (var doc in snaphsot.docs) {
            final data = doc.data();
            total += (data['amount'] ?? 0) as int;
          }
          return total;
        });
  }

  // New method to get real-time available items count
  Stream<int> _getAvailableItemsStream() {
    return FirebaseFirestore.instance.collectionGroup('items').snapshots().map((
      snapshot,
    ) {
      final Set<String> categories = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = data['amount'];

        if (amount > 0) {
          final categoryId = doc.reference.parent.parent?.id;
          if (categoryId != null) {
            categories.add(categoryId);
          }
        }
      }
      return categories.length;
    });
  }

  void _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserName = prefs.getString('username') ?? '';

      // Get total borrowed items by current user
      final borrowedSnapshot = await FirebaseFirestore.instance
          .collection('borrowed')
          .where('by', isEqualTo: currentUserName)
          .where('status', isEqualTo: 'dipinjam')
          .get();

      // Get total available items
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('items')
          .get();

      int availableCount = 0;
      for (var doc in productsSnapshot.docs) {
        final data = doc.data();
        final quantity = data['amount'] ?? 0;
        if (quantity > 0) {
          availableCount++;
        }
      }

      setState(() {
        totalBorrowedItems = borrowedSnapshot.docs.length;
        totalAvailableItems = availableCount;
      });
    } catch (e) {
      // print('Error loading stats: $e');
    }
  }

  String hello = '23';

  Map<String, IconData> categoryIcons = {};

  // Get User
  Future<String> getCurrentUserName() async {
    if (userName != null) return userName!;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? 'Unknown';
  }

  // Admin only - Add Product Dialog
  void showAddProductDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController merkController = TextEditingController();
    final TextEditingController skuController = TextEditingController();
    String selectedCategory = categories.isNotEmpty ? categories.first : '';
    final firestoreServices = FirestoreServices();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Tambah Produk",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Nama Produk',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  controller: controller,
                  style: GoogleFonts.poppins(),
                ),
                SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'SKU',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  controller: skuController,
                  style: GoogleFonts.poppins(),
                ),
                SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Jumlah',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  controller: quantityController,
                  style: GoogleFonts.poppins(),
                ),
                SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Merk',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  controller: merkController, // Harga
                  style: GoogleFonts.poppins(),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: categories.contains(selectedCategory)
                      ? selectedCategory
                      : null,
                  items: categories
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(
                            cat.toUpperCase(),
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    selectedCategory = value!;
                  },
                  decoration: InputDecoration(
                    hintText: 'Kategori',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Batal", style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final product = controller.text.trim();
                final quantity =
                    int.tryParse(quantityController.text.trim()) ?? 0;
                final merk = merkController.text.trim();
                final sku = skuController.text.trim();
                final byId = await getCurrentUserName();

                if (product.isNotEmpty && sku.isNotEmpty) {
                  await firestoreServices.addProduct(
                    product,
                    quantity,
                    sku,
                    selectedCategory,
                    '',
                    byId,
                    merk: merk,
                    hasCustomImage: true,
                  );
                  _loadStats();
                }

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text(
                "Tambah",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          height: 150,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.indigo[700]!, Colors.indigo[700]!],
            ),
          ),
        ),
        title: Text(
          '\n ${getGreeting()} ${userName ?? 'User'}👋',
          style: GoogleFonts.interTight(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            // shadows: [
            //   Shadow(
            //     offset: Offset(2, 2),
            //     blurRadius: 4,
            //     color: Colors.black26,
            //   ),]
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: IconButton(
              // 3 dots menu
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {
                showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(
                    MediaQuery.of(context).size.width - 100,
                    kToolbarHeight,
                    0,
                    0,
                  ),
                  items: [
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: const [
                          Icon(Icons.logout, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ],
                ).then((value) {
                  if (value == 'logout') {
                    _logout();
                  }
                });
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Layer 2: gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  if (role == 'admin') ...[
                    Colors.indigo[400]!,
                    Colors.indigo[300]!,
                    Colors.indigo[50]!,
                  ] else if (role == 'user') ...[
                    Colors.indigo[300]!,
                    Colors.indigo[200]!,
                    Colors.indigo[50]!,
                  ] else ...[
                    Colors.indigo[300]!,
                    Colors.indigo[100]!,
                  ],
                ],
              ),
            ),
          ),

          // Layer 1: solid color overlay at top
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.indigo[700]!,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
          ),

          SingleChildScrollView(
            child: Column(
              children: [
                // Welcome Header Section
                AnimatedBuilder(
                  animation: _shimmerAnimation,
                  builder: (context, _) {
                    return Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(-1, 1),
                          end: Alignment(1, -1),
                          stops: [
                            (_shimmerAnimation.value - 0.25).clamp(0.0, 1.0),
                            (_shimmerAnimation.value - 0.08).clamp(0.0, 1.0),
                            _shimmerAnimation.value.clamp(0.0, 1.0),
                            (_shimmerAnimation.value + 0.08).clamp(0.0, 1.0),
                            (_shimmerAnimation.value + 0.25).clamp(0.0, 1.0),
                          ],
                          // Color gradient card
                          colors: [
                            if (role == 'user') ...[
                              Colors.indigo[400]!,
                              Colors.indigo[200]!, // indigo lebih muda
                              Colors.indigo[100]!, // indigo sangat muda
                              Colors.indigo[200]!, // indigo lebih muda
                              Colors.indigo[400]!,
                            ],
                            if (role == 'admin') ...[
                              Color(0xFF1A237E),
                              Color(0xFF283593),
                              Colors.indigo[300]!,
                              Color(0xFF283593),
                              Color(0xFF1A237E),
                            ],
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          if (role == 'admin')
                            BoxShadow(
                              color: Colors.indigo.withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 2),
                            ),
                          if (role == 'user')
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: role == 'admin'
                                  ? Colors.indigo[400]
                                  : Colors.indigo[300],
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/icons/logo_mertani_baru_warna.png',
                                //size: 28,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mertani Borrow App',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: (userName!.length >= 5) ? 17 : 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  role == 'admin'
                                      ? 'Kelola barang dengan mudah'
                                      : 'Pinjam barang yang Anda butuhkan',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Stats Cards (User specific)
                if (role == 'user' || role == 'admin')
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: StreamBuilder<int>(
                            stream: _getBorrowedItemsStream(),
                            builder: (context, snapshot) {
                              final borrowedCount = snapshot.data ?? 0;
                              return Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 10,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.assignment_outlined,
                                      size: 32,
                                      color: Colors.orange[600],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '$borrowedCount',
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[600],
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Sedang Dipinjam',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: StreamBuilder<int>(
                            stream: _getAvailableItemsStream(),
                            builder: (context, snapshot) {
                              final availableCount = snapshot.data ?? 0;
                              return Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 10,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 32,
                                      color: Colors.green[600],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '$availableCount',
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[600],
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Kategori Tersedia',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 24),

                // Quick Access Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        role == 'admin' ? 'Kelola Inventori' : 'Akses Cepat',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(2, 2),
                              blurRadius: 4,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                          );
                        },
                        icon: Icon(
                          // arrow
                          Icons.arrow_forward,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Lihat Semua',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(2, 2),
                                blurRadius: 4,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Menu Grid
                if (categories.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                      children: [
                        // Categories
                        ...categories.map((cat) {
                          final icon = categoryIcons[cat] ?? Icons.category;
                          return _buildGridItem(
                            context,
                            cat,
                            icon,
                            Colors.indigo[400]!,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HomePage(
                                    selectedCategoryFromOutside: cat,
                                  ),
                                ),
                              );
                            },
                          );
                        }),

                        // User interface
                        if (role == 'admin')
                          _buildGridItem(
                            context,
                            'Users',
                            Icons.people,
                            Colors.purple,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserPage(),
                                ),
                              );
                            },
                          ),

                        // Graphic chart
                        _buildGridItem(
                          context,
                          'Chart',
                          Icons.bar_chart,
                          Colors.purple,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChartPage(),
                              ),
                            );
                          },
                        ),

                        // History
                        _buildGridItem(
                          context,
                          'Riwayat',
                          Icons.history,
                          Colors.purple[600]!,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HistoryPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 50), // Space for FAB
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: role == 'alien'
          ? SpeedDial(
              icon: Icons.add,
              activeIcon: Icons.close,
              backgroundColor: Colors.blue[400],
              foregroundColor: Colors.white,
              overlayOpacity: 0.4,
              children: [
                SpeedDialChild(
                  child: const Icon(Icons.category),
                  label: 'Kelola Kategori',
                  backgroundColor: Colors.blue[400],
                  foregroundColor: Colors.white,
                  onTap: () {
                    Navigator.pushNamed(context, '/category');
                  },
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.only(bottom: 70),
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MyBorrowingsPage(userName: userName, isSelf: true),
                    ),
                  );
                },
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                icon: Icon(Icons.assignment_outlined),
                label: Text(
                  'Pinjaman Saya',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  flex: 2,
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// My Borrowings Page (jika belum ada)
class MyBorrowingsPage extends StatelessWidget {
  final String? userName;
  final bool isSelf;

  const MyBorrowingsPage({
    super.key,
    required this.userName,
    this.isSelf = false,
  });

  // Get User
  Future<String> getCurrentUserName() async {
    if (userName != null && userName!.isNotEmpty) {
      return userName!;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return 'Unknown';

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    if (doc.exists) {
      final data = doc.data();
      return data?['username'] ?? 'Unknown';
    }
    return 'Unknown';
  }

  DateTime? parseBorrowDate(dynamic borrowDateData) {
    try {
      if (borrowDateData is Timestamp) {
        return borrowDateData.toDate();
      } else if (borrowDateData is String) {
        return DateTime.parse(borrowDateData);
      } else if (borrowDateData == null) {
        return DateTime.now();
      }
    } catch (e) {
      return DateTime.now();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: Text(
          'Pinjaman $userName',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<String>(
        future: getCurrentUserName(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('borrowed')
                .where('by', isEqualTo: userSnapshot.data!)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                List borrowings = snapshot.data!.docs;

                borrowings.sort((a, b) {
                  final aDate =
                      (a['borrowDate'] as Timestamp?)?.toDate() ?? DateTime(0);
                  final bDate =
                      (b['borrowDate'] as Timestamp?)?.toDate() ?? DateTime(0);
                  return bDate.compareTo(aDate);
                });

                if (borrowings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada pinjaman',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Borrowing notes card
                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: borrowings.length,
                  itemBuilder: (context, index) {
                    // Testing active status
                    final doc = borrowings[index];
                    final borrowing =
                        borrowings[index].data() as Map<String, dynamic>;
                    final borrowDate =
                        parseBorrowDate(borrowing['borrowDate']) ??
                        DateTime.now();
                    final status = borrowing['status'] ?? 'borrow';
                    final productId = borrowing['productId'] ?? '';
                    final returnAmount = borrowing['amount'] ?? 0;
                    final productName =
                        borrowing['productName'] ?? 'Unknown Product';

                    // Last three index for "Pinjam Lagi" button
                    final isLastThree = index < 3;

                    // active status
                    final activeStatus = borrowings.any((otherDoc) {
                      final other = otherDoc.data() as Map<String, dynamic>;
                      final otherStatus = (other['status'] ?? '')
                          .toString()
                          .trim()
                          .toLowerCase();
                      return otherStatus == 'dipinjam';
                    });

                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    productName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: status == 'dipinjam'
                                        ? Colors.indigo[100]
                                        : Colors.green[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: status == 'dipinjam'
                                          ? Colors.indigo[400]
                                          : Colors.green[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Jumlah: ${borrowing['amount']} unit',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Dipinjam: ${DateFormat('dd MMM yyyy, HH:mm').format(borrowDate)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),

                                Spacer(),

                                // Second Borrowing Page Button
                                if (status == 'dikembalikan' &&
                                    isLastThree &&
                                    !activeStatus &&
                                    isSelf)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 24,
                                      top: 8,
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        final cat = borrowing['category'] ?? '';
                                        final docId =
                                            borrowing['productId'] ?? '';
                                        final name =
                                            borrowing['productName'] ?? '';
                                        final sku = borrowing['sku'] ?? '';
                                        final imageUrl =
                                            borrowing['imageUrl'] ?? '';

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => HomePage(
                                              selectedCategoryFromOutside: cat,
                                              openBorrowDialogOnStart: true,
                                              borrowDialogData: {
                                                'docId': docId,
                                                'productName': name,
                                                'sku': sku,
                                                'category': cat,
                                                'imageUrl': imageUrl,
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Pinjam Lagi'),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 12),

                            if (borrowing['notes'] != null &&
                                borrowing['notes'].toString().isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Catatan: ${borrowing['notes']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),

                            if (status == 'dipinjam' && isSelf == true) ...[
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  // Return Button
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green[600],
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 16,
                                        ),
                                        elevation: 2,
                                      ),
                                      icon: Icon(
                                        Icons.keyboard_return,
                                        size: 18,
                                      ),
                                      label: Text(
                                        'Kembalikan',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      onPressed: () async {
                                        final firestore = FirestoreServices();

                                        if (productId.isEmpty) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Gagal: Id tidak ditemukan',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        await firestore.returnProduct(
                                          categoryId:
                                              borrowing['category'] ?? '',
                                          docId:
                                              borrowing['productId'] ??
                                              'Unknown Product',
                                          returnAmount: returnAmount,
                                        );

                                        await FirebaseFirestore.instance
                                            .collection('borrowed')
                                            .doc(doc.id)
                                            .update({'status': 'dikembalikan'});

                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context);
                                        toastification.show(
                                          style:
                                              ToastificationStyle.flatColored,
                                          icon: Icon(Icons.check),
                                          backgroundColor: Colors.green[200],
                                          foregroundColor: Colors.green,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          context: context,
                                          title: Text(
                                            'Barang berhasil dikembalikan',
                                          ),
                                          autoCloseDuration: const Duration(
                                            seconds: 3,
                                          ),
                                          dragToClose: true,
                                        );

                                        final username =
                                            await getCurrentUserName();
                                        NotificationService()
                                            .updateReminderNotification(
                                              username,
                                            );
                                      },
                                    ),
                                  ),

                                  SizedBox(width: 12),

                                  // Extend Button
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigo[400],
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 16,
                                        ),
                                        elevation: 2,
                                      ),
                                      icon: Icon(Icons.access_time, size: 18),
                                      label: Text(
                                        'Perpanjang',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      onPressed: () async {
                                        if (productId.isEmpty) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Gagal: Id tidak ditemukan',
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        // Resetting Scheduler
                                        final username =
                                            await getCurrentUserName();

                                        NotificationService()
                                            .cancelNotification(100);
                                        NotificationService()
                                            .cancelNotification(101);
                                        NotificationService()
                                            .scheduleBorrowingNotifications(
                                              username: username,
                                              testing: true,
                                            );

                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context);
                                        toastification.show(
                                          style:
                                              ToastificationStyle.flatColored,
                                          icon: Icon(Icons.check),
                                          backgroundColor: Colors.green[200],
                                          foregroundColor: Colors.green,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          context: context,
                                          title: Text(
                                            'Barang berhasil diperpanjang',
                                          ),
                                          autoCloseDuration: const Duration(
                                            seconds: 3,
                                          ),
                                          dragToClose: true,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              } else {
                return Center(
                  child: CircularProgressIndicator(color: Colors.blue[400]),
                );
              }
            },
          );
        },
      ),
    );
  }
}
