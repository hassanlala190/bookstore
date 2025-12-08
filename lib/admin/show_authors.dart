import 'package:bookstore/admin/author_edit.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShowAuthorsPage extends StatefulWidget {
  @override
  _ShowAuthorsPageState createState() => _ShowAuthorsPageState();
}

class _ShowAuthorsPageState extends State<ShowAuthorsPage> {
  // Fetch all authors from Firestore
  Future<List<DocumentSnapshot>> _fetchAuthors() async {
    var querySnapshot = await FirebaseFirestore.instance.collection("Authors").get();
    return querySnapshot.docs;
  }

  // Function to delete an author
  Future<void> _deleteAuthor(String authorId) async {
    try {
      await FirebaseFirestore.instance.collection('Authors').doc(authorId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Author deleted successfully")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting author")));
    }
  }

  // Function to show delete confirmation dialog
  void _showDeleteDialog(String authorId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Are you sure?'),
          content: Text('Do you really want to delete this author?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteAuthor(authorId);
                Navigator.pop(context); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Authors List"),
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _fetchAuthors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No authors available."));
          } else {
            // List of authors
            List<DocumentSnapshot> authors = snapshot.data!;

            return ListView.builder(
              itemCount: authors.length,
              itemBuilder: (context, index) {
                var author = authors[index].data() as Map<String, dynamic>;
                String authorId = authors[index].id;  // Get the author ID from Firestore
                String authorName = author['name'];
                String authorContact = author['contact'];
                String authorDescription = author['description'];
                String authorImage = author['image_url'];

                return Card(
                  margin: EdgeInsets.all(10),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        // Author image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            authorImage,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 10),
                        // Author details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authorName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text("Contact: $authorContact"),
                              SizedBox(height: 5),
                              Text(
                                "Description: $authorDescription",
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Edit and Delete buttons
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            // Navigate to edit page
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AuthorEditPage(authorId: authorId, authorData: author)),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            _showDeleteDialog(authorId);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
