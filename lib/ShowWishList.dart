import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({Key? key}) : super(key: key);

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text("Please login to view your wishlist")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: const Text("My Wishlist"),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('wishlist')
            .doc(userId)
            .collection('items')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ---------- EMPTY UI ----------
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 60,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Your Wishlist is Empty",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Save books you love to see them here",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          final wishlistItems = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: wishlistItems.length,
            itemBuilder: (context, index) {
              final doc = wishlistItems[index];
              final item = doc.data() as Map<String, dynamic>;
              final wishlistId = doc.id;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // ---------- IMAGE ----------
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(18),
                      ),
                      child: SizedBox(
                        width: 95,
                        height: 135,
                        child: item['bookCoverImage'] != null &&
                                item['bookCoverImage'].isNotEmpty
                            ? Image.memory(
                                base64Decode(item['bookCoverImage']),
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.book,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),

                    // ---------- CONTENT ----------
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['bookName'] ?? "No Name",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              "₹${item['bookPrice'] ?? "0"}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple.shade700,
                              ),
                            ),

                            const SizedBox(height: 14),

                            Align(
                              alignment: Alignment.bottomRight,
                              child: InkWell(
                                onTap: () async {
                                  await FirebaseFirestore.instance
                                      .collection('wishlist')
                                      .doc(userId)
                                      .collection('items')
                                      .doc(wishlistId)
                                      .delete();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text("Removed from Wishlist"),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.favorite,
                                        color: Colors.redAccent,
                                        size: 18,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        "Remove",
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
