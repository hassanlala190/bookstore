import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login.dart';
import 'usershow_books.dart';
import 'my_orders_page.dart';
import 'ShowWishList.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({Key? key}) : super(key: key);

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  int _currentIndex = 0;

  List<Map<String, dynamic>> _featuredBooks = [];
  List<Map<String, dynamic>> _recentBooks = [];
  List<Map<String, dynamic>> _bestSellers = [];
  List<Map<String, dynamic>> _categories = [];

  Map<String, dynamic> _userStats = {
    'totalOrders': 0,
    'wishlistCount': 0,
    'completedOrders': 0,
    'totalSpent': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    await Future.wait([
      _loadFeaturedBooks(),
      _loadRecentBooks(),
      _loadBestSellers(),
      _loadCategories(),
      _loadUserStats(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadFeaturedBooks() async {
    final snap = await _firestore
        .collection('books')
        .orderBy('createdAt', descending: true)
        .limit(4)
        .get();

    _featuredBooks = snap.docs.map((e) {
      final d = e.data();
      return {
        'id': e.id,
        'title': d['bookName'] ?? '',
        'author': d['bookAuthor'] ?? '',
        'price': d['bookPrice'] ?? 0,
        'image': d['bookCoverImage'] ?? '',
        'category': d['bookCategory'] ?? 'General',
      };
    }).toList();
  }

  Future<void> _loadRecentBooks() async {
    final snap = await _firestore
        .collection('books')
        .orderBy('createdAt', descending: true)
        .limit(6)
        .get();

    _recentBooks = snap.docs.map((e) {
      final d = e.data();
      return {
        'title': d['bookName'] ?? '',
        'price': d['bookPrice'] ?? 0,
        'image': d['bookCoverImage'] ?? '',
      };
    }).toList();
  }

  Future<void> _loadBestSellers() async {
    final snap = await _firestore.collection('books').limit(3).get();

    _bestSellers = snap.docs.map((e) {
      final d = e.data();
      return {
        'title': d['bookName'] ?? '',
        'author': d['bookAuthor'] ?? '',
        'price': d['bookPrice'] ?? 0,
        'image': d['bookCoverImage'] ?? '',
      };
    }).toList();
  }

  Future<void> _loadCategories() async {
    final snap = await _firestore.collection('categories').limit(6).get();
    _categories = snap.docs
        .map((e) => {'name': e['name'] ?? ''})
        .toList();
  }

  Future<void> _loadUserStats() async {
    if (user == null) return;

    final orders = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: user!.uid)
        .get();

    double spent = 0;
    int completed = 0;

    for (var o in orders.docs) {
      final d = o.data();
      if (d['status'] == 'completed') completed++;
      spent += (d['totalAmount'] ?? 0).toDouble();
    }

    final wishlist = await _firestore
        .collection('wishlist')
        .doc(user!.uid)
        .collection('items')
        .get();

    _userStats = {
      'totalOrders': orders.docs.length,
      'wishlistCount': wishlist.docs.length,
      'completedOrders': completed,
      'totalSpent': spent,
    };
  }

  Widget _buildImage(String img) {
    if (img.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(
            Icons.book,
            color: Colors.grey[400],
            size: 40,
          ),
        ),
      );
    }
    if (img.startsWith('http')) {
      return Image.network(
        img,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: Icon(
                Icons.book,
                color: Colors.grey[400],
                size: 40,
              ),
            ),
          );
        },
      );
    }
    try {
      final base64String = img.contains(',') ? img.split(',').last : img;
      return Image.memory(
        base64Decode(base64String),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: Icon(
                Icons.book,
                color: Colors.grey[400],
                size: 40,
              ),
            ),
          );
        },
      );
    } catch (_) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(
            Icons.book,
            color: Colors.grey[400],
            size: 40,
          ),
        ),
      );
    }
  }

  String _truncateText(String text, {int maxLength = 20}) {
    if (text.isEmpty) return '';
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? _buildLoadingScreen()
          : SafeArea(
              child: Column(
                children: [
                  // Header with search
                  _header(),
                  
                  // Main Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _statsGrid(),
                          _featuredSection(),
                          _categorySection(),
                          _recentSection(),
                          _bestSellerSection(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
          ),
          SizedBox(height: 20),
          Text(
            'Loading Dashboard...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() => Container(
        color: Colors.white,
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _truncateText(user?.email?.split('@').first ?? 'Reader', maxLength: 15),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.search, color: Colors.black87),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UserShowBooksPage()),
                );
              },
            ),
          ],
        ),
      );

  Widget _statsGrid() => Padding(
        padding: EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _statCard(
              title: 'Orders',
              value: _userStats['totalOrders'].toString(),
              icon: Icons.shopping_bag_outlined,
            ),
            _statCard(
              title: 'Wishlist',
              value: _userStats['wishlistCount'].toString(),
              icon: Icons.favorite_border,
            ),
            _statCard(
              title: 'Completed',
              value: _userStats['completedOrders'].toString(),
              icon: Icons.check_circle_outline,
            ),
            _statCard(
              title: 'Total Spent',
              value: '₹${_userStats['totalSpent'].toStringAsFixed(2)}',
              icon: Icons.currency_rupee,
            ),
          ],
        ),
      );

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.black, size: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _featuredSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Featured Books",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(
            height: 310, // Increased height
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: _featuredBooks.length,
              itemBuilder: (_, i) {
                final b = _featuredBooks[i];
                return Container(
                  width: 175, // Increased width
                  margin: EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Larger image section
                      Container(
                        height: 190, // Increased height
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: _buildImage(b['image'] ?? ''),
                        ),
                      ),
                      
                      // Content with better spacing
                      Padding(
                        padding: EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Book title with 3 lines
                            Text(
                              b['title'] ?? '',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                height: 1.3,
                              ),
                            ),
                            
                            SizedBox(height: 6),
                            
                            // Author
                            Text(
                              _truncateText(b['author'], maxLength: 25),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            
                            SizedBox(height: 10),
                            
                            // Price and category
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "₹${b['price']}",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _truncateText(b['category'], maxLength: 12),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20),
        ],
      );

  Widget _recentSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Recently Added",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(
            height: 240, // Increased height
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: _recentBooks.length,
              itemBuilder: (_, i) {
                final b = _recentBooks[i];
                return Container(
                  width: 160, // Increased width
                  margin: EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image section
                      Container(
                        height: 150, // Increased height
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: _buildImage(b['image'] ?? ''),
                        ),
                      ),
                      
                      // Content
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Book title with 2 lines
                              Text(
                                b['title'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  height: 1.2,
                                ),
                              ),
                              
                              // Price
                              Text(
                                "₹${b['price']}",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20),
        ],
      );

  Widget _categorySection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Categories",
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => UserShowBooksPage()),
                    );
                  },
                  child: Text(
                    'See All',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (_, i) => Container(
                width: 90,
                margin: EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.category_outlined,
                          color: Colors.black,
                          size: 30,
                        ),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      _truncateText(_categories[i]['name'], maxLength: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
        ],
      );

  Widget _bestSellerSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Popular Books",
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: _bestSellers.map((b) => Container(
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: SizedBox(
                    width: 50,
                    height: 70,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildImage(b['image']),
                    ),
                  ),
                  title: Text(
                    _truncateText(b['title'], maxLength: 35),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    _truncateText(b['author'], maxLength: 30),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: Text(
                    "₹${b['price']}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),
          SizedBox(height: 20),
        ],
      );

  BottomNavigationBar _bottomNav() => BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          switch (i) {
            case 0:
              // Already on home
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserShowBooksPage()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MyOrdersPage()),
              );
              break;
            case 3:
              _profileMenu();
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      );

  void _profileMenu() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            
            // User info
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                _truncateText(user?.email?.split('@').first ?? 'User', maxLength: 20),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                _truncateText(user?.email ?? '', maxLength: 25),
                style: TextStyle(
                  fontSize: 12,
                      color: Colors.grey[600],
                ),
              ),
            ),
            
            Divider(height: 20),
            
            // Menu items
            _buildProfileMenuItem(
              icon: Icons.shopping_bag_outlined,
              label: 'My Orders',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MyOrdersPage()),
                );
              },
            ),
            
            _buildProfileMenuItem(
              icon: Icons.favorite_outline,
              label: 'Wishlist',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => WishlistPage()),
                );
              },
            ),
            
            Divider(height: 20),
            
            // Logout button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.red[50],
              ),
              child: ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Colors.red[700],
                ),
                title: Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
                    (route) => false,
                  );
                },
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        label,
        style: TextStyle(
          color: Colors.black87,
          fontSize: 14,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }
}