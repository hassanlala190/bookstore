import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

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

  @override
  void initState() {
    super.initState();
    nameController.text = widget.data['name'];
    contactController.text = widget.data['contact'];
    descriptionController.text = widget.data['description'];
  }

  void showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
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
      showMessage("All fields required", isError: true);
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
      });
      showMessage("Author updated!");
      Navigator.pop(context);
    } catch (e) {
      showMessage("Update error: $e", isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    contactController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Author")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            if (kIsWeb && _webImageBase64 != null)
              Image.memory(
                base64Decode(_webImageBase64!),
                height: 150,
                fit: BoxFit.cover,
              )
            else if (!kIsWeb && _selectedImage != null)
              Image.file(_selectedImage!, height: 150, fit: BoxFit.cover)
            else if (widget.data['image'] != null)
              kIsWeb && widget.data['is_web']
                  ? Image.memory(base64Decode(widget.data['image']),
                      height: 150, fit: BoxFit.cover)
                  : Image.file(File(widget.data['image']),
                      height: 150, fit: BoxFit.cover)
            else
              Container(
                height: 150,
                color: Colors.grey[300],
                child: Center(child: Text("No image")),
              ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              icon: Icon(Icons.image),
              label: Text("Change Image"),
              onPressed: _pickImage,
            ),
            SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: contactController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: "Contact"),
            ),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(labelText: "Description"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _updateAuthor,
              child: _isSaving
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Update Author"),
            ),
          ],
        ),
      ),
    );
  }
}
