import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
      appBar: AppBar(
        title: const Text("Top Ordered Books"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, int>>(
        future: getTopBooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No completed orders found"));
          }

          final topBooks = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: topBooks.length,
            itemBuilder: (context, index) {
              final bookName = topBooks.keys.elementAt(index);
              final count = topBooks[bookName];
              print(bookName);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(bookName),
                  trailing: Text(
                    "$count orders",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
