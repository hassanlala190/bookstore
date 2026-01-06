import 'package:bookstore/admin/add_category.dart';
import 'package:bookstore/admin/category_edit.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ShowCategoryPage extends StatelessWidget {
  // Firestore instance
  FirebaseFirestore db = FirebaseFirestore.instance;

  // Show message function
  void showMessage(BuildContext context, String message, {bool isError = false}) {
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

  // Function to delete a category
  Future<void> _deleteCategory(BuildContext context, String categoryId, String categoryName) async {
    try {
      await db.collection('categories').doc(categoryId).delete();
      showMessage(context, "'$categoryName' deleted successfully");
    } catch (e) {
      showMessage(context, "Error deleting category: $e", isError: true);
    }
  }

  // Function to show delete confirmation dialog
  void _showDeleteDialog(BuildContext context, String categoryId, String categoryName) {
    showDialog(
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
              "Delete Category?",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete '$categoryName'? This action cannot be undone.",
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
              onPressed: () {
                _deleteCategory(context, categoryId, categoryName);
                Navigator.pop(context);
              },
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "All Categories",
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
        actions: [
          Container(
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
                Icons.add,
                color: Colors.black87,
                size: 20,
              ),
              onPressed: () {
                // Navigate to Add Category Page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddCategoryPage()),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Stats
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
                    Icons.category_outlined,
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
                        "Categories Overview",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StreamBuilder<QuerySnapshot>(
                        stream: db.collection("categories").snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Text(
                              "Loading categories...",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            );
                          }
                          final count = snapshot.data!.docs.length;
                          return Text(
                            "Total $count ${count == 1 ? 'category' : 'categories'} in library",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Categories List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StreamBuilder<QuerySnapshot>(
                stream: db.collection("categories").orderBy("created_at", descending: true).snapshots(),
                builder: (context, snapshot) {
                  // Check for loading state
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
                            "Loading Categories...",
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

                  // Check for errors
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
                              "Error Loading Categories",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${snapshot.error}",
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

                  // Check if no data is found
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                              Icons.category_outlined,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No Categories Found",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Add your first category to get started",
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
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
                              child: ElevatedButton(
                                onPressed: () {
                                  // Navigate to Add Category Page
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => AddCategoryPage()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  "Add New Category",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  var categories = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      var category = categories[index];
                      String categoryId = category.id;
                      String categoryName = category['name'] ?? 'No name';
                      Timestamp createdAt = category['created_at'] ?? Timestamp.now();
                      DateTime dateTime = createdAt.toDate();
                      String formattedDate = DateFormat('MMM dd, yyyy').format(dateTime);

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
                            vertical: 12,
                          ),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey[900]!,
                                  Colors.black87,
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            categoryName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 12,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Added: $formattedDate",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Edit button
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: Colors.grey[700],
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CategoryEditPage(
                                          categoryId: categoryId,
                                          categoryData: category.data() as Map<String, dynamic>,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Delete button
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red[300]!),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.red[700],
                                  ),
                                  onPressed: () {
                                    _showDeleteDialog(context, categoryId, categoryName);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black87,
              Colors.grey[900]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            // Navigate to Add Category Page
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(builder: (context) => AddCategoryPage()),
            // );
          },
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}