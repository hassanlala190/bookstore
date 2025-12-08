import 'package:bookstore/admin/category_edit.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShowCategoryPage extends StatelessWidget {
  // Firestore instance
  FirebaseFirestore db = FirebaseFirestore.instance;

  // Function to delete a category
  Future<void> _deleteCategory(BuildContext context, String categoryId) async {
    try {
      await db.collection('categories').doc(categoryId).delete();
      // Show success message after deletion
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Category deleted successfully")));
    } catch (e) {
      // Show error message if deletion fails
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting category")));
    }
  }

  // Function to show delete confirmation dialog
  void _showDeleteDialog(BuildContext context, String categoryId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Are you sure?'),
          content: Text('Do you really want to delete this category?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteCategory(context, categoryId);
                Navigator.pop(context); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Show Categories"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: db.collection("categories").orderBy("created_at").snapshots(),
          builder: (context, snapshot) {
            // Check for loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            // Check for errors
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            // Check if no data is found
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text("No categories found"));
            }

            var categories = snapshot.data!.docs;

            return ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                var category = categories[index];
                String categoryId = category.id;  // Get the category ID
                String categoryName = category['name'] ?? 'No name';
                Timestamp createdAt = category['created_at'] ?? Timestamp.now();
                DateTime dateTime = createdAt.toDate();

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    title: Text(categoryName),
                    subtitle: Text("Created on: ${dateTime.toLocal()}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit button
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            // Navigate to the category edit page
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
                        // Delete button
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            _showDeleteDialog(context, categoryId);
                          },
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
    );
  }
}
