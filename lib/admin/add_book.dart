import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AddBookPage extends StatefulWidget {
  @override
  _AddBookPageState createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  // Text controllers
  TextEditingController bookNameController = TextEditingController();
  TextEditingController bookPriceController = TextEditingController();
  TextEditingController bookDescriptionController = TextEditingController();

  // Dropdown values
  String? selectedCategory;
  String? selectedAuthor;
  String selectedLanguage = "English";
  String selectedStock = "Yes";

  // Image handling
  File? _selectedImage;
  String? _webImageBase64;
  final ImagePicker _picker = ImagePicker();
  
  // Data lists
  List<String> categories = [];
  List<String> authors = [];

  FirebaseFirestore db = FirebaseFirestore.instance;
  bool _isSaving = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchAuthors();
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
        if (categories.isNotEmpty && selectedCategory == null) {
          selectedCategory = categories[0];
        }
      });
    } catch (e) {
      showMessage("Failed to load categories: $e", isError: true);
    } finally {
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
        if (authors.isNotEmpty && selectedAuthor == null) {
          selectedAuthor = authors[0];
        }
      });
    } catch (e) {
      showMessage("Failed to load authors: $e", isError: true);
    }
  }

  // Pick Image (Web + Mobile Compatible)
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      if (kIsWeb) {
        // WEB IMAGE BYTES
        final bytes = await image.readAsBytes();

        // COMPRESS WEB IMAGE
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
        // MOBILE FILE
        File file = File(image.path);

        // PATH FOR COMPRESSED IMAGE
        final targetPath = image.path.replaceAll(".jpg", "_compressed.jpg");

        // COMPRESS MOBILE IMAGE
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
      showMessage("Book cover image selected");
    } catch (e) {
      showMessage("Image Error: $e", isError: true);
    }
  }

  // Save Image (Web = Base64, Mobile = Folder)
  Future<String?> _saveImage() async {
    if (_selectedImage == null && _webImageBase64 == null) {
      return null;
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

      String fileName = 'book_${DateTime.now().millisecondsSinceEpoch}'
          '${path.extension(_selectedImage!.path)}';

      String newPath = '${imagesDir.path}/$fileName';
      await _selectedImage!.copy(newPath);

      return 'book_covers/$fileName';
    } catch (e) {
      showMessage("Failed to save image: $e", isError: true);
      return null;
    }
  }

  // Add book to Firestore
  void _addBook() async {
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

    // Validate price
    double? price = double.tryParse(bookPrice);
    if (price == null || price <= 0) {
      showMessage("Please enter a valid price", isError: true);
      return;
    }

    try {
      setState(() => _isSaving = true);

      // Save image
      String? imageData = await _saveImage();

      // Add book to Firestore
      await db.collection('books').add({
        'bookName': bookName,
        'bookPrice': price,
        'bookDescription': bookDescription,
        'bookAuthor': selectedAuthor,
        'bookCategory': selectedCategory,
        'bookLanguage': selectedLanguage,
        'bookStock': selectedStock,
        'bookCoverImage': imageData ?? "",
        'is_web': kIsWeb,
        'createdAt': FieldValue.serverTimestamp(),
      });

      showMessage("Book added successfully!");
      
      _clearFields();
      
    } catch (e) {
      showMessage("Error: $e", isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _clearFields() {
    bookNameController.clear();
    bookPriceController.clear();
    bookDescriptionController.clear();
    setState(() {
      _selectedImage = null;
      _webImageBase64 = null;
      if (categories.isNotEmpty) selectedCategory = categories[0];
      if (authors.isNotEmpty) selectedAuthor = authors[0];
      selectedLanguage = "English";
      selectedStock = "Yes";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Add New Book",
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
                            Icons.menu_book,
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
                                "Add New Book",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Fill in the details to add a new book",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
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
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Stack(
                            children: [
                              if (kIsWeb && _webImageBase64 != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    base64Decode(_webImageBase64!),
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else if (_selectedImage != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _selectedImage!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_outlined, size: 50, color: Colors.grey[400]),
                                    const SizedBox(height: 10),
                                    Text(
                                      "No cover image selected",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      "Upload book cover image",
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: Container(
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
                                      Icons.camera_alt_outlined,
                                      color: Colors.black87,
                                    ),
                                    onPressed: _pickImage,
                                  ),
                                ),
                              ),
                            ],
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
                            maxLines: 3,
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

                        const SizedBox(height: 20),

                        // Category Selection - Single Column
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

                        // Author Selection - Single Column
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

                        // Language and Stock Selection - Single Column Each
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
                      // Clear Button
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: _clearFields,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              "CLEAR FORM",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Submit Button
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
                            onPressed: _isSaving ? null : _addBook,
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
                                        Icons.add,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "ADD BOOK",
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
                            "All fields marked with * are required. Book cover image is optional.",
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
        menuMaxHeight: 300, // Fixed height for dropdown menu
        iconSize: 24,
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}