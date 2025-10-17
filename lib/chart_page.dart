import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/homepage.dart';

class ChartPage extends StatefulWidget {
  ChartPage({super.key});

  final Color dark = Colors.indigo;
  final Color normal = Colors.indigo[400]!;
  final Color light = Colors.indigo[200]!;

  @override
  State<StatefulWidget> createState() => ChartPageState();
}

class ChartPageState extends State<ChartPage> {
  Map<String, int> categoryBorrowCount = {};
  List<String> categoryNames = [];
  List<Map<String, dynamic>> topBorrowedItems = [];
  bool isLoading = true;
  String? userName;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadUserInfo();
    await _loadChartData();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('username') ?? 'User';
    });
  }

  // Get User
  Future<String> getCurrentUserName() async {
    if (userName != null) return userName!;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? 'Unknown';
  }

  // Load data dari Firebas

  Future<void> _loadChartData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = prefs.getString('username') ?? 'Unknown';
      // Get borrowing frequency per category dari history
      final historySnapshot = await FirebaseFirestore.instance
          .collection('borrowed')
          .where('status', isEqualTo: 'dikembalikan')
          .where('by', isEqualTo: currentUser)
          .get();

      Map<String, int> tempCategoryCount = {};
      Map<String, Map<String, dynamic>> itemBorrowData = {};

      for (var doc in historySnapshot.docs) {
        final data = doc.data();
        final category = data['category'] ?? 'Unknown';
        final itemName = data['productName'] ?? '';
        final amount = data['amount'] ?? 1;
        final sku = data['sku'] ?? '';
        final productId = data['productId'] ?? '';

        // Count per category
        tempCategoryCount[category] = (tempCategoryCount[category] ?? 0) + 1;

        // Count per item untuk top borrowed
        final itemKey = '$sku-$itemName';
        if (itemBorrowData.containsKey(itemKey)) {
          itemBorrowData[itemKey]!['count'] =
              (itemBorrowData[itemKey]!['count'] as int) + 1;
          itemBorrowData[itemKey]!['totalAmount'] =
              (itemBorrowData[itemKey]!['totalAmount'] as int) + amount;
        } else {
          itemBorrowData[itemKey] = {
            'productId' : productId,
            'productName': itemName,
            'sku': sku,
            'category': category,
            'count': 1,
            'totalAmount': amount,
          };
        }
      }

      // Sort categories by borrow count
      var sortedCategories = tempCategoryCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Take top 5 categories for chart
      setState(() {
        categoryNames = sortedCategories.take(5).map((e) => e.key).toList();

        for (String cat in categoryNames) {
          categoryBorrowCount[cat] = tempCategoryCount[cat] ?? 0;
        }

        // Get top 3 borrowed items
        var sortedItems = itemBorrowData.values.toList()
          ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

        topBorrowedItems = sortedItems.take(3).toList();
        isLoading = false;
      });
    } catch (e) {
      // print('Error loading chart data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 10);

    if (value.toInt() >= categoryNames.length) {
      return const SizedBox.shrink();
    }

    String text = categoryNames[value.toInt()];
    // Truncate long category names
    if (text.length > 8) {
      text = '${text.substring(0, 6)}...';
    }

    return SideTitleWidget(
      meta: meta,
      child: Text(text, style: style),
    );
  }

  Widget leftTitles(double value, TitleMeta meta) {
    if (value == meta.max) {
      return Container();
    }
    const style = TextStyle(fontSize: 10);
    return SideTitleWidget(
      meta: meta,
      child: Text(value.toInt().toString(), style: style),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Chart Peminjaman'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Title
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Frekuensi Peminjaman per Kategori',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Chart
                  categoryBorrowCount.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text('Belum ada data peminjaman'),
                          ),
                        )
                      : Center(
                          child: AspectRatio(
                            aspectRatio: 1.66,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceEvenly,
                                  maxY: getMaxY(),
                                  barTouchData: BarTouchData(
                                    enabled: true,
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipItem:
                                          (group, groupIndex, rod, rodIndex) {
                                            String category =
                                                categoryNames[group.x.toInt()];
                                            return BarTooltipItem(
                                              '$category\n',
                                              const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              children: <TextSpan>[
                                                TextSpan(
                                                  text:
                                                      '${rod.toY.toInt()} kali',
                                                  style: const TextStyle(
                                                    color: Colors.yellow,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 28,
                                        getTitlesWidget: bottomTitles,
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        getTitlesWidget: leftTitles,
                                      ),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: 1,
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: Colors.grey.withValues(
                                          alpha: 0.2,
                                        ),
                                        strokeWidth: 1,
                                      );
                                    },
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barGroups: getBarGroups(),
                                ),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeInOut,
                              ),
                            ),
                          ),
                        ),

                  const SizedBox(height: 50),

                  // Quick Access Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.indigo[400],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    width: double.infinity,
                    child: const Text(
                      'Akses Cepat - Barang Sering Dipinjam',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Top Borrowed Items
                  if (topBorrowedItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Belum ada data barang yang dipinjam'),
                    )
                  else
                    ...topBorrowedItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),

                        // Card for each item
                        child: Card(
                          elevation: 2,
                          child: ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.indigo,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              item['productName'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SKU: ${item['sku'] ?? '-'}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  'Kategori: ${item['category'] ?? '-'}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.indigo[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${item['count']}x',
                                    style: TextStyle(
                                      color: Colors.indigo[800],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'dipinjam',
                                    style: TextStyle(
                                      color: Colors.indigo[600],
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {
                              // Navigate to item detail or borrow page
                              final cat = item['category'] ?? '';
                              final docId = item['productId'] ?? '';
                              final name = item['productName'] ?? '';
                              final sku = item['sku'] ?? '';
                              final imageUrl = item['imageUrl'] ?? '';

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
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Refresh button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          isLoading = true;
                        });
                        _loadChartData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Data'),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  double getMaxY() {
    if (categoryBorrowCount.isEmpty) return 10;

    int maxValue = categoryBorrowCount.values.reduce(
      (max, value) => value > max ? value : max,
    );

    // Round up to nearest 5 or 10
    if (maxValue <= 10) return 10;
    if (maxValue <= 20) return 20;
    if (maxValue <= 50) return 50;
    return (maxValue / 10).ceil() * 10.0;
  }

  List<BarChartGroupData> getBarGroups() {
    return List.generate(categoryNames.length, (index) {
      final count = categoryBorrowCount[categoryNames[index]] ?? 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            gradient: LinearGradient(
              colors: [widget.dark, widget.normal, widget.light],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 40,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    });
  }
}
