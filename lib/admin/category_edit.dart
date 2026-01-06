import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CategoryEditPage extends StatefulWidget {
  final String categoryId;
  final Map<String, dynamic> categoryData;

  CategoryEditPage({required this.categoryId, required this.categoryData});

  @override
  _CategoryEditPageState createState() => _CategoryEditPageState();
}

class _CategoryEditPageState extends State<CategoryEditPage> {
  final TextEditingController categoryNameController = TextEditingController();
  FirebaseFirestore db = FirebaseFirestore.instance;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    // Set initial category name
    categoryNameController.text = widget.categoryData['name'];
  }

  // Show message function
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

  // Function to update category details
  Future<void> _updateCategory() async {
    String categoryName = categoryNameController.text.trim();

    if (categoryName.isEmpty) {
      showMessage("Category name is required", isError: true);
      return;
    }

    try {
      setState(() => _isSaving = true);
      
      await db.collection('categories').doc(widget.categoryId).update({
        'name': categoryName,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      showMessage("Category updated successfully");
      Navigator.pop(context);  // Navigate back after update
    } catch (e) {
      showMessage("Error updating category: $e", isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteCategory() async {
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
              "Delete Category?",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete '${widget.categoryData['name']}'? This action cannot be undone.",
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
      setState(() => _isDeleting = true);
      try {
        await db.collection("categories").doc(widget.categoryId).delete();
        showMessage("Category deleted successfully!");
        Navigator.pop(context);
      } catch (e) {
        showMessage("Delete error: $e", isError: true);
      } finally {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = widget.categoryData['created_at'] as Timestamp?;
    final updatedAt = widget.categoryData['updated_at'] as Timestamp?;
    
    final formattedCreatedDate = createdAt != null
        ? DateFormat('MMM dd, yyyy HH:mm').format(createdAt.toDate())
        : "N/A";
        
    final formattedUpdatedDate = updatedAt != null
        ? DateFormat('MMM dd, yyyy HH:mm').format(updatedAt.toDate())
        : "Never updated";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Edit Category",
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                      Icons.edit_outlined,
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
                          "Edit Category",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.categoryData['name'] ?? "Unknown Category",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Created: $formattedCreatedDate",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Updated: $formattedUpdatedDate",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Category Form Card
            Container(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Category Details",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Category Name Field
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: categoryNameController,
                      style: TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: "Category Name *",
                        labelStyle: TextStyle(color: Colors.grey[700]),
                        prefixIcon: Icon(
                          Icons.category_outlined,
                          color: Colors.grey[700],
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.black54,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Action Buttons
                  Row(
                    children: [
                      // Delete Button
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: _isDeleting ? null : _deleteCategory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[50],
                              foregroundColor: Colors.red[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isDeleting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.red,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.delete_outline, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        "DELETE",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Update Button
                      Expanded(
                        child: Container(
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
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _updateCategory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.save_outlined,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "UPDATE",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Information Note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey[600],
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Update the category name and click update to save changes. Deleting a category will remove it permanently.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Category Statistics
            Container(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Category Information",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoItem(
                        icon: Icons.category_outlined,
                        title: "Category ID",
                        value: widget.categoryId.substring(0, 8) + "...",
                      ),
                      const SizedBox(width: 20),
                      _buildInfoItem(
                        icon: Icons.calendar_today_outlined,
                        title: "Status",
                        value: "Active",
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: Colors.grey[700],
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}