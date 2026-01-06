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
  int _tempRating = 0; // For dialog stars
  final TextEditingController _reviewController = TextEditingController();
  bool _isWishlisted = false;

  @override
  void initState() {
    super.initState();
    CartService.loadInitialCartCount();
    _checkWishlistStatus();
  }

  // ---------------- CHECK WISHLIST STATUS ----------------
  Future<void> _checkWishlistStatus() async {
    if (userId == null) return;

    final ref = FirebaseFirestore.instance
        .collection('wishlist')
        .doc(userId)
        .collection('items')
        .doc(widget.docId);

    final doc = await ref.get();
    if (mounted) {
      setState(() {
        _isWishlisted = doc.exists;
      });
    }
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

    try {
      if (_isWishlisted) {
        await ref.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Removed from Wishlist")),
        );
      } else {
        await ref.set({
          "bookId": widget.docId,
          "bookName": widget.data['bookName'] ?? "",
          "bookPrice": widget.data['bookPrice'] ?? "",
          "bookCoverImage": widget.data['bookCoverImage'] ?? "",
          "createdAt": FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Added to Wishlist")),
        );
      }
      setState(() {
        _isWishlisted = !_isWishlisted;
      });
    } catch (e) {
      debugPrint("Wishlist error: $e");
    }
  }

  // ---------------- OPEN REVIEW DIALOG ----------------
  void _openReviewDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Write Review",
                  style: TextStyle(color: Colors.black87)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Stars with proper state management
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _tempRating = i + 1;
                          });
                        },
                        child: Icon(
                          i < _tempRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 40,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _tempRating == 0
                        ? "Tap to rate"
                        : "${_tempRating} Star${_tempRating > 1 ? 's' : ''}",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reviewController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Write your review...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
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
                  child: const Text("Cancel",
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () => _submitReview(dialogContext, _tempRating),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Submit",
                      style: TextStyle(color: Colors.white)),
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

    if (rating == 0 || _reviewController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add rating & review")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('reviews').add({
      'bookId': widget.docId,
      'userId': userId,
      'rating': rating,
      'description': _reviewController.text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _tempRating = 0;
    _reviewController.clear();

    Navigator.pop(dialogContext);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Review added successfully")),
    );
  }

  // ---------------- STAR WIDGET FOR DISPLAY ----------------
  Widget _stars(double rating) {
    return Row(
      children: List.generate(5, (i) {
        if (i + 1 <= rating) {
          return const Icon(Icons.star, color: Colors.amber, size: 20);
        } else if (i + 0.5 <= rating) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 20);
        } else {
          return const Icon(Icons.star_border, color: Colors.grey, size: 20);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          data['bookName'] ?? "Book Details",
          style: const TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: CartService.cartCountNotifier,
            builder: (context, count, _) {
              return Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.shopping_cart, color: Colors.black87),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Image - Adjusted for portrait images
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 300, // Adjusted for portrait
                  width: double.infinity,
                  color: Colors.grey[200],
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
                    color: Colors.black.withOpacity(0.05),
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
                      color: Colors.black87,
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
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ---------------- AVERAGE RATING ----------------
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .where('bookId', isEqualTo: widget.docId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox();
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Ratings & Reviews",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "No ratings yet",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  );
                }

                double avg = docs
                        .map((e) => e['rating'] as int)
                        .reduce((a, b) => a + b) /
                    docs.length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Ratings & Reviews",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _stars(avg),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              avg.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              "${docs.length} review${docs.length > 1 ? 's' : ''}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // ---------------- WRITE REVIEW BUTTON ----------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.rate_review, size: 20),
                label: const Text(
                  "Write a Review",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                onPressed: _openReviewDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),

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
                              // FIXED: Compare by book ID (widget.docId)
                              bool alreadyInCart = cartList
                                  .any((item) => item['id'] == widget.docId);

                              if (alreadyInCart) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Book already in cart"),
                                  ),
                                );
                                return;
                              }

                              final cartItem = {
                                "uuid": DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString(),
                                "id": widget.docId, // Use widget.docId as book ID
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
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: data['bookStock'] == "Yes"
                            ? Colors.black87
                            : Colors.grey,
                        foregroundColor: Colors.white,
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
                    onPressed: _toggleWishlist,
                    icon: Icon(
                      _isWishlisted ? Icons.favorite : Icons.favorite_border,
                      color: _isWishlisted ? Colors.white : Colors.redAccent,
                    ),
                    label: Text(
                      _isWishlisted ? "Wishlisted" : "Wishlist",
                      style: TextStyle(
                        color: _isWishlisted ? Colors.white : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: _isWishlisted
                            ? Colors.transparent
                            : Colors.redAccent,
                      ),
                      backgroundColor:
                          _isWishlisted ? Colors.redAccent : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // ---------------- REVIEWS ----------------
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .where('bookId', isEqualTo: widget.docId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                    color: Colors.black87,
                  ));
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Container(); // Already handled above
                }

                // Sort by date descending
                List sortedDocs = docs.toList()
                  ..sort((a, b) {
                    Timestamp ta = a['createdAt'] ?? Timestamp(0, 0);
                    Timestamp tb = b['createdAt'] ?? Timestamp(0, 0);
                    return tb.compareTo(ta);
                  });

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      "Customer Reviews",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: sortedDocs.map((doc) {
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

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          userName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Row(
                                          children: List.generate(
                                            5,
                                            (i) => Icon(
                                              Icons.star,
                                              size: 18,
                                              color: i < review['rating']
                                                  ? Colors.amber
                                                  : Colors.grey[300],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      review['description'] ?? "",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _formatTimestamp(review['createdAt']),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ---------------- HELPERS ----------------
  Widget _detail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$title:",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "";
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return "Today";
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} days ago";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }

  Widget _buildBookImage(Map<String, dynamic> data) {
    if (kIsWeb &&
        data['bookCoverImage'] != null &&
        data['bookCoverImage'].isNotEmpty) {
      return Center(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: 300,
            maxWidth: 200, // Portrait constraint
          ),
          child: Image.memory(
            base64Decode(data['bookCoverImage']),
            fit: BoxFit.contain,
          ),
        ),
      );
    } else if (!kIsWeb &&
        data['bookCoverImage'] != null &&
        data['bookCoverImage'].isNotEmpty) {
      return FutureBuilder<File>(
        future: _getImageFile(data['bookCoverImage']),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Center(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: 300,
                  maxWidth: 200, // Portrait constraint
                ),
                child: Image.file(
                  snapshot.data!,
                  fit: BoxFit.contain,
                ),
              ),
            );
          }
          return const Center(
            child: Icon(Icons.book, size: 100, color: Colors.grey),
          );
        },
      );
    }
    return const Center(
      child: Icon(Icons.book, size: 100, color: Colors.grey),
    );
  }

  Future<File> _getImageFile(String imagePath) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$imagePath');
  }
}