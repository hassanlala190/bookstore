import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookstore/admin/book_edit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class ShowBooksPage extends StatefulWidget {
  @override
  _ShowBooksPageState createState() => _ShowBooksPageState();
}

class _ShowBooksPageState extends State<ShowBooksPage> {
  FirebaseFirestore db = FirebaseFirestore.instance;

  void showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red[800] : Colors.green[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _deleteBook(DocumentSnapshot doc) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_outlined, color: Colors.red[700]),
            const SizedBox(width: 10),
            Text(
              "Delete Book?",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete '${doc['bookName']}'? This action cannot be undone.",
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.red[50],
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.red[700],
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Delete"),
            ),
          ),
        ],
      ),
    );
    
    if (confirm) {
      try {
        await db.collection("books").doc(doc.id).delete();
        showMessage("Book deleted successfully!");
      } catch (e) {
        showMessage("Delete error: $e", isError: true);
      }
    }
  }

  void _showFullDescription(String bookName, String description) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black87,
                    Colors.grey[900]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bookName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Book Description",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Description Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<File> _getImageFile(String imagePath) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String fullPath = '${appDocDir.path}/$imagePath';
    return File(fullPath);
  }

  Widget _buildBookImage(Map<String, dynamic> data) {
    if (data['bookCoverImage'] != null && data['bookCoverImage']!.isNotEmpty) {
      if (kIsWeb && data['is_web'] == true) {
        return Image.memory(
          base64Decode(data['bookCoverImage']!),
          width: 80,
          height: 100,
          fit: BoxFit.cover,
        );
      } else {
        return FutureBuilder<File>(
          future: _getImageFile(data['bookCoverImage']!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.grey[600],
                  ),
                ),
              );
            }
            if (snapshot.hasData) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  snapshot.data!,
                  width: 80,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              );
            }
            return _buildDefaultBookCover();
          },
        );
      }
    }
    return _buildDefaultBookCover();
  }

  Widget _buildDefaultBookCover() {
    return Container(
      width: 80,
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black87,
            Colors.grey[900]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          Icons.menu_book,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "All Books",
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
      body: StreamBuilder<QuerySnapshot>(
        stream: db
            .collection("books")
            .orderBy("createdAt", descending: true)
            .snapshots(),
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
                    "Loading Books...",
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

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
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
                      Icons.menu_book_outlined,
                      color: Colors.grey[400],
                      size: 64,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "No Books Found",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Add new books to see them listed here",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final books = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final doc = books[index];
              final data = doc.data() as Map<String, dynamic>;
              final createdAt = data['createdAt'] as Timestamp?;
              final formattedDate = createdAt != null
                  ? DateFormat('MMM dd, yyyy').format(createdAt.toDate())
                  : "N/A";

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: _buildBookCard(doc, data, formattedDate, index),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBookCard(DocumentSnapshot doc, Map<String, dynamic> data, String formattedDate, int index) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with ID and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "ID: ${index + 1}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Book Info Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book Cover
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildBookImage(data),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Book Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['bookName'] ?? "Unknown Book",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Price
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green[100]!),
                          ),
                          child: Text(
                            "₹${data['bookPrice']?.toStringAsFixed(2) ?? '0.00'}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Author and Category
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _bookDetailRow(
                                    icon: Icons.person_outline,
                                    label: "Author",
                                    value: data['bookAuthor'] ?? '-',
                                  ),
                                  const SizedBox(height: 6),
                                  _bookDetailRow(
                                    icon: Icons.category_outlined,
                                    label: "Category",
                                    value: data['bookCategory'] ?? '-',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _bookDetailRow(
                                    icon: Icons.language_outlined,
                                    label: "Language",
                                    value: data['bookLanguage'] ?? '-',
                                  ),
                                  const SizedBox(height: 6),
                                  _bookDetailRow(
                                    icon: Icons.inventory_outlined,
                                    label: "Stock",
                                    value: data['bookStock'] ?? '-',
                                    isStock: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Description Preview
              if (data['bookDescription'] != null && data['bookDescription']!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Description",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data['bookDescription']!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showFullDescription(
                          data['bookName'] ?? "Book",
                          data['bookDescription']!,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Read Full Description",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.blue[700],
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Action Buttons
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue[700]!,
                              Colors.blue[900]!,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookEditPage(
                                  bookId: doc.id,
                                  bookData: data,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            "Edit Book",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red[300]!),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.red[50],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _deleteBook(doc),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.red[700],
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                          ),
                          label: const Text(
                            "Delete",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bookDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isStock = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey[600],
          size: 14,
        ),
        const SizedBox(width: 6),
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: isStock 
                  ? (value == 'Yes' ? Colors.green[700] : Colors.red[700])
                  : Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}