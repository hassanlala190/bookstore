import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddCategoryPage extends StatefulWidget {
  @override
  _AddCategoryPageState createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  TextEditingController categoryController = TextEditingController();

  // Firestore instance
  FirebaseFirestore db = FirebaseFirestore.instance;

  // Show message function
  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // Add category function
  void addCategory() async {
    String category = categoryController.text.trim();

    if (category.isEmpty) {
      showMessage("Category is required");
      return;
    }

    try {
      // Add category to Firestore
      await db.collection("categories").add({
        "name": category,
        "created_at": DateTime.now(),
      });

      showMessage("Category added successfully");

      // Clear the field
      categoryController.clear();
    } catch (e) {
      showMessage("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Category"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Add New Category",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // Category name field
            TextField(
              controller: categoryController,
              decoration: InputDecoration(
                labelText: "Enter Category Name",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
            ),
            SizedBox(height: 20),

            // Add button
            ElevatedButton(
              onPressed: addCategory,
              child: Text("Add Category"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
