import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class BookEditPage extends StatefulWidget {
  final String bookId;
  final Map<String, dynamic> bookData;

  BookEditPage({required this.bookId, required this.bookData});

  @override
  _BookEditPageState createState() => _BookEditPageState();
}

class _BookEditPageState extends State<BookEditPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? selectedCategory;
  String? selectedAuthor;
  String selectedLanguage = "English";
  File? _newImage; // For storing the new image

  final ImagePicker _picker = ImagePicker();
  
  List<String> categories = [];
  List<String> authors = [];

  @override
  void initState() {
    super.initState();

    // Set initial values from bookData
    nameController.text = widget.bookData['bookName'];
    priceController.text = widget.bookData['bookPrice'].toString();
    stockController.text = widget.bookData['bookStock'];
    descriptionController.text = widget.bookData['bookDescription'];
    selectedCategory = widget.bookData['bookCategory'];
    selectedAuthor = widget.bookData['bookAuthor'];
    selectedLanguage = widget.bookData['bookLanguage'];

    // Fetch categories and authors
    _fetchCategories();
    _fetchAuthors();
  }

  // Fetch categories from Firestore
  void _fetchCategories() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('categories').get();
    List<String> categoryList = snapshot.docs.map((doc) => doc['name'] as String).toList();
    setState(() {
      categories = categoryList;
    });
  }

  // Fetch authors from Firestore
  void _fetchAuthors() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('authors').get();
    List<String> authorList = snapshot.docs.map((doc) => doc['name'] as String).toList();
    setState(() {
      authors = authorList;
    });
  }

  // Pick an image for the book cover
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _newImage = File(pickedFile.path);
      });
    }
  }

  // Upload image to Firebase Storage and get URL
  Future<String> _uploadCoverImage() async {
    if (_newImage == null) {
      return widget.bookData['bookCoverImage'];  // Use existing image if no new image is selected
    }
    try {
      Reference storageRef = FirebaseStorage.instance.ref().child('book_covers/${DateTime.now().millisecondsSinceEpoch}');
      UploadTask uploadTask = storageRef.putFile(_newImage!);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return widget.bookData['bookCoverImage']; // Fallback to old image if upload fails
    }
  }

  // Update book details in Firestore
  Future<void> _updateBook() async {
    String bookName = nameController.text.trim();
    String bookPrice = priceController.text.trim();
    String bookDescription = descriptionController.text.trim();
    String bookStock = stockController.text.trim();

    if (bookName.isEmpty || bookPrice.isEmpty || bookDescription.isEmpty || bookStock.isEmpty || selectedAuthor == null || selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("All fields are required.")));
      return;
    }

    String coverImageUrl = await _uploadCoverImage();

    try {
      await FirebaseFirestore.instance.collection('books').doc(widget.bookId).update({
        'bookName': bookName,
        'bookPrice': double.tryParse(bookPrice) ?? 0.0,
        'bookStock': bookStock,
        'bookDescription': bookDescription,
        'bookAuthor': selectedAuthor,
        'bookCategory': selectedCategory,
        'bookLanguage': selectedLanguage,
        'bookCoverImage': coverImageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Book updated successfully")));
      Navigator.pop(context); // Navigate back after successful update
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating book")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Book")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Book Name field
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Book Name'),
              ),
              SizedBox(height: 16),

              // Book Price field
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Price'),
              ),
              SizedBox(height: 16),

              // Book Stock field
              TextField(
                controller: stockController,
                decoration: InputDecoration(labelText: 'Stock'),
              ),
              SizedBox(height: 16),

              // Book Description field
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 16),

              // Book Category dropdown
              DropdownButton<String>(
                value: selectedCategory,
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
              SizedBox(height: 16),

              // Book Author dropdown
              DropdownButton<String>(
                value: selectedAuthor,
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
              SizedBox(height: 16),

              // Book Language dropdown
              DropdownButton<String>(
                value: selectedLanguage,
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
              SizedBox(height: 16),

              // Book Image display
              Text("Book Cover Image", style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              _newImage == null
                  ? widget.bookData['bookCoverImage'] != null
                      ? Image.network(widget.bookData['bookCoverImage'], height: 150, width: 150, fit: BoxFit.cover)
                      : Text("No image selected")
                  : Image.file(_newImage!, height: 150, width: 150, fit: BoxFit.cover),

              SizedBox(height: 16),

              // Pick Image button
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.image),
                label: Text("Pick an image"),
              ),

              SizedBox(height: 20),

              // Update button
              ElevatedButton(
                onPressed: _updateBook,
                child: Text('Update Book'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
