import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_application_2/firebase_services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ProductByCategoryPage extends StatelessWidget{
  final String categoryName;

  const ProductByCategoryPage({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Produk:  ${categoryName.toUpperCase()}')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
        .collection('products')
        .where('category', isEqualTo: categoryName)
        .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Error loading products');
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
    // to order category by timestamp
        final docs = snapshot.data!.docs
        .where((doc) => doc['timestamp'] != null)
        .toList()
        ..sort((a, b) {
          final ta = a['timestamp'] as Timestamp;
          final tb = b['timestamp'] as Timestamp;
          return tb.compareTo(ta);
        });

        if (docs.isEmpty) {
          return const Center(child:  Text('No products in this category'));
        }

      return ListView.builder(
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final data = docs[index].data() as Map<String, dynamic>;
          final product = data ['product'] ?? 'Unknown';
          final sku = data['sku'] ?? '-';
          final qty = data['quantity'] ?? 0;
          final price = data['price'] ?? 0.0;
          final timestamp = data['timestamp'] as Timestamp?;
          final formattedTime = timestamp != null
              ? DateFormat('dd MMMM yyyy, HH:mm').format(timestamp.toDate())
               : '-';

          return ListTile(
            title: Text(product, style: GoogleFonts.alexandria(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text('SKU: $sku'),
                  Text('Jumlah: $qty'),
                  Text('Harga: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(price)}'),
                  Text('Ditambahkan: $formattedTime', style: TextStyle(color: Colors.grey[600], fontSize: 12)),               
              ],
            ),
            isThreeLine: true,
          );
        },
      );
      },
     ) );
  }}