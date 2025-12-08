import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'book_edit.dart'; // Import the BookEditPage

class ShowBooksPage extends StatelessWidget {
  FirebaseFirestore db = FirebaseFirestore.instance;

  // Function to delete a book
  Future<void> _deleteBook(BuildContext context, String bookId) async {
    try {
      await db.collection('books').doc(bookId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Book deleted successfully")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting book")));
    }
  }

  // Function to show delete confirmation dialog
  void _showDeleteDialog(BuildContext context, String bookId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Are you sure?'),
          content: Text('Do you really want to delete this book?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteBook(context, bookId);
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
        title: Text("Show Books"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: db.collection('books').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text("No books available"));
            }

            var books = snapshot.data!.docs;

            return ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {
                var book = books[index];
                String bookId = book.id; // Get the book ID
                String bookName = book['bookName'];
                double bookPrice = book['bookPrice'];
                String bookAuthor = book['bookAuthor'];
                String bookCategory = book['bookCategory'];
                String bookCoverImage = book['bookCoverImage'];
                String bookStock = book['bookStock'];

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(10),
                    leading: bookCoverImage.isNotEmpty
                        ? Image.network(bookCoverImage, width: 50, height: 75, fit: BoxFit.cover)
                        : Container(width: 50, height: 75, color: Colors.grey),
                    title: Text(bookName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Author: $bookAuthor"),
                        Text("Category: $bookCategory"),
                        Text("Price: \$${bookPrice.toStringAsFixed(2)}"),
                        Text("Stock: $bookStock"),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit button
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            // Safely cast book data to Map<String, dynamic>
                            Map<String, dynamic> bookData = (book.data() as Map<String, dynamic>? ) ?? {};

                            // Navigate to the Book Edit page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookEditPage(
                                  bookId: bookId,  // Pass the book ID
                                  bookData: bookData,  // Pass the data as a Map<String, dynamic>
                                ),
                              ),
                            );
                          },
                        ),
                        // Delete button
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            _showDeleteDialog(context, bookId);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
