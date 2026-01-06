import 'dart:convert';
import 'package:bookstore/cart_Service.dart';
import 'package:bookstore/checkout_page.dart';
import 'package:flutter/material.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    loadCart();
  }

  Future<void> loadCart() async {
    cartItems = await CartService.getCart();
    setState(() {});
  }

  double getTotalPrice() {
    double total = 0;
    for (var item in cartItems) {
      int qty = item['quantity'] ?? 1;
      double price = double.tryParse(item['bookPrice'].toString()) ?? 0;
      total += qty * price;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "My Cart",
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Colors.grey[400]),
                  SizedBox(height: 20),
                  Text(
                    "Your cart is empty",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Add items to get started",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      int quantity = item['quantity'] ?? 1;
                      String uuid = item['uuid'] ?? '';

                      return Container(
                        margin: EdgeInsets.only(bottom: 16),
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
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Book Image
                              Container(
                                width: 80,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: item['bookCoverImage'] != null &&
                                        (item['bookCoverImage'] as String)
                                            .isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.memory(
                                          base64Decode(item['bookCoverImage']),
                                          width: 80,
                                          height: 110,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Center(
                                        child: Icon(Icons.book,
                                            size: 40, color: Colors.grey[400]),
                                      ),
                              ),

                              SizedBox(width: 12),

                              // Book details & quantity
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['bookName'] ?? 'No Name',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "₹${item['bookPrice']}",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    // Quantity control
                                    Row(
                                      children: [
                                        // Decrement
                                        InkWell(
                                          onTap: () async {
                                            if (quantity > 1) {
                                              await CartService.updateQuantity(
                                                  uuid, quantity - 1);
                                              loadCart();
                                            }
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.grey[300]!,
                                              ),
                                            ),
                                            child: Icon(Icons.remove,
                                                size: 18, color: Colors.grey[700]),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: Text(
                                            '$quantity',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        // Increment
                                        InkWell(
                                          onTap: () async {
                                            if (quantity < 10) {
                                              await CartService.updateQuantity(
                                                  uuid, quantity + 1);
                                              loadCart();
                                            }
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.grey[300]!,
                                              ),
                                            ),
                                            child: Icon(Icons.add,
                                                size: 18, color: Colors.grey[700]),
                                          ),
                                        ),
                                        Spacer(),
                                        // Delete
                                        IconButton(
                                          icon: Icon(Icons.delete_outline,
                                              size: 22, color: Colors.grey[600]),
                                          onPressed: () async {
                                            await CartService.removeItemByUuid(
                                                uuid);
                                            loadCart();
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Total + Checkout
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Items",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            "${cartItems.length} items",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Divider(color: Colors.grey[200]),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Total",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "₹${getTotalPrice().toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 150,
                            child: ElevatedButton(
                              onPressed: () {
                                if (cartItems.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Cart is empty"),
                                      backgroundColor: Colors.black87,
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CheckoutPage(
                                        cartItems: cartItems,
                                        totalAmount: getTotalPrice(),
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black87,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                "Checkout",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
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
  }
}