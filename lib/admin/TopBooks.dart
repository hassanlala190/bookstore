import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TopBooksPage extends StatelessWidget {
  const TopBooksPage({super.key});

  Future<Map<String, int>> getTopBooks() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('status', isEqualTo: 'completed')
        .get();

    Map<String, int> bookCount = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];

      for (var item in items) {
        final bookName = (item as Map<String, dynamic>)['bookName'] ?? 'Unknown';

        if (bookCount.containsKey(bookName)) {
          bookCount[bookName] = bookCount[bookName]! + 1;
        } else {
          bookCount[bookName] = 1;
        }
      }
    }

    // Sort by count descending
    var sortedEntries = bookCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map<String, int>.fromEntries(sortedEntries);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Top Ordered Books",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black87,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black87,
              size: 20,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: FutureBuilder<Map<String, int>>(
        future: getTopBooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black87, Colors.grey[900]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Analyzing Book Orders...",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Error Loading Data",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Unable to fetch order data",
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bar_chart_outlined,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No Order Data",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "No completed orders found to analyze",
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          // Refresh or navigate to orders
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("View Orders"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final topBooks = snapshot.data!;
          final totalOrders = topBooks.values.fold(0, (sum, value) => sum + value);

          return Column(
            children: [
              // Header Stats Card
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black87,
                      Colors.grey[900]!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(
                        Icons.trending_up_outlined,
                        color: Colors.black87,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Top Selling Books",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Based on ${topBooks.length} books with $totalOrders completed orders",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "#1 ${topBooks.keys.first}",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Legend
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildLegendItem(Colors.green[400]!, "High Demand"),
                    const SizedBox(width: 16),
                    _buildLegendItem(Colors.orange[400]!, "Medium Demand"),
                    const SizedBox(width: 16),
                    _buildLegendItem(Colors.blue[400]!, "Low Demand"),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Books List
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView.builder(
                    itemCount: topBooks.length,
                    itemBuilder: (context, index) {
                      final bookName = topBooks.keys.elementAt(index);
                      final count = topBooks[bookName]!;
                      final percentage = (count / totalOrders * 100).toStringAsFixed(1);
                      Color rankColor = _getRankColor(index, topBooks.length);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  rankColor.withOpacity(0.9),
                                  rankColor,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                (index + 1).toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            bookName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              // Progress Bar
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: FractionallySizedBox(
                                  widthFactor: count / topBooks.values.first,
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          rankColor.withOpacity(0.8),
                                          rankColor,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.shopping_cart_outlined,
                                        size: 12,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "$count orders",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "$percentage% of total",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: rankColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Footer Note
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey[600],
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Based on completed orders only. Updated in real-time.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getRankColor(int index, int total) {
    if (index < 3) return Colors.green[400]!; // Top 3 - Green
    if (index < total ~/ 3) return Colors.orange[400]!; // Next 1/3 - Orange
    return Colors.blue[400]!; // Rest - Blue
  }
}