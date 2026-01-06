import 'dart:io';
import 'dart:convert';
import 'package:bookstore/BookDetails.dart';
import 'package:bookstore/cart_Service.dart';
import 'package:bookstore/cart_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

class UserShowBooksPage extends StatefulWidget {
  @override
  _UserShowBooksPageState createState() => _UserShowBooksPageState();
}

class _UserShowBooksPageState extends State<UserShowBooksPage> {
  FirebaseFirestore db = FirebaseFirestore.instance;
  
  // Search and Filter variables
  TextEditingController searchController = TextEditingController();
  TextEditingController minPriceController = TextEditingController();
  TextEditingController maxPriceController = TextEditingController();
  
  String selectedCategory = "All";
  String selectedAuthor = "All";
  String selectedLanguage = "All";
  String sortBy = "Newest First";
  String selectedStock = "All";
  
  // Data lists
  List<String> categories = ["All"];
  List<String> authors = ["All"];
  List<String> languages = ["All", "English", "Urdu"];
  
  // Loading states
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _fetchFilterData();
  }
  
  // Fetch categories and authors for filters
  void _fetchFilterData() async {
    try {
      // Fetch categories
      QuerySnapshot categoriesSnapshot = await db.collection('categories').get();
      List<String> categoryList = categoriesSnapshot.docs
          .map((doc) => doc['name'] as String)
          .toList();
      
      // Fetch authors
      QuerySnapshot authorsSnapshot = await db.collection('authors').get();
      List<String> authorList = authorsSnapshot.docs
          .map((doc) => doc['name'] as String)
          .toList();
      
      setState(() {
        categories.addAll(categoryList);
        authors.addAll(authorList);
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching filter data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Build book card widget
  Widget _buildBookCard(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          // Book Cover Image
          Container(
            width: 110,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: _buildBookImage(data),
          ),
          
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book Title (Clickable)
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookDetailsPage(data: data, docId: doc.id),
                        ),
                      );
                    },
                    child: Text(
                      data['bookName']?.toString() ?? "No Title",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  SizedBox(height: 4),

                  // Author
                  Text(
                    data['bookAuthor']?.toString() ?? "Unknown Author",
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: 4),

                  // Category
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      data['bookCategory']?.toString() ?? "General",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 6),

                  // Stock Status
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: data['bookStock']?.toString() == "Yes"
                              ? Colors.green[50]
                              : Colors.red[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: data['bookStock']?.toString() == "Yes"
                                ? Colors.green[100]!
                                : Colors.red[100]!,
                          ),
                        ),
                        child: Text(
                          data['bookStock']?.toString() == "Yes"
                              ? "In Stock"
                              : "Out of Stock",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: data['bookStock']?.toString() == "Yes"
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                        ),
                      ),
                      Spacer(),
                      // Price
                      Text(
                        "₹${(data['bookPrice'] as num?)?.toStringAsFixed(2) ?? "0.00"}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build book image widget
  Widget _buildBookImage(Map<String, dynamic> data) {
    if (kIsWeb && data['is_web'] == true && data['bookCoverImage'] != null && data['bookCoverImage']!.isNotEmpty) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
          child: Image.memory(
            base64Decode(data['bookCoverImage']!),
            width: 110,
            height: 160,
            fit: BoxFit.cover,
          ),
        );
      } catch (e) {
        return _buildPlaceholderImage();
      }
    } else if (!kIsWeb && data['bookCoverImage'] != null && data['bookCoverImage']!.isNotEmpty) {
      return FutureBuilder<File>(
        future: _getImageFile(data['bookCoverImage']!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildPlaceholderImage();
          }
          if (snapshot.hasData) {
            return ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Image.file(
                snapshot.data!,
                width: 110,
                height: 160,
                fit: BoxFit.cover,
              ),
            );
          }
          return _buildPlaceholderImage();
        },
      );
    }
    
    return _buildPlaceholderImage();
  }
  
  Widget _buildPlaceholderImage() {
    return Container(
      width: 110,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
      ),
      child: Center(
        child: Icon(Icons.book, size: 40, color: Colors.grey[400]),
      ),
    );
  }
  
  // Filter dialog with theme
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Filter Books",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey[300]),
                  SizedBox(height: 10),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Filter
                          Text("Category", style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          )),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: DropdownButton<String>(
                              value: selectedCategory,
                              isExpanded: true,
                              underline: SizedBox(),
                              onChanged: (value) {
                                setState(() {
                                  selectedCategory = value!;
                                });
                              },
                              items: categories.map((category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category, style: TextStyle(color: Colors.black87)),
                                );
                              }).toList(),
                            ),
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Author Filter
                          Text("Author", style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          )),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: DropdownButton<String>(
                              value: selectedAuthor,
                              isExpanded: true,
                              underline: SizedBox(),
                              onChanged: (value) {
                                setState(() {
                                  selectedAuthor = value!;
                                });
                              },
                              items: authors.map((author) {
                                return DropdownMenuItem<String>(
                                  value: author,
                                  child: Text(author, style: TextStyle(color: Colors.black87)),
                                );
                              }).toList(),
                            ),
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Language Filter
                          Text("Language", style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          )),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: DropdownButton<String>(
                              value: selectedLanguage,
                              isExpanded: true,
                              underline: SizedBox(),
                              onChanged: (value) {
                                setState(() {
                                  selectedLanguage = value!;
                                });
                              },
                              items: languages.map((language) {
                                return DropdownMenuItem<String>(
                                  value: language,
                                  child: Text(language, style: TextStyle(color: Colors.black87)),
                                );
                              }).toList(),
                            ),
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Price Range
                          Text("Price Range", style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          )),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: minPriceController,
                                  decoration: InputDecoration(
                                    hintText: "Min",
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[200]!),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text("to", style: TextStyle(color: Colors.grey[600])),
                              SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: maxPriceController,
                                  decoration: InputDecoration(
                                    hintText: "Max",
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[200]!),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Leave empty for all prices",
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Sort By
                          Text("Sort By", style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          )),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: DropdownButton<String>(
                              value: sortBy,
                              isExpanded: true,
                              underline: SizedBox(),
                              onChanged: (value) {
                                setState(() {
                                  sortBy = value!;
                                });
                              },
                              items: [
                                "Newest First",
                                "Price: Low to High",
                                "Price: High to Low",
                                "Title: A to Z",
                                "Title: Z to A",
                              ].map((sort) {
                                return DropdownMenuItem<String>(
                                  value: sort,
                                  child: Text(sort, style: TextStyle(color: Colors.black87)),
                                );
                              }).toList(),
                            ),
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Stock Filter
                          Text("Stock Status", style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          )),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: DropdownButton<String>(
                              value: selectedStock,
                              isExpanded: true,
                              underline: SizedBox(),
                              onChanged: (value) {
                                setState(() {
                                  selectedStock = value!;
                                });
                              },
                              items: ["All", "In Stock", "Out of Stock"].map((stock) {
                                return DropdownMenuItem<String>(
                                  value: stock,
                                  child: Text(stock, style: TextStyle(color: Colors.black87)),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Reset filters
                            setState(() {
                              selectedCategory = "All";
                              selectedAuthor = "All";
                              selectedLanguage = "All";
                              selectedStock = "All";
                              minPriceController.clear();
                              maxPriceController.clear();
                              sortBy = "Newest First";
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            "Reset All",
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            this.setState(() {});
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Apply Filters",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  // SIMPLE QUERY FIX - Remove multiple where clauses initially
  Stream<QuerySnapshot> get booksStream {
    // Start with basic query
    Query query = db.collection('books');
    
    // Apply sorting
    switch (sortBy) {
      case "Newest First":
        query = query.orderBy('createdAt', descending: true);
        break;
      case "Price: Low to High":
        query = query.orderBy('bookPrice', descending: false);
        break;
      case "Price: High to Low":
        query = query.orderBy('bookPrice', descending: true);
        break;
      case "Title: A to Z":
        query = query.orderBy('bookName', descending: false);
        break;
      case "Title: Z to A":
        query = query.orderBy('bookName', descending: true);
        break;
      default:
        query = query.orderBy('createdAt', descending: true);
    }
    
    return query.snapshots();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Book Catalog",
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          // Cart Icon with badge
          ValueListenableBuilder<int>(
            valueListenable: CartService.cartCountNotifier,
            builder: (context, count, _) {
              return Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: Icon(Icons.shopping_cart, color: Colors.black87),
                    tooltip: "My Cart",
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartPage()),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Filter Icon
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.black87),
            onPressed: _showFilterDialog,
            tooltip: "Filters",
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar and Price Filter
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Main Search Bar
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search books by title, author, or category...",
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[600]),
                            onPressed: () {
                              searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  style: TextStyle(color: Colors.black87),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                
                SizedBox(height: 12),
                
                // Quick Price Filter
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minPriceController,
                        decoration: InputDecoration(
                          hintText: "Min Price",
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: Colors.black87),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    Text("to", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: maxPriceController,
                        decoration: InputDecoration(
                          hintText: "Max Price",
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: Colors.black87),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Tooltip(
                      message: "Clear price filters",
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600], size: 20),
                          onPressed: () {
                            minPriceController.clear();
                            maxPriceController.clear();
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Active Filters Info (without heading)
          _buildActiveFiltersInfo(),
          
          // Books List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Colors.black87,
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: booksStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: Colors.black87,
                          ),
                        );
                      }
                      
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.book, size: 80, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text(
                                "No books found",
                                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                              ),
                              if (selectedCategory != "All" || 
                                  selectedAuthor != "All" || 
                                  selectedLanguage != "All")
                                Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text(
                                    "Try changing your filters",
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }
                      
                      // Apply all filters locally
                      List<DocumentSnapshot> filteredBooks = snapshot.data!.docs;
                      
                      // Apply search filter
                      if (searchController.text.isNotEmpty) {
                        String searchQuery = searchController.text.toLowerCase();
                        filteredBooks = filteredBooks.where((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          return (data['bookName']?.toString().toLowerCase().contains(searchQuery) ?? false) ||
                                 (data['bookAuthor']?.toString().toLowerCase().contains(searchQuery) ?? false) ||
                                 (data['bookCategory']?.toString().toLowerCase().contains(searchQuery) ?? false);
                        }).toList();
                      }
                      
                      // Apply category filter locally
                      if (selectedCategory != "All") {
                        filteredBooks = filteredBooks.where((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          return data['bookCategory'] == selectedCategory;
                        }).toList();
                      }
                      
                      // Apply author filter locally
                      if (selectedAuthor != "All") {
                        filteredBooks = filteredBooks.where((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          return data['bookAuthor'] == selectedAuthor;
                        }).toList();
                      }
                      
                      // Apply language filter locally
                      if (selectedLanguage != "All") {
                        filteredBooks = filteredBooks.where((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          return data['bookLanguage'] == selectedLanguage;
                        }).toList();
                      }
                      
                      // Apply stock filter locally
                      if (selectedStock == "In Stock") {
                        filteredBooks = filteredBooks.where((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          return data['bookStock'] == "Yes";
                        }).toList();
                      } else if (selectedStock == "Out of Stock") {
                        filteredBooks = filteredBooks.where((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          return data['bookStock'] == "No";
                        }).toList();
                      }
                      
                      // Apply price range filter locally
                      double? minPrice = _parsePrice(minPriceController.text);
                      double? maxPrice = _parsePrice(maxPriceController.text);
                      
                      if (minPrice != null || maxPrice != null) {
                        filteredBooks = filteredBooks.where((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          double price = (data['bookPrice'] as num?)?.toDouble() ?? 0;
                          
                          bool minCondition = minPrice == null || price >= minPrice;
                          bool maxCondition = maxPrice == null || price <= maxPrice;
                          
                          return minCondition && maxCondition;
                        }).toList();
                      }
                      
                      // Apply sorting locally
                      filteredBooks.sort((a, b) {
                        var dataA = a.data() as Map<String, dynamic>;
                        var dataB = b.data() as Map<String, dynamic>;
                        
                        switch (sortBy) {
                          case "Price: Low to High":
                            double priceA = (dataA['bookPrice'] as num?)?.toDouble() ?? 0;
                            double priceB = (dataB['bookPrice'] as num?)?.toDouble() ?? 0;
                            return priceA.compareTo(priceB);
                            
                          case "Price: High to Low":
                            double priceA = (dataA['bookPrice'] as num?)?.toDouble() ?? 0;
                            double priceB = (dataB['bookPrice'] as num?)?.toDouble() ?? 0;
                            return priceB.compareTo(priceA);
                            
                          case "Title: A to Z":
                            String titleA = dataA['bookName'] ?? "";
                            String titleB = dataB['bookName'] ?? "";
                            return titleA.compareTo(titleB);
                            
                          case "Title: Z to A":
                            String titleA = dataA['bookName'] ?? "";
                            String titleB = dataB['bookName'] ?? "";
                            return titleB.compareTo(titleA);
                            
                          default: // Newest First
                            return 0; // Already sorted by createdAt
                        }
                      });
                      
                      return filteredBooks.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                                  SizedBox(height: 16),
                                  Text(
                                    "No books match your filters",
                                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                  ),
                                  SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      // Reset all filters
                                      searchController.clear();
                                      minPriceController.clear();
                                      maxPriceController.clear();
                                      selectedCategory = "All";
                                      selectedAuthor = "All";
                                      selectedLanguage = "All";
                                      selectedStock = "All";
                                      sortBy = "Newest First";
                                      setState(() {});
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black87,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      "Reset All Filters",
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredBooks.length,
                              itemBuilder: (context, index) {
                                return _buildBookCard(filteredBooks[index]);
                              },
                            );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  // Parse price from text input
  double? _parsePrice(String priceText) {
    if (priceText.trim().isEmpty) return null;
    try {
      return double.tryParse(priceText.trim());
    } catch (e) {
      return null;
    }
  }
  
  Widget _buildActiveFiltersInfo() {
    List<String> activeFilters = [];
    
    if (selectedCategory != "All") activeFilters.add("Category: $selectedCategory");
    if (selectedAuthor != "All") activeFilters.add("Author: $selectedAuthor");
    if (selectedLanguage != "All") activeFilters.add("Language: $selectedLanguage");
    if (selectedStock != "All") activeFilters.add("Stock: $selectedStock");
    
    double? minPrice = _parsePrice(minPriceController.text);
    double? maxPrice = _parsePrice(maxPriceController.text);
    
    if (minPrice != null || maxPrice != null) {
      String priceFilter = "Price: ";
      if (minPrice != null) priceFilter += "₹${minPrice.toStringAsFixed(0)}";
      priceFilter += " to ";
      if (maxPrice != null) priceFilter += "₹${maxPrice.toStringAsFixed(0)}";
      activeFilters.add(priceFilter);
    }
    
    activeFilters.add("Sort: $sortBy");
    
    if (activeFilters.isEmpty) return Container();
    
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12), // Removed top padding
      color: Colors.grey[50],
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: activeFilters.map((filter) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              filter,
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            ),
          );
        }).toList(),
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