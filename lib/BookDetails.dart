import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class BookDetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const BookDetailsPage({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(data['bookName'] ?? "Book Details"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Image
            Center(
              child: SizedBox(
                height: 250,
                child: _buildBookImage(data),
              ),
            ),

            const SizedBox(height: 20),

            _detail("Author", data['bookAuthor']),
            _detail("Category", data['bookCategory']),
            _detail("Language", data['bookLanguage']),
            _detail("Price", "₹${data['bookPrice']}"),
            _detail(
              "Stock",
              data['bookStock'] == "Yes" ? "In Stock" : "Out of Stock",
            ),

            const SizedBox(height: 20),

            Text(
              "Description",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              data['bookDescription'] ?? "No description available",
              style: TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 30),

            // Add to Cart Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart),
                label: const Text("Add to Cart"),
                onPressed: () {
                  // yahan cart logic add kar sakte ho
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Added to cart")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildBookImage(Map<String, dynamic> data) {
    if (kIsWeb &&
        data['bookCoverImage'] != null &&
        data['bookCoverImage'].isNotEmpty) {
      return Image.memory(
        base64Decode(data['bookCoverImage']),
        fit: BoxFit.cover,
      );
    } else if (!kIsWeb &&
        data['bookCoverImage'] != null &&
        data['bookCoverImage'].isNotEmpty) {
      return FutureBuilder<File>(
        future: _getImageFile(data['bookCoverImage']),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.file(snapshot.data!, fit: BoxFit.cover);
          }
          return const Icon(Icons.book, size: 100);
        },
      );
    }
    return const Icon(Icons.book, size: 100);
  }

  Future<File> _getImageFile(String imagePath) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$imagePath');
  }
}
