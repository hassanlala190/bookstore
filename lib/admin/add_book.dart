import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddBookPage extends StatefulWidget {
  @override
  _AddBookPageState createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  TextEditingController bookNameController = TextEditingController();
  TextEditingController bookPriceController = TextEditingController();
  TextEditingController bookDescriptionController = TextEditingController();
  TextEditingController bookAuthorController = TextEditingController();

  String? selectedCategory;
  String? selectedAuthor;
  String selectedLanguage = "English";
  String selectedStock = "Yes";
  File? coverImage;

  List<String> categories = [];
  List<String> authors = [];

  FirebaseFirestore db = FirebaseFirestore.instance;
  FirebaseStorage storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchAuthors();
  }

  // Fetch categories from Firestore
  void _fetchCategories() async {
    QuerySnapshot snapshot = await db.collection('categories').get();
    List<String> categoryList = snapshot.docs.map((doc) => doc['name'] as String).toList();
    setState(() {
      categories = categoryList;
    });
  }

  // Fetch authors from Firestore
  void _fetchAuthors() async {
    QuerySnapshot snapshot = await db.collection('authors').get();
    List<String> authorList = snapshot.docs.map((doc) => doc['name'] as String).toList();
    setState(() {
      authors = authorList;
    });
  }

  // Pick an image for the book cover
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        coverImage = File(pickedFile.path);
      });
    }
  }

  // Upload image to Firebase Storage and get URL
  Future<String> _uploadCoverImage() async {
    if (coverImage == null) {
      return "";
    }
    try {
      Reference storageRef = storage.ref().child('book_covers/${DateTime.now().millisecondsSinceEpoch}');
      UploadTask uploadTask = storageRef.putFile(coverImage!);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return "";
    }
  }

  // Add book to Firestore
  void _addBook() async {
    String bookName = bookNameController.text.trim();
    String bookPrice = bookPriceController.text.trim();
    String bookDescription = bookDescriptionController.text.trim();
    String author = selectedAuthor ?? "";
    String category = selectedCategory ?? "";

    if (bookName.isEmpty || bookPrice.isEmpty || bookDescription.isEmpty || author.isEmpty || category.isEmpty) {
      _showMessage("All fields are required.");
      return;
    }

    String coverImageUrl = await _uploadCoverImage();

    try {
      await db.collection('books').add({
        'bookName': bookName,
        'bookPrice': double.tryParse(bookPrice) ?? 0,
        'bookDescription': bookDescription,
        'bookAuthor': author,
        'bookCategory': category,
        'bookLanguage': selectedLanguage,
        'bookStock': selectedStock,
        'bookCoverImage': coverImageUrl,
        'createdAt': DateTime.now(),
      });

      _showMessage("Book added successfully.");
      // Clear fields after successful addition
      setState(() {
        bookNameController.clear();
        bookPriceController.clear();
        bookDescriptionController.clear();
        selectedCategory = null;
        selectedAuthor = null;
        coverImage = null;
        selectedLanguage = "English";
        selectedStock = "Yes";
      });
    } catch (e) {
      _showMessage("Error: $e");
    }
  }

  // Show message
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Book")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: bookNameController,
              decoration: InputDecoration(labelText: "Book Name"),
            ),
            TextField(
              controller: bookPriceController,
              decoration: InputDecoration(labelText: "Book Price"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: bookDescriptionController,
              decoration: InputDecoration(labelText: "Book Description"),
              maxLines: 4,
            ),
            DropdownButton<String>(
              value: selectedCategory,
              hint: Text("Select Category"),
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
            DropdownButton<String>(
              value: selectedAuthor,
              hint: Text("Select Author"),
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
            DropdownButton<String>(
              value: selectedStock,
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
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text("Pick Book Cover Image"),
            ),
            if (coverImage != null) Image.file(coverImage!),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addBook,
              child: Text("Add Book"),
            ),
          ],
        ),
      ),
    );
  }
}
