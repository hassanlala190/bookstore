import 'dart:convert';
import 'dart:io';
import 'package:bookstore/cart_Service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'cart_page.dart';

class BookDetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const BookDetailsPage({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(data['bookName'] ?? "Book Details"),
        backgroundColor: Colors.deepPurple,
        actions: [
          FutureBuilder<int>(
            future: CartService.getCartCount(),
            builder: (context, snapshot) {
              int count = snapshot.data ?? 0;
              return Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartPage()),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Book image
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: _buildBookImage(data),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Book details card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detail("Author", data['bookAuthor']),
                  _detail("Category", data['bookCategory']),
                  _detail("Language", data['bookLanguage']),
                  _detail("Price", "₹${data['bookPrice']}"),
                  _detail("Stock", data['bookStock'] == "Yes" ? "In Stock" : "Out of Stock"),
                  const SizedBox(height: 16),
                  Text(
                    "Description",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['bookDescription'] ?? "No description available",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Add to Cart button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart),
                label: const Text("Add to Cart", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final cartItem = {
                    "uuid": DateTime.now().millisecondsSinceEpoch.toString(),
                    "id": data['id'],
                    "bookName": data['bookName'],
                    "bookPrice": data['bookPrice'],
                    "bookCoverImage": data['bookCoverImage'],
                    "quantity": 1,
                  };
                  await CartService.addToCart(cartItem);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Book added to cart")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          Text("$title: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black54))),
        ],
      ),
    );
  }

  Widget _buildBookImage(Map<String, dynamic> data) {
    if (kIsWeb && data['bookCoverImage'] != null && data['bookCoverImage'].isNotEmpty) {
      return Image.memory(base64Decode(data['bookCoverImage']), fit: BoxFit.cover);
    } else if (!kIsWeb && data['bookCoverImage'] != null && data['bookCoverImage'].isNotEmpty) {
      return FutureBuilder<File>(
        future: _getImageFile(data['bookCoverImage']),
        builder: (context, snapshot) {
          if (snapshot.hasData) return Image.file(snapshot.data!, fit: BoxFit.cover);
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
