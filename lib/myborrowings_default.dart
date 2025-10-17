// // My Borrowings Page dengan penanganan tipe data yang benar
// class MyBorrowingsPage extends StatelessWidget {
//   Future<String> getCurrentUserName() async {
//     final prefs = await SharedPreferences.getInstance();
//     final userId = prefs.getString('userId');
//     if (userId == null) return 'Unknown';

//     final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
//     if (doc.exists) {
//       final data = doc.data();
//       return data?['username'] ?? 'Unknown';
//     }
//     return 'Unknown';
//   }

//   // Helper method untuk mengkonversi borrowDate yang fleksibel
//   DateTime? parseBorrowDate(dynamic borrowDateData) {
//     try {
//       if (borrowDateData is Timestamp) {
//         return borrowDateData.toDate();
//       } else if (borrowDateData is String) {
//         return DateTime.parse(borrowDateData);
//       } else if (borrowDateData == null) {
//         return DateTime.now(); // fallback ke waktu sekarang
//       }
//     } catch (e) {
//       print('Error parsing date: $e');
//       return DateTime.now(); // fallback ke waktu sekarang jika parsing gagal
//     }
//     return null;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         backgroundColor: Colors.blue[600],
//         title: Text(
//           'Pinjaman Saya',
//           style: GoogleFonts.poppins(
//             color: Colors.white,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         iconTheme: IconThemeData(color: Colors.white),
//       ),
//       body: FutureBuilder<String>(
//         future: getCurrentUserName(),
//         builder: (context, userSnapshot) {
//           if (!userSnapshot.hasData) {
//             return Center(child: CircularProgressIndicator());
//           }

//           return StreamBuilder<QuerySnapshot>(
//             stream: FirebaseFirestore.instance
//                 .collection('borrowed')
//                 .where('by', isEqualTo: userSnapshot.data!)
//                 .snapshots(), // Hapus orderBy untuk menghindari error index
//             builder: (context, snapshot) {
//               if (snapshot.hasError) {
//                 return Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
//                       SizedBox(height: 16),
//                       Text(
//                         'Terjadi kesalahan saat memuat data',
//                         style: GoogleFonts.poppins(
//                           fontSize: 16,
//                           color: Colors.red[600],
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               }

//               if (snapshot.hasData) {
//                 List borrowings = snapshot.data!.docs;

//                 // Sort manual setelah data diterima
//                 borrowings.sort((a, b) {
//                   final aData = a.data() as Map<String, dynamic>;
//                   final bData = b.data() as Map<String, dynamic>;
                  
//                   final aDate = parseBorrowDate(aData['borrowDate']) ?? DateTime.now();
//                   final bDate = parseBorrowDate(bData['borrowDate']) ?? DateTime.now();
                  
//                   return bDate.compareTo(aDate); // descending order
//                 });

//                 if (borrowings.isEmpty) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.assignment_outlined,
//                           size: 80,
//                           color: Colors.grey[400],
//                         ),
//                         SizedBox(height: 16),
//                         Text(
//                           'Belum ada pinjaman',
//                           style: GoogleFonts.poppins(
//                             fontSize: 18,
//                             color: Colors.grey[600],
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }

//                 return ListView.builder(
//                   padding: EdgeInsets.all(16),
//                   itemCount: borrowings.length,
//                   itemBuilder: (context, index) {
//                     final borrowing = borrowings[index].data() as Map<String, dynamic>;
//                     final borrowDate = parseBorrowDate(borrowing['borrowDate']) ?? DateTime.now();
//                     final status = borrowing['status'] ?? 'dipinjam';
                    
//                     return Card(
//                       margin: EdgeInsets.only(bottom: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       elevation: 2,
//                       child: Padding(
//                         padding: EdgeInsets.all(16),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: Text(
//                                     borrowing['productName'] ?? 'Unknown Product',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.grey[800],
//                                     ),
//                                   ),
//                                 ),
//                                 Container(
//                                   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                   decoration: BoxDecoration(
//                                     color: status == 'dipinjam'
//                                         ? Colors.orange[100]
//                                         : status == 'dikembalikan'
//                                         ? Colors.green[100]
//                                         : Colors.grey[100],
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: Text(
//                                     status.toUpperCase(),
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.w600,
//                                       color: status == 'dipinjam'
//                                           ? Colors.orange[800]
//                                           : status == 'dikembalikan'
//                                           ? Colors.green[800]
//                                           : Colors.grey[800],
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             SizedBox(height: 8),
//                             Text(
//                               'Jumlah: ${borrowing['quantity'] ?? 0} unit',
//                               style: GoogleFonts.poppins(
//                                 fontSize: 14,
//                                 color: Colors.grey[600],
//                               ),
//                             ),
//                             SizedBox(height: 4),
//                             Text(
//                               'Dipinjam: ${DateFormat('dd MMM yyyy, HH:mm').format(borrowDate)}',
//                               style: GoogleFonts.poppins(
//                                 fontSize: 14,
//                                 color: Colors.grey[600],
//                               ),
//                             ),
//                             if (borrowing['notes'] != null && borrowing['notes'].toString().isNotEmpty)
//                               Padding(
//                                 padding: EdgeInsets.only(top: 8),
//                                 child: Container(
//                                   padding: EdgeInsets.all(8),
//                                   decoration: BoxDecoration(
//                                     color: Colors.grey[50],
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: Text(
//                                     'Catatan: ${borrowing['notes']}',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 14,
//                                       color: Colors.grey[700],
//                                       fontStyle: FontStyle.italic,
//                                     ),
//                                   ),
//                                 ),
//                               ),
                            
//                             // Return date jika sudah dikembalikan
//                             if (status == 'dikembalikan' && borrowing['returnDate'] != null)
//                               Padding(
//                                 padding: EdgeInsets.only(top: 4),
//                                 child: Text(
//                                   'Dikembalikan: ${DateFormat('dd MMM yyyy, HH:mm').format(parseBorrowDate(borrowing['returnDate']) ?? DateTime.now())}',
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 14,
//                                     color: Colors.green[600],
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               } else {
//                 return Center(
//                   child: CircularProgressIndicator(color: Colors.blue[600]),
//                 );
//               }
//             },
//           );
//         },
//       ),
//     );
//   }
// }