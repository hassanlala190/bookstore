import 'package:bookstore/admin/OrderHistory.dart';
import 'package:bookstore/admin/TopBooks.dart';
import 'package:flutter/material.dart';
import 'admin_drawer.dart';
import 'add_author.dart';
import 'add_book.dart';
import 'add_category.dart';

class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard"),
        backgroundColor: Colors.black,
      ),
      drawer: AdminDrawer(),
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _dashboardCard(
              context,
              "Add Author",
              Icons.person_add,
              AddAuthorPage(),
            ),
            _dashboardCard(
              context,
              "Add Book",
              Icons.book,
              AddBookPage(),
            ),
            _dashboardCard(
              context,
              "Add Category",
              Icons.category,
              AddCategoryPage(),
            ),
            _dashboardCard(
              context,
              "Manage Store",
              Icons.settings,
              OrdersHistoryPage(),
            ),
            _dashboardCard(
              context,
              "Top Books",
              Icons.sell,
              TopBooksPage(),
            ),

          ],
        ),
      ),
    );
  }

  Widget _dashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    Widget? page,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        if (page != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.black, Colors.grey.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(2, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
