

import 'dart:io';
import 'dart:convert';
import 'package:bookstore/BookDetails.dart';
import 'package:bookstore/cart_Service.dart';
import 'package:bookstore/cart_page.dart';
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
    
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(8),
      child: Container(
        height: 180,
        child: Row(
          children: [
            // Book Cover Image
            Container(
              width: 120,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
              child: _buildBookImage(data),
            ),
            
            // Book Details
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book Title
                    Text(
                      data['bookName'] ?? "No Title",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    ),
                    
                    SizedBox(height: 4),
                    
                    // Author
                    Text(
                      "Author: ${data['bookAuthor'] ?? "Unknown"}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    
                    // Category
                    Text(
                      "Category: ${data['bookCategory'] ?? "Unknown"}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    
                    // Language
                    Text(
                      "Language: ${data['bookLanguage'] ?? "English"}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    // Stock Status
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: data['bookStock'] == "Yes" ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        data['bookStock'] == "Yes" ? "In Stock" : "Out of Stock",
                        style: TextStyle(
                          fontSize: 12,
                          color: data['bookStock'] == "Yes" ? Colors.green[800] : Colors.red[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    Spacer(),
                    
                    // Price and Action Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "₹${data['bookPrice']?.toStringAsFixed(2) ?? "0.00"}",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                           Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailsPage(data: data),
      ),
    );
                            // _showBookDetails(data);
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                            padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                              EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            ),
                          ),
                          child: Text("View Details"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build book image widget
  Widget _buildBookImage(Map<String, dynamic> data) {
    if (kIsWeb && data['is_web'] == true && data['bookCoverImage'] != null && data['bookCoverImage']!.isNotEmpty) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(4),
            bottomLeft: Radius.circular(4),
          ),
          child: Image.memory(
            base64Decode(data['bookCoverImage']!),
            width: 120,
            height: 180,
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
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
              child: Image.file(
                snapshot.data!,
                width: 120,
                height: 180,
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
      width: 120,
      height: 180,
      color: Colors.grey[200],
      child: Icon(Icons.book, size: 50, color: Colors.grey[400]),
    );
  }
  
  // Show book details dialog
 
  
  // Filter dialog
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("Filter Books"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Filter
                  Text("Category:", style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                    items: categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Author Filter
                  Text("Author:", style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: selectedAuthor,
                    isExpanded: true,
                    onChanged: (value) {
                      setState(() {
                        selectedAuthor = value!;
                      });
                    },
                    items: authors.map((author) {
                      return DropdownMenuItem<String>(
                        value: author,
                        child: Text(author),
                      );
                    }).toList(),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Language Filter
                  Text("Language:", style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: selectedLanguage,
                    isExpanded: true,
                    onChanged: (value) {
                      setState(() {
                        selectedLanguage = value!;
                      });
                    },
                    items: languages.map((language) {
                      return DropdownMenuItem<String>(
                        value: language,
                        child: Text(language),
                      );
                    }).toList(),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Price Range - Manual Input
                  Text("Price Range:", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minPriceController,
                          decoration: InputDecoration(
                            labelText: "Min Price",
                            hintText: "0",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text("to", style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: maxPriceController,
                          decoration: InputDecoration(
                            labelText: "Max Price",
                            hintText: "1000",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Leave empty to show all prices",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Sort By
                  Text("Sort By:", style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: sortBy,
                    isExpanded: true,
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
                        child: Text(sort),
                      );
                    }).toList(),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Stock Filter
                  Text("Stock Status:", style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: selectedStock,
                    isExpanded: true,
                    onChanged: (value) {
                      setState(() {
                        selectedStock = value!;
                      });
                    },
                    items: ["All", "In Stock", "Out of Stock"].map((stock) {
                      return DropdownMenuItem<String>(
                        value: stock,
                        child: Text(stock),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
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
                child: Text("Reset All"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  // Apply filters
                  this.setState(() {});
                  Navigator.pop(context);
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                ),
                child: Text("Apply Filters"),
              ),
            ],
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
      appBar: AppBar(
  title: Text("Book Catalog"),
  actions: [
    // Cart Icon with badge
   ValueListenableBuilder<int>(
  valueListenable: CartService.cartCountNotifier,
  builder: (context, count, _) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart),
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
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                '$count',
                style: const TextStyle(
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
      icon: Icon(Icons.filter_list),
      onPressed: _showFilterDialog,
      tooltip: "Filters",
    ),
  ],
),

      body: Column(
        children: [
          // Search Bar and Price Filter
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                // Main Search Bar
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search books by title, author, or category...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
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
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Text("to", style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: maxPriceController,
                        decoration: InputDecoration(
                          hintText: "Max Price",
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Tooltip(
                      message: "Clear price filters",
                      child: IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          minPriceController.clear();
                          maxPriceController.clear();
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Active Filters Info
          _buildActiveFiltersInfo(),
          
          // Books List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: booksStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.book, size: 80, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                "No books found",
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              if (selectedCategory != "All" || 
                                  selectedAuthor != "All" || 
                                  selectedLanguage != "All")
                                Text(
                                  "Try changing your filters",
                                  style: TextStyle(color: Colors.grey[600]),
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
                                  Icon(Icons.search_off, size: 80, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    "No books match your filters",
                                    style: TextStyle(fontSize: 18, color: Colors.grey),
                                  ),
                                  SizedBox(height: 8),
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
                                    child: Text("Reset All Filters"),
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
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.blue[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Active Filters:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: activeFilters.map((filter) {
              return Chip(
                label: Text(filter, style: TextStyle(fontSize: 11)),
                backgroundColor: Colors.blue[100],
              );
            }).toList(),
          ),
        ],
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