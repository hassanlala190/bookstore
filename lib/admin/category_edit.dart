import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryEditPage extends StatefulWidget {
  final String categoryId;
  final Map<String, dynamic> categoryData;

  CategoryEditPage({required this.categoryId, required this.categoryData});

  @override
  _CategoryEditPageState createState() => _CategoryEditPageState();
}

class _CategoryEditPageState extends State<CategoryEditPage> {
  final TextEditingController categoryNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set initial category name
    categoryNameController.text = widget.categoryData['name'];
  }

  // Function to update category details
  Future<void> _updateCategory() async {
    try {
      await FirebaseFirestore.instance.collection('categories').doc(widget.categoryId).update({
        'name': categoryNameController.text,
        'updated_at': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Category updated successfully")));
      Navigator.pop(context);  // Navigate back after update
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating category")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Category"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: categoryNameController,
              decoration: InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateCategory,
              child: Text('Update Category'),
            ),
          ],
        ),
      ),
    );
  }
}
