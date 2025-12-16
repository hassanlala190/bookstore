import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

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
      // Web image (base64)
      _webImageBase64 = widget.bookData['bookCoverImage'];
    } else if (!kIsWeb && widget.bookData['bookCoverImage'] != null && 
               widget.bookData['bookCoverImage']!.isNotEmpty) {
      // Mobile - load from file path
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
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
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
          quality: 15,      // VERY LOW SIZE (good for Firestore)
          minWidth: 300,    // OPTIONAL (reduce resolution)
          minHeight: 300,
        );

        setState(() {
          _webImageBase64 = base64Encode(compressed);
          _selectedImage = null;
          _imageChanged = true;
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
          quality: 15,     // SMALL SIZE
        );

        setState(() {
          _selectedImage = File(compressedFile!.path);
          _webImageBase64 = null;
          _imageChanged = true;
        });
      }
    } catch (e) {
      showMessage("Image Error: $e", isError: true);
    }
  }

  // Save Image (Web = Base64, Mobile = Folder)
  Future<String?> _saveImage() async {
    // If image hasn't changed, return existing image
    if (!_imageChanged) {
      return widget.bookData['bookCoverImage'];
    }

    if (_selectedImage == null && _webImageBase64 == null) {
      return widget.bookData['bookCoverImage'];
    }

    if (kIsWeb) {
      return _webImageBase64; // Base64 data
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

      return 'book_covers/$fileName'; // Firestore path
    } catch (e) {
      print(e.toString());
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

    // Validate price
    double? price = double.tryParse(bookPrice);
    if (price == null || price <= 0) {
      showMessage("Please enter a valid price", isError: true);
      return;
    }

    try {
      setState(() => _isSaving = true);

      // Save image (returns base64 for web, path for mobile)
      String? imageData = await _saveImage();

      // Update book in Firestore
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Book"),
      ),
      body: _isLoadingData
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Preview
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        // Show selected image
                        if (kIsWeb && _webImageBase64 != null)
                          Image.memory(
                            base64Decode(_webImageBase64!),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        else if (_selectedImage != null)
                          Image.file(
                            _selectedImage!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        // Show existing image if no new image selected
                        else if (widget.bookData['bookCoverImage'] != null && 
                                widget.bookData['bookCoverImage']!.isNotEmpty)
                          _buildExistingImage()
                        else
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, size: 50, color: Colors.grey),
                                SizedBox(height: 10),
                                Text("No cover image"),
                              ],
                            ),
                          ),
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: FloatingActionButton.small(
                            onPressed: _pickImage,
                            child: Icon(Icons.camera_alt),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  TextField(
                    controller: bookNameController,
                    decoration: InputDecoration(
                      labelText: "Book Name *",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.book),
                    ),
                  ),
                  
                  SizedBox(height: 15),
                  
                  TextField(
                    controller: bookPriceController,
                    decoration: InputDecoration(
                      labelText: "Book Price *",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                  
                  SizedBox(height: 15),
                  
                  TextField(
                    controller: bookDescriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Book Description *",
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  
                  SizedBox(height: 15),
                  
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: "Category *",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                      });
                    },
                    items: categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                  ),
                  
                  SizedBox(height: 15),
                  
                  DropdownButtonFormField<String>(
                    value: selectedAuthor,
                    decoration: InputDecoration(
                      labelText: "Author *",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedAuthor = value;
                      });
                    },
                    items: authors.map((author) {
                      return DropdownMenuItem<String>(
                        value: author,
                        child: Text(author),
                      );
                    }).toList(),
                  ),
                  
                  SizedBox(height: 15),
                  
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedLanguage,
                          decoration: InputDecoration(
                            labelText: "Language",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.language),
                          ),
                          onChanged: (value) {
                            setState(() {
                              selectedLanguage = value!;
                            });
                          },
                          items: ["English", "Urdu"].map((language) {
                            return DropdownMenuItem<String>(
                              value: language,
                              child: Text(language),
                            );
                          }).toList(),
                        ),
                      ),
                      
                      SizedBox(width: 15),
                      
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedStock,
                          decoration: InputDecoration(
                            labelText: "In Stock",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.inventory),
                          ),
                          onChanged: (value) {
                            setState(() {
                              selectedStock = value!;
                            });
                          },
                          items: ["Yes", "No"].map((stock) {
                            return DropdownMenuItem<String>(
                              value: stock,
                              child: Text(stock),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 30),
                  
                  Center(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _updateBook,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(200, 50),
                      ),
                      child: _isSaving
                          ? CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.save),
                                SizedBox(width: 10),
                                Text("Update Book"),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Helper to build existing image widget
  Widget _buildExistingImage() {
    final imageData = widget.bookData['bookCoverImage'];
    final isWeb = widget.bookData['is_web'] == true;
    
    if (kIsWeb && isWeb) {
      try {
        // Web - show base64 image
        return Image.memory(
          base64Decode(imageData!),
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } catch (e) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 50, color: Colors.grey),
              SizedBox(height: 10),
              Text("Error loading image"),
            ],
          ),
        );
      }
    } else if (!kIsWeb && !isWeb) {
      // Mobile - show file image
      return FutureBuilder<File>(
        future: _getImageFile(imageData!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return Image.file(
              snapshot.data!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, size: 50, color: Colors.grey),
                SizedBox(height: 10),
                Text("No image available"),
              ],
            ),
          );
        },
      );
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 50, color: Colors.grey),
          SizedBox(height: 10),
          Text("No image data"),
        ],
      ),
    );
  }

  // Helper function to get File from path (for mobile)
  Future<File> _getImageFile(String imagePath) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String fullPath = '${appDocDir.path}/$imagePath';
    return File(fullPath);
  }
}