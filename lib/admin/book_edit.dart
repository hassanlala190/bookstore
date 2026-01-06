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

class BookEditPage extends StatefulWidget {
  final String bookId;
  final Map<String, dynamic> bookData;

  BookEditPage({required this.bookId, required this.bookData});

  @override
  _BookEditPageState createState() => _BookEditPageState();
}

class _BookEditPageState extends State<BookEditPage> {
  // Text controllers
  late TextEditingController bookNameController;
  late TextEditingController bookPriceController;
  late TextEditingController bookDescriptionController;

  // Dropdown values
  String? selectedCategory;
  String? selectedAuthor;
  String selectedLanguage = "English";
  String selectedStock = "Yes";

  // Image handling
  File? _selectedImage;
  String? _webImageBase64;
  final ImagePicker _picker = ImagePicker();
  bool _imageChanged = false;
  bool _isDeleting = false;
  
  // Data lists
  List<String> categories = [];
  List<String> authors = [];

  FirebaseFirestore db = FirebaseFirestore.instance;
  bool _isSaving = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing data
    bookNameController = TextEditingController(text: widget.bookData['bookName'] ?? '');
    bookPriceController = TextEditingController(text: widget.bookData['bookPrice']?.toString() ?? '');
    bookDescriptionController = TextEditingController(text: widget.bookData['bookDescription'] ?? '');
    
    // Set dropdown values from existing data
    selectedCategory = widget.bookData['bookCategory'];
    selectedAuthor = widget.bookData['bookAuthor'];
    selectedLanguage = widget.bookData['bookLanguage'] ?? 'English';
    selectedStock = widget.bookData['bookStock'] ?? 'Yes';
    
    // Load existing image
    _loadExistingImage();
    
