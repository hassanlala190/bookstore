import 'dart:convert';
import 'dart:io';

import 'package:bookstore/cart_Service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'cart_page.dart';

class BookDetailsPage extends StatefulWidget {
  final Map<String, dynamic> data;
final String docId; // <-- Add this

  const BookDetailsPage({Key? key, required this.data, required this.docId}) : super(key: key);

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    CartService.loadInitialCartCount();
    print(widget.docId);
  }

  // ---------------- ADD TO WISHLIST ----------------
 Future<void> _addToWishlist(Map<String, dynamic> data) async {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please login first")),
    );
    return;
  }

  final ref = FirebaseFirestore.instance
      .collection('wishlist')
      .doc(userId)
      .collection('items')
      .doc(widget.docId);

  try {
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        "bookId": widget.docId,
        "bookName": data['bookName'] ?? "",
        "bookPrice": data['bookPrice'] ?? "",
        "bookCoverImage": data['bookCoverImage'] ?? "",
        "createdAt": FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Added to Wishlist")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Already in Wishlist")),
      );
    }
  } catch (e) {
    debugPrint("Wishlist error: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(data['bookName'] ?? "Book Details"),
        backgroundColor: Colors.deepPurple,
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: CartService.cartCountNotifier,
            builder: (context, count, _) {
              return Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CartPage(),
                        ),
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
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
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
            // Book Image
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
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

            // Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detail("Author", data['bookAuthor']),
                  _detail("Category", data['bookCategory']),
                  _detail("Language", data['bookLanguage']),
                  _detail("Price", "₹${data['bookPrice']}"),
                  _detail(
                    "Stock",
                    data['bookStock'] == "Yes" ? "In Stock" : "Out of Stock",
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Description",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['bookDescription'] ?? "No description available",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                    Text(
                     data["id"]?? "No description available",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

          // ---------------- ADD TO CART + WISHLIST ----------------
Row(
  children: [
    // Add to Cart Button
    Expanded(
      flex: 3,
      child: SizedBox(
        height: 50,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.shopping_cart),
          label: const Text(
            "Add to Cart",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: data['bookStock'] == "Yes"
              ? () async {
                  final cartList = await CartService.getCart();
                  bool alreadyInCart =
                      cartList.any((item) => item['id'] == data['id']);

                  if (alreadyInCart) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Book already in cart"),
                      ),
                    );
                    return;
                  }

                  final cartItem = {
                    "uuid":
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    "id": data['id'],
                    "bookName": data['bookName'],
                    "bookPrice": data['bookPrice'],
                    "bookCoverImage": data['bookCoverImage'] ?? "",
                    "quantity": 1,
                  };

                  await CartService.addToCart(cartItem);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Book added to cart"),
                    ),
                  );
                }
              : null, // disabled if out of stock
          style: ElevatedButton.styleFrom(
            backgroundColor: data['bookStock'] == "Yes"
                ? Colors.deepPurple
                : Colors.grey, // color change
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    ),

    const SizedBox(width: 12),

    // Wishlist Button
    SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () {
          _addToWishlist(data); // aapki existing wishlist function
        },
        icon: const Icon(Icons.favorite_border, color: Colors.redAccent),
        label: const Text(
          "Wishlist",
          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.redAccent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),
  ],
),

          ],
        ),
      ),
    );
  }

  // ---------------- HELPERS ----------------
  Widget _detail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
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
