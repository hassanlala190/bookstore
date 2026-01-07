import 'dart:convert';
import 'dart:io';

import 'package:bookstore/cart_Service.dart';
import 'package:bookstore/cart_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class BookDetailsPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;

  const BookDetailsPage({
    Key? key,
    required this.data,
    required this.docId,
  }) : super(key: key);

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  final TextEditingController _reviewController = TextEditingController();

  bool _isWishlisted = false;
  int _tempRating = 0;

  @override
  void initState() {
    super.initState();
    CartService.loadInitialCartCount();
    _checkWishlistStatus();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  // ---------------- CHECK WISHLIST ----------------
  Future<void> _checkWishlistStatus() async {
    if (userId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('wishlist')
        .doc(userId)
        .collection('items')
        .doc(widget.docId)
        .get();

    if (!mounted) return;
    setState(() => _isWishlisted = doc.exists);
  }

  // ---------------- TOGGLE WISHLIST ----------------
  Future<void> _toggleWishlist() async {
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

    if (_isWishlisted) {
      await ref.delete();
    } else {
      await ref.set({
        'bookId': widget.docId,
        'bookName': widget.data['bookName'],
        'bookPrice': widget.data['bookPrice'],
        'bookCoverImage': widget.data['bookCoverImage'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (!mounted) return;
    setState(() => _isWishlisted = !_isWishlisted);
  }

  // ---------------- ADD TO CART ----------------
  Future<void> _addToCart() async {
    await CartService.addToCart({
      'id': widget.docId,
      'bookName': widget.data['bookName'],
      'bookPrice': widget.data['bookPrice'],
      'bookCoverImage': widget.data['bookCoverImage'],
      'quantity': 1,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Added to Cart")),
    );
  }

  // ---------------- REVIEW DIALOG ----------------
  void _openReviewDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setStateDialog) {
            return AlertDialog(
              title: const Text("Write Review"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return IconButton(
                        icon: Icon(
                          i < _tempRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setStateDialog(() => _tempRating = i + 1);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reviewController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: "Write your review...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _tempRating = 0;
                    _reviewController.clear();
                    Navigator.pop(dialogContext);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () =>
                      _submitReview(dialogContext, _tempRating),
                  child: const Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------- SUBMIT REVIEW ----------------
  Future<void> _submitReview(
      BuildContext dialogContext, int rating) async {
    if (userId == null) return;

    if (rating == 0 || _reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add rating & review")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('reviews').add({
      'bookId': widget.docId,
      'userId': userId,
      'rating': rating,
      'description': _reviewController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    _tempRating = 0;
    _reviewController.clear();

    if (!mounted) return;
    Navigator.pop(dialogContext);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Review added successfully")),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Scaffold(
      appBar: AppBar(
        title: Text(data['bookName'] ?? "Book"),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: CartService.cartCountNotifier,
            builder: (_, count, __) {
              return Stack(
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
                      child: CircleAvatar(
                        radius: 9,
                        backgroundColor: Colors.red,
                        child: Text(
                          "$count",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 300, child: _buildBookImage(data)),
            const SizedBox(height: 20),

            _detail("Author", data['bookAuthor'] ?? ""),
            _detail("Category", data['bookCategory'] ?? ""),
            _detail("Language", data['bookLanguage'] ?? ""),
            _detail("Price", "₹${data['bookPrice']}"),
            _detail(
              "Stock",
              data['bookStock'] == "Yes" ? "In Stock" : "Out of Stock",
            ),

            const SizedBox(height: 20),
            Text(data['bookDescription'] ?? ""),

            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: _addToCart,
              child: const Text("Add to Cart"),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _toggleWishlist,
              child: Text(_isWishlisted ? "Wishlisted" : "Wishlist"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _openReviewDialog,
              child: const Text("Write Review"),
            ),

            const SizedBox(height: 25),
            _reviewsSection(),
          ],
        ),
      ),
    );
  }

  // ---------------- REVIEWS ----------------
  Widget _reviewsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('bookId', isEqualTo: widget.docId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (_, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Text("No reviews yet");
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: docs.map((doc) {
            final r = doc.data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text("Rating: ${r['rating']}"),
                subtitle: Text(r['description']),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ---------------- HELPERS ----------------
  Widget _detail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              "$title:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildBookImage(Map<String, dynamic> data) {
    if (data['bookCoverImage'] == null || data['bookCoverImage'].isEmpty) {
      return const Icon(Icons.book, size: 120);
    }

    final bytes = base64Decode(data['bookCoverImage']);

    if (kIsWeb) {
      return Image.memory(bytes, fit: BoxFit.contain);
    }

    return FutureBuilder<File>(
      future: _getImageFile(data['bookCoverImage']),
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          return Image.file(snapshot.data!, fit: BoxFit.contain);
        }
        return Image.memory(bytes, fit: BoxFit.contain);
      },
    );
  }

  Future<File> _getImageFile(String path) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$path');
  }
}
