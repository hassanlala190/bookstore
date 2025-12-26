import 'package:bookstore/admin/admin_order_page.dart';
import 'package:bookstore/admin/all_users.dart';
import 'package:flutter/material.dart';

// Pages
import 'add_author.dart';
import 'add_book.dart';
import 'add_category.dart';
import 'show_authors.dart';
import 'show_books.dart';
import 'show_category.dart';

class AdminDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.grey.shade900],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          children: [
            _drawerHeader(),

            _item(context, Icons.dashboard, "Dashboard", null),
            _divider(),

            _item(context, Icons.person_add, "Users", AdminUsersPage()),
            _item(context, Icons.people, "User Orders", AdminOrdersPage()),
            _divider(),

            _item(context, Icons.person_add, "Add Author", AddAuthorPage()),
            _item(context, Icons.people, "Show Authors", ShowAuthorPage()),
            _divider(),

            _item(context, Icons.book, "Add Book", AddBookPage()),
            _item(context, Icons.menu_book, "Show Books", ShowBooksPage()),

            _divider(),

            _item(context, Icons.category, "Add Category", AddCategoryPage()),
            _item(context, Icons.list_alt, "Show Categories", ShowCategoryPage()),

            _divider(),

            ListTile(
              leading: Icon(Icons.logout, color: Colors.redAccent),
              title: Text("Logout", style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.white],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.admin_panel_settings, color: Colors.white, size: 50),
          SizedBox(height: 10),
          Text(
            "ADMIN PANEL",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          Text(
            "Book Store Management",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String title, Widget? page) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title,
          style: TextStyle(color: Colors.white, fontSize: 15)),
      hoverColor: Colors.white12,
      onTap: () {
        Navigator.pop(context);
        if (page != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        }
      },
    );
  }

  Widget _divider() {
    return Divider(color: Colors.white24);
  }
}
