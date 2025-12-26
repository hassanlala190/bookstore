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
      appBar: AppBar(
        title: const Text("My Cart"),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: cartItems.isEmpty
          ? const Center(
              child: Text(
                "Your cart is empty",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      int quantity = item['quantity'] ?? 1;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: Colors.grey.withOpacity(0.3),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Book Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: item['bookCoverImage'] != null
                                    ? Image.memory(
                                        base64Decode(item['bookCoverImage']),
                                        width: 70,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 70,
                                        height: 100,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.book, size: 40, color: Colors.white),
                                      ),
                              ),

                              const SizedBox(width: 12),

                              // Book details & quantity
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['bookName'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Rs ${item['bookPrice']}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.deepPurple,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Quantity control
                                    Row(
                                      children: [
                                        // Decrement
                                        InkWell(
                                          onTap: () async {
                                            if (quantity > 1) {
                                              await CartService.updateQuantity(item['uuid'], quantity - 1);
                                              loadCart();
                                            }
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.deepPurple.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Icon(Icons.remove, color: Colors.deepPurple),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: Text(
                                            '$quantity',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        // Increment
                                        InkWell(
                                          onTap: () async {
                                            if (quantity < 10) {
                                              await CartService.updateQuantity(item['uuid'], quantity + 1);
                                              loadCart();
                                            }
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.deepPurple.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Icon(Icons.add, color: Colors.deepPurple),
                                          ),
                                        ),
                                        const Spacer(),
                                        // Delete
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                          onPressed: () async {
                                            await CartService.removeFromCart(index);
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Total",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Rs ${getTotalPrice().toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Checkout logic
                          if (cartItems.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Cart is empty")),
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
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          "Checkout",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
