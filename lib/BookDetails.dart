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

  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    CartService.loadInitialCartCount();
  }

  // ---------------- OPEN REVIEW DIALOG ----------------
  void _openReviewDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
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
                      i < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setState(() => _rating = i + 1);
                    },
                  );
                }),
              ),
              TextField(
                controller: _reviewController,
                maxLines: 3,
                decoration:
                    const InputDecoration(hintText: "Write your review"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => _submitReview(dialogContext),
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  // ---------------- SUBMIT REVIEW ----------------
  Future<void> _submitReview(BuildContext dialogContext) async {
    if (userId == null) return;

    if (_rating == 0 || _reviewController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add rating & review")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('reviews').add({
      'bookId': widget.docId,
      'userId': userId,
      'rating': _rating,
      'description': _reviewController.text,
      'createdAt': FieldValue.serverTimestamp(), // null-safe
    });

    _rating = 0;
    _reviewController.clear();

    Navigator.pop(dialogContext);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Review added successfully")),
    );
  }

  // ---------------- STAR WIDGET ----------------
  Widget _stars(double rating) {
    return Row(
      children: List.generate(5, (i) {
        if (i + 1 <= rating) {
          return const Icon(Icons.star, color: Colors.amber, size: 18);
        } else if (i + 0.5 <= rating) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 18);
        } else {
          return const Icon(Icons.star_border, size: 18);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(data['bookName']),
        backgroundColor: Colors.deepPurple,
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: CartService.cartCountNotifier,
            builder: (_, count, __) => Stack(
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
                    child: CircleAvatar(
                      radius: 9,
                      backgroundColor: Colors.red,
                      child: Text(
                        '$count',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white),
                      ),
                    ),
                  )
              ],
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 250, child: _buildBookImage(data)),
            const SizedBox(height: 15),

            _detail("Author", data['bookAuthor']),
            _detail("Category", data['bookCategory']),
            _detail("Language", data['bookLanguage']),
            _detail("Price", "₹${data['bookPrice']}"),
            _detail(
              "Stock",
              data['bookStock'] == "Yes" ? "In Stock" : "Out of Stock",
            ),

            const SizedBox(height: 10),
            Text(data['bookDescription'] ?? ""),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.rate_review),
                label: const Text("Write Review"),
                onPressed: _openReviewDialog,
              ),
            ),

            const SizedBox(height: 25),

            // ---------------- AVERAGE RATING ----------------
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .where('bookId', isEqualTo: widget.docId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text("No ratings yet");
                }

                double avg = snapshot.data!.docs
                        .map((e) => e['rating'] as int)
                        .reduce((a, b) => a + b) /
                    snapshot.data!.docs.length;

                return Row(
                  children: [
                    _stars(avg),
                    const SizedBox(width: 8),
                    Text(avg.toStringAsFixed(1)),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),
            const Text(
              "Reviews",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // ---------------- REVIEWS WITH REAL USER NAME ----------------
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .where('bookId', isEqualTo: widget.docId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Text("No reviews yet");
                }

                // Sort locally by createdAt descending
                List docs = snapshot.data!.docs.toList();
                docs.sort((a, b) {
                  Timestamp ta = a['createdAt'] ?? Timestamp(0, 0);
                  Timestamp tb = b['createdAt'] ?? Timestamp(0, 0);
                  return tb.compareTo(ta); // descending
                });

                return Column(
                  children: docs.map((doc) {
                    final review = doc.data() as Map<String, dynamic>;
                    final reviewUserId = review['userId'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(reviewUserId)
                          .get(),
                      builder: (context, userSnap) {
                        String userName = "User";

                        if (userSnap.hasData && userSnap.data!.exists) {
                          userName = userSnap.data!['name'] ?? "User";
                        }

                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.deepPurple,
                              child:
                                  Icon(Icons.person, color: Colors.white),
                            ),
                            title: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(userName),
                                Row(
                                  children: List.generate(
                                    review['rating'],
                                    (_) => const Icon(Icons.star,
                                        size: 14, color: Colors.amber),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(review['description'] ?? ""),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text("$title: ",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildBookImage(Map<String, dynamic> data) {
    if (kIsWeb && data['bookCoverImage'] != null) {
      return Image.memory(
        base64Decode(data['bookCoverImage']),
        fit: BoxFit.cover,
      );
    } else if (!kIsWeb && data['bookCoverImage'] != null) {
      return FutureBuilder<File>(
        future: _getImageFile(data['bookCoverImage']),
        builder: (_, snapshot) {
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
