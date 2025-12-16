import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookstore/admin/book_edit.dart'; // Import the BookEditPage
import 'package:path_provider/path_provider.dart';

class ShowBooksPage extends StatefulWidget {
  @override
  _ShowBooksPageState createState() => _ShowBooksPageState();
}

class _ShowBooksPageState extends State<ShowBooksPage> {
  FirebaseFirestore db = FirebaseFirestore.instance;

  void showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _deleteBook(DocumentSnapshot doc) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Book?"),
        content: Text("Are you sure you want to delete '${doc['bookName']}'?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Delete")),
        ],
      ),
    );
    if (confirm) {
      try {
        await db.collection("books").doc(doc.id).delete();
        showMessage("Book deleted successfully!");
      } catch (e) {
        showMessage("Delete error: $e", isError: true);
      }
    }
  }

  void _showFullDescription(String bookName, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(bookName),
        content: SingleChildScrollView(
          child: Text(description),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Books List")),
      body: StreamBuilder<QuerySnapshot>(
        stream: db
            .collection("books")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return Center(child: Text("No books found"));

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  leading: kIsWeb && data['is_web'] == true
                      ? (data['bookCoverImage'] != null && data['bookCoverImage']!.isNotEmpty
                          ? Image.memory(
                              base64Decode(data['bookCoverImage']!),
                              width: 50,
                              height: 75,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 50,
                              height: 75,
                              color: Colors.grey,
                              child: Icon(Icons.book, color: Colors.white)))
                      : (data['bookCoverImage'] != null && data['bookCoverImage']!.isNotEmpty
                          ? FutureBuilder<File>(
                              future: _getImageFile(data['bookCoverImage']!),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Container(
                                    width: 50,
                                    height: 75,
                                    color: Colors.grey,
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (snapshot.hasData) {
                                  return Image.file(
                                    snapshot.data!,
                                    width: 50,
                                    height: 75,
                                    fit: BoxFit.cover,
                                  );
                                }
                                return Container(
                                  width: 50,
                                  height: 75,
                                  color: Colors.grey,
                                  child: Icon(Icons.book, color: Colors.white),
                                );
                              },
                            )
                          : Container(
                              width: 50,
                              height: 75,
                              color: Colors.grey,
                              child: Icon(Icons.book, color: Colors.white))),
                  title: Text("Book: ${data['bookName'] ?? "No Name"}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['bookAuthor'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text("Author: ${data['bookAuthor']}"),
                        ),
                      if (data['bookCategory'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text("Category: ${data['bookCategory']}"),
                        ),
                      if (data['bookPrice'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text("Price: \$${data['bookPrice'].toStringAsFixed(2)}"),
                        ),
                      if (data['bookLanguage'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text("Language: ${data['bookLanguage']}"),
                        ),
                      if (data['bookStock'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text("In Stock: ${data['bookStock']}"),
                        ),
                      if (data['bookDescription'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Description: ${data['bookDescription']!}",
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              GestureDetector(
                                onTap: () => _showFullDescription(
                                    data['bookName'] ?? "Book",
                                    data['bookDescription']!),
                                child: Text(
                                  "Read More",
                                  style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookEditPage(
                                      bookId: doc.id, 
                                      bookData: data),
                                ));
                          }),
                      IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteBook(doc)),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
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