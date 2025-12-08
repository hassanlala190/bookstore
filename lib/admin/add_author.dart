import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddAuthorPage extends StatefulWidget {
  @override
  _AddAuthorPageState createState() => _AddAuthorPageState();
}

class _AddAuthorPageState extends State<AddAuthorPage> {
  TextEditingController authorNameController = TextEditingController();
  TextEditingController authorContactController = TextEditingController();
  TextEditingController authorDescriptionController = TextEditingController();
  
  File? _image;
  final ImagePicker _picker = ImagePicker();

  // Function to pick image from gallery
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Function to upload image to Firebase Storage
  Future<String?> _uploadImage(File image) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageReference = FirebaseStorage.instance.ref().child('authors/$fileName');
      UploadTask uploadTask = storageReference.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      String downloadURL = await snapshot.ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print("Image upload failed: $e");
      return null;
    }
  }

  // Function to add author to Firestore
  void _addAuthor() async {
    if (authorNameController.text.isEmpty ||
        authorContactController.text.isEmpty ||
        authorDescriptionController.text.isEmpty ||
        _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("All fields are required")));
      return;
    }

    String? imageUrl = await _uploadImage(_image!);

    if (imageUrl != null) {
      try {
        FirebaseFirestore.instance.collection("Authors").add({
          "name": authorNameController.text,
          "contact": authorContactController.text,
          "description": authorDescriptionController.text,
          "image_url": imageUrl,
          "created_at": DateTime.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Author added successfully")));
        
        // Clear the fields after adding
        authorNameController.clear();
        authorContactController.clear();
        authorDescriptionController.clear();
        setState(() {
          _image = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Author")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Author Name", style: TextStyle(fontSize: 16)),
              TextField(
                controller: authorNameController,
                decoration: InputDecoration(hintText: "Enter Author Name"),
              ),
              SizedBox(height: 16),

              Text("Author Contact", style: TextStyle(fontSize: 16)),
              TextField(
                controller: authorContactController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(hintText: "Enter Author Contact"),
              ),
              SizedBox(height: 16),

              Text("Author Description", style: TextStyle(fontSize: 16)),
              TextField(
                controller: authorDescriptionController,
                maxLines: 4,
                decoration: InputDecoration(hintText: "Enter Author Description"),
              ),
              SizedBox(height: 16),

              Text("Author Image", style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              _image == null
                  ? Text("No image selected")
                  : Image.file(_image!, height: 150, width: 150, fit: BoxFit.cover),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.image),
                label: Text("Pick an image"),
              ),
              SizedBox(height: 16),

              ElevatedButton(
                onPressed: _addAuthor,
                child: Text("Add Author"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
