import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String actionFilter = 'all';
  String searchQuery = '';
  String? role;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    });
  }

  String formatCurrency(num value) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
    return 'Rp ${formatter.format(value)}';
  }

  // Action display

  Color _getActionColor(String action) {
    switch (action) {
      case 'item_added':
        return Colors.blue[900]!;
      case 'borrow':
        return Colors.orange[900]!;
      case 'return':
        return Colors.green[700]!;
      case 'item_deleted':
        return Colors.red[700]!;
      case 'item_out':
        return Colors.red[700]!;
      default:
        return Colors.orange[700]!;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'item_added':
        return Icons.add_circle;
      case 'borrow':
        return Icons.inventory;
      case 'return':
        return Icons.check_circle;
      case 'item_deleted':
        return Icons.delete;
      case 'item_out':
        return Icons.exit_to_app;
      default:
        return Icons.edit_outlined;
    }
  }

  String _getActionText(String action) {
    switch (action) {
      case 'item_added':
        return 'Ditambahkan';
      case 'item_deleted':
        return 'Dihapus';
      case 'item_out':
        return 'Barang Keluar';
      case 'update':
        return 'Diperbarui';
      case 'borrow':
        return 'Dipinjam';
      case 'return':
        return 'Dikembalikan';
      default:
        return 'Unknown';
    }
  }

  Future<void> _confirmAndDeleteHistory() async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Hapus Semua Riwayat?",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          "Ini akan menghapus semua history transaksi.",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            child: Text(
              "Batal",
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Hapus",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    final historyCollection = FirebaseFirestore.instance.collection('history');
    final snapshots = await historyCollection.get();

    if (!mounted) return;

    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Semua history berhasil dihapus",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo[500],
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'Riwayat Transaksi',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          if (role == 'admin')
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[600],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_sweep, color: Colors.white, size: 20),
                ),
                tooltip: "Delete all history",
                onPressed: _confirmAndDeleteHistory,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header with search and filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    style: GoogleFonts.poppins(),
                    decoration: InputDecoration(
                      hintText: 'Cari produk...',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.indigo[600]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Filter dropdown
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, color: Colors.indigo[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Filter:",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: actionFilter,
                            style: GoogleFonts.poppins(color: Colors.grey[800]),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text("Semua")),
                              DropdownMenuItem(value: 'item_added', child: Text("Ditambahkan")),
                              DropdownMenuItem(value: 'item_out', child: Text("Barang Keluar")),
                              DropdownMenuItem(value: 'item_deleted', child: Text("Dihapus")),
                              DropdownMenuItem(value: 'borrow', child: Text("Dipinjam")),
                              DropdownMenuItem(value: 'return', child: Text("Dikembalikan")),
                            ],
                            onChanged: (value) {
                              if (value != null) setState(() => actionFilter = value);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // History list
          Expanded(
            child: _isInitialLoading ? Center(
              child: Lottie.network(
                'https://lottie.host/e4db3417-45c2-437f-a49f-d273726a12bf/9q4nGsLcOT.json'
              ),
            ) :
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('history')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: Lottie.network(
                      'https://lottie.host/e4db3417-45c2-437f-a49f-d273726a12bf/9q4nGsLcOT.json'
                    ),
                  );
                }

                // Item Display
                final allDocs = snapshot.data!.docs;
                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data();
                  final productName = (data['name'] ?? data['item_name'] ?? '').toString().toLowerCase();
                  final action = data['action'];

                  final matchesSearch = productName.contains(searchQuery);
                  final matchesFilter = actionFilter == 'all' || action == actionFilter;
                  return matchesSearch && matchesFilter;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Tidak ada transaksi",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Belum ada aktivitas yang tercatat",
                          style: GoogleFonts.poppins(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data();
                    final product = data['name'] ?? data['item_name'] ?? '';
                    final action = data['action'] ?? '';
                    final quantity = data['amount'] ?? 0;
                    final sku = data['sku']?? data['item_sku'] ?? 'No SKU';
                    final timestamp = (data['timestamp'] as Timestamp).toDate();
                    final user = data['by'] ?? data['user'] ?? data['user_email'] ?? 'Unknown';

                    final actionText = _getActionText(action);
                    final actionColor = _getActionColor(action);
                    final actionIcon = _getActionIcon(action);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Action icon
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: actionColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: actionColor.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                actionIcon,
                                color: actionColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product name
                                  Text(
                                    product,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  // Action and quantity
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: actionColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          actionText,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: actionColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (quantity > 0 || (quantity == 0 && actionText != 'Updated'))
                                        Text(
                                          '$quantity unit',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      if (quantity == 0 && actionText == 'Updated')
                                        Text(
                                          'Stok habis',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.red[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Details like SKU
                                  Row(
                                    children: [
                                      Tooltip(
                                        message: sku,
                                          child: SizedBox(
                                            width: 200,
                                            child: Text(
                                              'Sku: $sku',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Timestamp and user
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          DateFormat('dd MMM yyyy, HH:mm').format(timestamp),
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.indigo.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'by: $user',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.indigo[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}