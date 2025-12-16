import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AddAuthorPage extends StatefulWidget {
  @override
  _AddAuthorPageState createState() => _AddAuthorPageState();
}

class _AddAuthorPageState extends State<AddAuthorPage> {
  // Text controllers
  TextEditingController nameController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController imagePathController = TextEditingController();

  FirebaseFirestore db = FirebaseFirestore.instance;

  File? _selectedImage;
  String? _webImageBase64;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  void showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
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
        imagePathController.text = "Web Compressed Image Selected";
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
        imagePathController.text = compressedFile.path;
      });
    }
  } catch (e) {
    showMessage("Image Compression Error: $e", isError: true);
  }
}

  // Save Image (Web = Base64, Mobile = Folder)
  Future<String?> _saveImage() async {
    if (kIsWeb) {
      return _webImageBase64; // Base64 data
    }

    if (_selectedImage == null) return null;

    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final Directory imagesDir = Directory('${appDocDir.path}/images');

      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      String fileName = 'author_${DateTime.now().millisecondsSinceEpoch}'
          '${path.extension(_selectedImage!.path)}';

      String newPath = '${imagesDir.path}/$fileName';
      await _selectedImage!.copy(newPath);

      return 'images/$fileName'; // Firestore path
    } catch (e) {
      print(e.toString());
      showMessage("Failed to save image: $e", isError: true);
      return null;
    }
  }

  void addAuthor() async {
    String name = nameController.text.trim();
    String contact = contactController.text.trim();
    String description = descriptionController.text.trim();

    if (name.isEmpty || contact.isEmpty || description.isEmpty) {
      showMessage("All required fields must be filled", isError: true);
      return;
    }

    if (_selectedImage == null && _webImageBase64 == null) {
      showMessage("Please select an image", isError: true);
      return;
    }

    try {
      setState(() => _isSaving = true);

      String? imageData = await _saveImage();
      if (imageData == null) {
        showMessage("Image save failed", isError: true);
        setState(() => _isSaving = false);
        return;
      }

      await db.collection("authors").add({
        "name": name,
        "contact": contact,
        "description": description,
        "image": imageData, // base64 or path
        "is_web": kIsWeb, // identify data type
        "created_at": FieldValue.serverTimestamp(),
      });

      showMessage("Author added successfully!");

      _clearFields();
    } catch (e) {
      showMessage("Error: $e", isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _clearFields() {
    nameController.clear();
    contactController.clear();
    descriptionController.clear();
    imagePathController.clear();
    setState(() {
      _selectedImage = null;
      _webImageBase64 = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Author")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Image Preview
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
            else
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: Center(child: Text("No image selected")),
              ),

            SizedBox(height: 10),
            ElevatedButton.icon(
              icon: Icon(Icons.image),
              label: Text("Select Image"),
              onPressed: _pickImage,
            ),

            SizedBox(height: 20),

            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Author Name *"),
            ),
            SizedBox(height: 10),

            TextField(
              controller: contactController,
              decoration: InputDecoration(labelText: "Contact *"),
            ),
            SizedBox(height: 10),

            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(labelText: "Description *"),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isSaving ? null : addAuthor,
              child: _isSaving
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Add Author"),
            ),
          ],
        ),
      ),
    );
  }
}


