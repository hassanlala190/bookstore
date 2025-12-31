import 'package:bookstore/admin/OrderHistory.dart';
import 'package:bookstore/admin/TopBooks.dart';
import 'package:bookstore/admin/admin_login.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin_drawer.dart';
import 'add_author.dart';
import 'add_book.dart';
import 'add_category.dart';

class AdminDashboard extends StatefulWidget {
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isAdminLoggedIn = prefs.getBool('isAdminLoggedIn') ?? false;

    if (!isAdminLoggedIn) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => AdminLoginPage()),
        (route) => false,
      );
    } else {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
            _dashboardCard(context, "Add Author", Icons.person_add, AddAuthorPage()),
            _dashboardCard(context, "Add Book", Icons.book, AddBookPage()),
            _dashboardCard(context, "Add Category", Icons.category, AddCategoryPage()),
            _dashboardCard(context, "Manage Store", Icons.settings, OrdersHistoryPage()),
            _dashboardCard(context, "Top Books", Icons.sell, TopBooksPage()),
          ],
        ),
      ),
    );
  }

  Widget _dashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    Widget page,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
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
