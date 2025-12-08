import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AuthorEditPage extends StatefulWidget {
  final String authorId;
  final Map<String, dynamic> authorData;

  AuthorEditPage({required this.authorId, required this.authorData});

  @override
  _AuthorEditPageState createState() => _AuthorEditPageState();
}

class _AuthorEditPageState extends State<AuthorEditPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  File? _newImage; // To store new image if selected
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Set initial values from authorData
    nameController.text = widget.authorData['name'];
    contactController.text = widget.authorData['contact'];
    descriptionController.text = widget.authorData['description'];
  }

  // Function to pick a new image
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _newImage = File(pickedFile.path);
      });
    }
  }

  // Function to upload the new image to Firebase Storage
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

  // Function to update author details in Firestore
  Future<void> _updateAuthor() async {
    // Check if fields are empty
    if (nameController.text.isEmpty || contactController.text.isEmpty || descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("All fields are required")));
      return;
    }

    try {
      String? imageUrl;

      if (_newImage != null) {
        // If a new image is selected, upload it and get the URL
        imageUrl = await _uploadImage(_newImage!);
      } else {
        // If no new image is selected, use the existing image URL
        imageUrl = widget.authorData['image_url'];
      }

      // Update author data in Firestore
      await FirebaseFirestore.instance.collection('Authors').doc(widget.authorId).update({
        'name': nameController.text,
        'contact': contactController.text,
        'description': descriptionController.text,
        'image_url': imageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Author updated successfully")));
      Navigator.pop(context); // Go back after updating
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating author")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Author"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author Name field
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Author Name'),
              ),
              SizedBox(height: 16),

              // Author Contact field
              TextField(
                controller: contactController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: 'Contact'),
              ),
              SizedBox(height: 16),

              // Author Description field
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 16),

              // Author Image display
              Text("Author Image", style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              _newImage == null
                  ? widget.authorData['image_url'] != null
                      ? Image.network(widget.authorData['image_url'], height: 150, width: 150, fit: BoxFit.cover)
                      : Text("No image selected")
                  : Image.file(_newImage!, height: 150, width: 150, fit: BoxFit.cover),

              SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.image),
                label: Text("Pick an image"),
              ),

              SizedBox(height: 20),

              // Update button
              ElevatedButton(
                onPressed: _updateAuthor,
                child: Text('Update Author'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
