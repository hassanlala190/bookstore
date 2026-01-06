import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class AuthorEditPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  AuthorEditPage({required this.docId, required this.data});

  @override
  _AuthorEditPageState createState() => _AuthorEditPageState();
}

class _AuthorEditPageState extends State<AuthorEditPage> {
  FirebaseFirestore db = FirebaseFirestore.instance;
  TextEditingController nameController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  File? _selectedImage;
  String? _webImageBase64;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.data['name'] ?? '';
    contactController.text = widget.data['contact'] ?? '';
    descriptionController.text = widget.data['description'] ?? '';
  }

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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        final compressed = await FlutterImageCompress.compressWithList(
          bytes,
          quality: 15,
          minWidth: 300,
          minHeight: 300,
        );
        setState(() {
          _webImageBase64 = base64Encode(compressed);
          _selectedImage = null;
        });
      } else {
        File file = File(image.path);
        final targetPath =
            image.path.replaceFirst(RegExp(r'\.(jpg|jpeg|png)$'), '_compressed.jpg');
        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: 15,
        );
        setState(() {
          _selectedImage = File(compressedFile!.path);
          _webImageBase64 = null;
        });
      }
      showMessage("Image selected successfully");
    } catch (e) {
      showMessage("Image error: $e", isError: true);
    }
  }

  Future<String?> _saveImage() async {
    if (kIsWeb) return _webImageBase64;

    if (_selectedImage == null) return null;

    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final Directory imagesDir = Directory('${appDocDir.path}/images');
      if (!await imagesDir.exists()) await imagesDir.create(recursive: true);

      String fileName = 'author_${DateTime.now().millisecondsSinceEpoch}'
          '${path.extension(_selectedImage!.path)}';
      String newPath = '${imagesDir.path}/$fileName';
      await _selectedImage!.copy(newPath);

      return 'images/$fileName';
    } catch (e) {
      showMessage("Save image failed: $e", isError: true);
      return null;
    }
  }

  void _updateAuthor() async {
    String name = nameController.text.trim();
    String contact = contactController.text.trim();
    String description = descriptionController.text.trim();
    
    if (name.isEmpty || contact.isEmpty || description.isEmpty) {
      showMessage("All fields are required", isError: true);
      return;
    }

    setState(() => _isSaving = true);
    String? imageData = await _saveImage();

    try {
      await db.collection("authors").doc(widget.docId).update({
        "name": name,
        "contact": contact,
        "description": description,
        "image": imageData ?? widget.data['image'],
        "is_web": kIsWeb,
        "updated_at": FieldValue.serverTimestamp(),
      });
      showMessage("Author updated successfully!");
      Navigator.pop(context);
    } catch (e) {
      showMessage("Update error: $e", isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteAuthor() async {
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
              "Delete Author?",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete '${widget.data['name']}'? This action cannot be undone.",
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
        await db.collection("authors").doc(widget.docId).delete();
        showMessage("Author deleted successfully!");
        Navigator.pop(context);
      } catch (e) {
        showMessage("Delete error: $e", isError: true);
      } finally {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    contactController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Widget _buildImagePreview() {
    if (kIsWeb && _webImageBase64 != null) {
      return Image.memory(
        base64Decode(_webImageBase64!),
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (!kIsWeb && _selectedImage != null) {
      return Image.file(_selectedImage!, height: 200, width: double.infinity, fit: BoxFit.cover);
    } else if (widget.data['image'] != null) {
      if (kIsWeb && widget.data['is_web'] == true) {
        return Image.memory(
          base64Decode(widget.data['image']),
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } else {
        return Image.file(
          File(widget.data['image']),
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
    } else {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              color: Colors.grey[400],
              size: 60,
            ),
            const SizedBox(height: 10),
            Text(
              "No Author Image",
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = widget.data['created_at'] as Timestamp?;
    final formattedDate = createdAt != null
        ? DateFormat('MMM dd, yyyy').format(createdAt.toDate())
        : "N/A";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Edit Author",
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
                          "Edit Author",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.data['name'] ?? "Unknown Author",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Created: $formattedDate",
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

            // Image Section
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
                    "Author Image",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Image Preview
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildImagePreview(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Change Image Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: Icon(
                        Icons.image_outlined,
                        color: Colors.grey[700],
                      ),
                      label: Text(
                        "CHANGE AUTHOR IMAGE",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Author Details Form
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
                    "Author Details",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name Field
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
                      controller: nameController,
                      style: TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: "Author Name *",
                        labelStyle: TextStyle(color: Colors.grey[700]),
                        prefixIcon: Icon(
                          Icons.person_outline,
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

                  const SizedBox(height: 16),

                  // Contact Field
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
                      controller: contactController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: "Contact *",
                        labelStyle: TextStyle(color: Colors.grey[700]),
                        prefixIcon: Icon(
                          Icons.phone_outlined,
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

                  const SizedBox(height: 16),

                  // Description Field
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
                      controller: descriptionController,
                      maxLines: 4,
                      style: TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: "Description *",
                        labelStyle: TextStyle(color: Colors.grey[700]),
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(bottom: 40),
                          child: Icon(
                            Icons.description_outlined,
                            color: Colors.grey[700],
                          ),
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
                ],
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
                      onPressed: _isDeleting ? null : _deleteAuthor,
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
                                  "DELETE AUTHOR",
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
                      onPressed: _isSaving ? null : _updateAuthor,
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
                                  "UPDATE AUTHOR",
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

            // Form Note
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
                      "All fields marked with * are required. Leave image unchanged to keep existing photo.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
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
}