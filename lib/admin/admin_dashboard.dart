import 'package:bookstore/admin/OrderHistory.dart';
import 'package:bookstore/admin/TopBooks.dart';
import 'package:bookstore/admin/admin_login.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'admin_drawer.dart';
import 'add_author.dart';
import 'add_book.dart';
import 'add_category.dart';
import 'show_books.dart';
import 'show_authors.dart';
import 'show_category.dart';
import 'admin_order_page.dart';

class AdminDashboard extends StatefulWidget {
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _checking = true;
  bool _loading = true;
  
  FirebaseFirestore db = FirebaseFirestore.instance;
  
  int _totalBooks = 0;
  int _totalAuthors = 0;
  int _totalCategories = 0;
  int _totalOrders = 0;
  int _pendingOrders = 0;
  int _completedOrders = 0;
  double _totalRevenue = 0.0;

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
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _loading = true);
      
      final booksSnapshot = await db.collection('books').get();
      final authorsSnapshot = await db.collection('authors').get();
      final categoriesSnapshot = await db.collection('categories').get();
      final ordersSnapshot = await db.collection('orders').get();
      final pendingOrdersSnapshot = await db.collection('orders')
          .where('status', isEqualTo: 'pending').get();
      final completedOrdersSnapshot = await db.collection('orders')
          .where('status', isEqualTo: 'completed').get();

      setState(() {
        _totalBooks = booksSnapshot.docs.length;
        _totalAuthors = authorsSnapshot.docs.length;
        _totalCategories = categoriesSnapshot.docs.length;
        _totalOrders = ordersSnapshot.docs.length;
        _pendingOrders = pendingOrdersSnapshot.docs.length;
        _completedOrders = completedOrdersSnapshot.docs.length;
        
        _totalRevenue = 0.0;
        for (var doc in completedOrdersSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = data['totalAmount'];
          if (amount != null) {
            if (amount is int) {
              _totalRevenue += amount.toDouble();
            } else if (amount is double) {
              _totalRevenue += amount;
            }
          }
        }
        
        _loading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: AdminDrawer(),
      appBar: AppBar(
        title: Text(
          "Admin Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black87,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu,
              color: Colors.white,
            ),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loading ? null : _loadDashboardData,
          ),
        ],
      ),
      body: _loading ? _buildLoadingIndicator() : _buildDashboardContent(),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black87, Colors.grey[900]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Loading Dashboard...",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black87, Colors.grey[900]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Text(
            "Loading Dashboard Data...",
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          _buildWelcomeCard(),
          SizedBox(height: 20),

          // Statistics Grid
          _buildStatsGrid(),
          SizedBox(height: 24),

          // Quick Actions
          Text(
            "Quick Actions",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          _buildActionsGrid(),
          SizedBox(height: 32),

          // Manage Sections
          Text(
            "Manage Sections",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          _buildManageSections(),
          SizedBox(height: 32),

          // Performance Overview
          _buildPerformanceCard(),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black87, Colors.grey[900]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome Admin",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Manage your bookstore efficiently",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          title: "Total Books",
          value: _totalBooks.toString(),
          icon: Icons.menu_book,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: "Total Orders",
          value: _totalOrders.toString(),
          icon: Icons.shopping_cart,
          color: Colors.green,
        ),
        _buildStatCard(
          title: "Pending Orders",
          value: _pendingOrders.toString(),
          icon: Icons.pending_actions,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: "Revenue",
          value: "₹${_totalRevenue.toStringAsFixed(2)}",
          icon: Icons.currency_rupee,
          color: Colors.purple,
          subtitle: "${_completedOrders} completed",
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsGrid() {
    List<Map<String, dynamic>> actions = [
      {
        'title': 'Add Author',
        'icon': Icons.person_add,
        'page': AddAuthorPage(),
        'color': Colors.blue[700],
      },
      {
        'title': 'Add Book',
        'icon': Icons.book,
        'page': AddBookPage(),
        'color': Colors.green[700],
      },
      {
        'title': 'Add Category',
        'icon': Icons.category,
        'page': AddCategoryPage(),
        'color': Colors.purple[700],
      },
      {
        'title': 'Order History',
        'icon': Icons.history,
        'page': OrdersHistoryPage(),
        'color': Colors.orange[700],
      },
      {
        'title': 'Top Books',
        'icon': Icons.trending_up,
        'page': TopBooksPage(),
        'color': Colors.red[700],
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        return _buildActionButton(
          title: actions[index]['title'],
          icon: actions[index]['icon'],
          page: actions[index]['page'],
          color: actions[index]['color'] as Color,
        );
      },
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Widget page,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManageSections() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildManageCard(
                title: "Books",
                count: _totalBooks,
                icon: Icons.menu_book,
                color: Colors.blue[700]!,
                page: ShowBooksPage(),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildManageCard(
                title: "Authors",
                count: _totalAuthors,
                icon: Icons.people,
                color: Colors.green[700]!,
                page: ShowAuthorPage(),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildManageCard(
                title: "Categories",
                count: _totalCategories,
                icon: Icons.category,
                color: Colors.purple[700]!,
                page: ShowCategoryPage(),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildManageCard(
                title: "Orders",
                count: _totalOrders,
                icon: Icons.shopping_cart,
                color: Colors.orange[700]!,
                page: AdminOrdersPage(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManageCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "$count items",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard() {
    final completionRate = _totalOrders > 0 
        ? (_completedOrders / _totalOrders * 100).toStringAsFixed(1)
        : '0.0';
        
    final avgOrderValue = _completedOrders > 0
        ? (_totalRevenue / _completedOrders)
        : 0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Performance Overview",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPerformanceMetric(
                title: "Completion",
                value: "$completionRate%",
                color: Colors.green,
              ),
              _buildPerformanceMetric(
                title: "Avg Order",
                value: "₹${avgOrderValue.toStringAsFixed(2)}",
                color: Colors.blue,
              ),
              _buildPerformanceMetric(
                title: "Orders",
                value: _totalOrders.toString(),
                color: Colors.orange,
              ),
            ],
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TopBooksPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                "View Analytics",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric({
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}