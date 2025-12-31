import 'package:bookstore/admin/admin_login.dart';
import 'package:bookstore/admin/admin_order_page.dart';
import 'package:bookstore/admin/all_users.dart';
import 'package:bookstore/admin/approved_order.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.grey[50]!,
              Colors.grey[100]!,
              Colors.grey[200]!,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border(
            right: BorderSide(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            _drawerHeader(),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _sectionTitle("MANAGEMENT"),
                    _item(
                      context,
                      Icons.person,
                      Colors.black87,
                      "Users",
                      "Manage all system users",
                      AdminUsersPage(),
                    ),
                    _item(
                      context,
                      Icons.shopping_cart,
                      Colors.black87,
                      "User Orders",
                      "View customer orders",
                      AdminOrdersPage(),
                    ),
                    _item(
                      context,
                      Icons.check_circle,
                      Colors.black87,
                      "Approved Orders",
                      "Completed orders",
                      ApprovedOrdersPage(),
                    ),
                    
                    _divider(),
                    
                    _sectionTitle("AUTHORS"),
                    _item(
                      context,
                      Icons.person_add,
                      Colors.grey[800]!,
                      "Add Author",
                      "Add new author",
                      AddAuthorPage(),
                    ),
                    _item(
                      context,
                      Icons.people,
                      Colors.grey[800]!,
                      "Show Authors",
                      "View all authors",
                      ShowAuthorPage(),
                    ),
                    
                    _divider(),
                    
                    _sectionTitle("BOOKS"),
                    _item(
                      context,
                      Icons.book,
                      Colors.grey[800]!,
                      "Add Book",
                      "Add new book",
                      AddBookPage(),
                    ),
                    _item(
                      context,
                      Icons.menu_book,
                      Colors.grey[800]!,
                      "Show Books",
                      "View all books",
                      ShowBooksPage(),
                    ),
                    
                    _divider(),
                    
                    _sectionTitle("CATEGORIES"),
                    _item(
                      context,
                      Icons.category,
                      Colors.grey[800]!,
                      "Add Category",
                      "Add new category",
                      AddCategoryPage(),
                    ),
                    _item(
                      context,
                      Icons.list_alt,
                      Colors.grey[800]!,
                      "Show Categories",
                      "View all categories",
                      ShowCategoryPage(),
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer with Logout
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black87,
                          Colors.grey[800]!,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.logout,
                        color: Colors.white,
                      ),
                      title: Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.white70,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 15),
                      onTap: () async {
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => AdminLoginPage()),
                          (route) => false,
                        );
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "BookStore Admin v1.0",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black87,
            Colors.grey[900]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(25),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(
              Icons.admin_panel_settings,
              color: Colors.black,
              size: 35,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ADMIN PANEL",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        blurRadius: 2,
                        color: Colors.black,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "BookStore Management System",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 5),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        "Online",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, Color iconColor, 
      String title, String subtitle, Widget? page) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey[100]!,
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[500],
          size: 20,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 10),
        visualDensity: VisualDensity.comfortable,
        onTap: () {
          Navigator.pop(context);
          if (page != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => page),
            );
          }
        },
      ),
    );
  }

  Widget _divider() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.grey[300]!,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}