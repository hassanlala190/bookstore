import 'dart:io';
import 'dart:convert';
import 'package:bookstore/admin/author_edit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShowAuthorPage extends StatefulWidget {
  @override
  _ShowAuthorPageState createState() => _ShowAuthorPageState();
}

class _ShowAuthorPageState extends State<ShowAuthorPage> {
  FirebaseFirestore db = FirebaseFirestore.instance;

  void showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _deleteAuthor(DocumentSnapshot doc) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Author?"),
        content: Text("Are you sure you want to delete '${doc['name']}'?"),
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
        await db.collection("authors").doc(doc.id).delete();
        showMessage("Author deleted!");
      } catch (e) {
        showMessage("Delete error: $e", isError: true);
      }
    }
  }

  void _showFullDescription(String name, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
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
      appBar: AppBar(title: Text("Authors List")),
      body: StreamBuilder<QuerySnapshot>(
        stream: db
            .collection("authors")
            .orderBy("created_at", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return Center(child: Text("No authors found"));

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  leading: kIsWeb && data['is_web'] == true
                      ? (data['image'] != null
                          ? Image.memory(
                              base64Decode(data['image']),
                              width: 50,
                              fit: BoxFit.cover,
                            )
                          : Icon(Icons.person))
                      : (data['image'] != null
                          ? Image.file(
                              File(data['image']),
                              width: 50,
                              fit: BoxFit.cover,
                            )
                          : Icon(Icons.person)),
                  title: Text("Name: ${data['name'] ?? ""}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['contact'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text("Contact: ${data['contact']}"),
                        ),
                      if (data['description'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Description: ${data['description']!}",
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              GestureDetector(
                                onTap: () => _showFullDescription(
                                    data['name'] ?? "Author",
                                    data['description']!),
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
                                  builder: (context) => AuthorEditPage(
                                      docId: doc.id, data: data),
                                ));
                          }),
                      IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteAuthor(doc)),
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
}