    // Fetch categories and authors
    _fetchCategories();
    _fetchAuthors();
  }

  void _loadExistingImage() {
    if (kIsWeb && widget.bookData['is_web'] == true) {
      _webImageBase64 = widget.bookData['bookCoverImage'];
    } else if (!kIsWeb && widget.bookData['bookCoverImage'] != null && 
               widget.bookData['bookCoverImage']!.isNotEmpty) {
      _loadImageFromPath(widget.bookData['bookCoverImage']!);
    }
  }

  Future<void> _loadImageFromPath(String imagePath) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String fullPath = '${appDocDir.path}/$imagePath';
      setState(() {
        _selectedImage = File(fullPath);
      });
    } catch (e) {
      print("Error loading image: $e");
    }
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

  // Fetch categories from Firestore
  void _fetchCategories() async {
    try {
      QuerySnapshot snapshot = await db.collection('categories').get();
      List<String> categoryList = snapshot.docs
          .map((doc) => doc['name'] as String)
          .toList();
          
      setState(() {
        categories = categoryList;
        _isLoadingData = false;
      });
    } catch (e) {
      showMessage("Failed to load categories: $e", isError: true);
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  // Fetch authors from Firestore
  void _fetchAuthors() async {
    try {
      QuerySnapshot snapshot = await db.collection('authors').get();
      List<String> authorList = snapshot.docs
          .map((doc) => doc['name'] as String)
          .toList();
          
      setState(() {
        authors = authorList;
      });
    } catch (e) {
      showMessage("Failed to load authors: $e", isError: true);
    }
  }

  // Pick Image
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
          _imageChanged = true;
        });

      } else {
        File file = File(image.path);
        final targetPath = image.path.replaceAll(".jpg", "_compressed.jpg");
        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: 15,
        );

        setState(() {
          _selectedImage = File(compressedFile!.path);
          _webImageBase64 = null;
          _imageChanged = true;
        });
      }
      showMessage("Book cover image updated");
    } catch (e) {
      showMessage("Image Error: $e", isError: true);
    }
  }

  // Save Image
  Future<String?> _saveImage() async {
    if (!_imageChanged) {
      return widget.bookData['bookCoverImage'];
    }

    if (_selectedImage == null && _webImageBase64 == null) {
      return widget.bookData['bookCoverImage'];
    }

    if (kIsWeb) {
      return _webImageBase64;
    }

    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final Directory imagesDir = Directory('${appDocDir.path}/book_covers');

      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      String fileName = 'book_${DateTime.now().millisecondsSinceEpoch}.jpg';
      String newPath = '${imagesDir.path}/$fileName';
      await _selectedImage!.copy(newPath);

      return 'book_covers/$fileName';
    } catch (e) {
      showMessage("Failed to save image: $e", isError: true);
      return null;
    }
  }

  // Update book in Firestore
  void _updateBook() async {
    String bookName = bookNameController.text.trim();
    String bookPrice = bookPriceController.text.trim();
    String bookDescription = bookDescriptionController.text.trim();

    if (bookName.isEmpty || 
        bookPrice.isEmpty || 
        bookDescription.isEmpty || 
        selectedAuthor == null || 
        selectedCategory == null) {
      showMessage("All required fields must be filled", isError: true);
      return;
    }

    double? price = double.tryParse(bookPrice);
    if (price == null || price <= 0) {
      showMessage("Please enter a valid price", isError: true);
      return;
    }

    try {
      setState(() => _isSaving = true);

      String? imageData = await _saveImage();

      await db.collection('books').doc(widget.bookId).update({
        'bookName': bookName,
        'bookPrice': price,
        'bookDescription': bookDescription,
        'bookAuthor': selectedAuthor,
        'bookCategory': selectedCategory,
        'bookLanguage': selectedLanguage,
        'bookStock': selectedStock,
        'bookCoverImage': imageData ?? widget.bookData['bookCoverImage'] ?? "",
        'updatedAt': FieldValue.serverTimestamp(),
      });

      showMessage("Book updated successfully!");
      Navigator.pop(context);
      
    } catch (e) {
      showMessage("Error: $e", isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteBook() async {
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
          "Are you sure you want to delete '${widget.bookData['bookName']}'? This action cannot be undone.",
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
        await db.collection("books").doc(widget.bookId).delete();
        showMessage("Book deleted successfully!");
        Navigator.pop(context);
      } catch (e) {
        showMessage("Delete error: $e", isError: true);
      } finally {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<File> _getImageFile(String imagePath) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String fullPath = '${appDocDir.path}/$imagePath';
    return File(fullPath);
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
    } else if (widget.bookData['bookCoverImage'] != null && 
               widget.bookData['bookCoverImage']!.isNotEmpty) {
      if (kIsWeb && widget.bookData['is_web'] == true) {
        return Image.memory(
          base64Decode(widget.bookData['bookCoverImage']!),
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } else {
        return FutureBuilder<File>(
          future: _getImageFile(widget.bookData['bookCoverImage']!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[200],
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasData) {
              return Image.file(
                snapshot.data!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              );
            }
            return _buildDefaultBookCover();
          },
        );
      }
    } else {
      return _buildDefaultBookCover();
    }
  }

  Widget _buildDefaultBookCover() {
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
          Icon(Icons.menu_book_outlined, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(
            "No Book Cover",
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = widget.bookData['createdAt'] as Timestamp?;
    final formattedDate = createdAt != null
        ? DateFormat('MMM dd, yyyy').format(createdAt.toDate())
        : "N/A";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Edit Book",
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
      body: _isLoadingData
          ? Center(
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
                    "Loading Data...",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
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
                                "Edit Book",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.bookData['bookName'] ?? "Unknown Book",
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

                  // Book Cover Image Section
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
                          "Book Cover Image",
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
                              "CHANGE BOOK COVER",
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

                  // Book Details Form
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
                          "Book Details",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Book Name Field
                        _buildTextField(
                          controller: bookNameController,
                          label: "Book Name *",
                          icon: Icons.book_outlined,
                        ),

                        const SizedBox(height: 16),

                        // Book Price Field
                        _buildTextField(
                          controller: bookPriceController,
                          label: "Book Price (₹) *",
                          icon: Icons.currency_rupee,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                        ),

                        const SizedBox(height: 16),

                        // Book Description Field
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
                            controller: bookDescriptionController,
                            maxLines: 4,
                            style: TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              labelText: "Book Description *",
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

                        const SizedBox(height: 16),

                        // Category Selection
                        _buildDropdown(
                          value: selectedCategory,
                          label: "Category *",
                          icon: Icons.category_outlined,
                          items: categories,
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // Author Selection
                        _buildDropdown(
                          value: selectedAuthor,
                          label: "Author *",
                          icon: Icons.person_outlined,
                          items: authors,
                          onChanged: (value) {
                            setState(() {
                              selectedAuthor = value;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // Language and Stock Selection
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown(
                                value: selectedLanguage,
                                label: "Language",
                                icon: Icons.language_outlined,
                                items: ["English", "Urdu"],
                                onChanged: (value) {
                                  setState(() {
                                    selectedLanguage = value!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDropdown(
                                value: selectedStock,
                                label: "Stock Status",
                                icon: Icons.inventory_outlined,
                                items: ["Yes", "No"],
                                onChanged: (value) {
                                  setState(() {
                                    selectedStock = value!;
                                  });
                                },
                              ),
                            ),
                          ],
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
                            onPressed: _isDeleting ? null : _deleteBook,
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
                                        "DELETE BOOK",
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
                            onPressed: _isSaving ? null : _updateBook,
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
                                        "UPDATE BOOK",
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
                            "All fields marked with * are required. Leave image unchanged to keep existing cover.",
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
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
        controller: controller,
        style: TextStyle(color: Colors.black87),
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[700]),
          prefixIcon: Icon(
            icon,
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
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
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
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[700]),
          prefixIcon: Icon(
            icon,
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
          isDense: true,
        ),
        onChanged: onChanged,
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width - 100,
              ),
              child: Text(
                item,
                style: TextStyle(color: Colors.black87, fontSize: 14),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          );
        }).toList(),
        dropdownColor: Colors.white,
        icon: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
        style: TextStyle(color: Colors.black87, fontSize: 14),
        isExpanded: true,
        menuMaxHeight: 300,
        iconSize: 24,
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}