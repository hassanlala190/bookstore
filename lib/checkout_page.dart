import 'dart:math';
import 'package:bookstore/attractive_dashboard.dart';
import 'package:bookstore/cart_Service.dart';
import 'package:bookstore/dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;

  const CheckoutPage({
    super.key,
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  bool loading = false;

  @override
  void initState() {
    super.initState();
    setUserEmail();
  }

  void setUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      emailCtrl.text = user.email!;
    }
  }

  String generateTracking() {
    return "TRK${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
  }

  Future<void> confirmOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    String trackingNo = generateTracking();

    await FirebaseFirestore.instance.collection('orders').add({
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'name': nameCtrl.text,
      'email': emailCtrl.text,
      'phone': phoneCtrl.text,
      'address': addressCtrl.text,
      'totalAmount': widget.totalAmount,
      'items': widget.cartItems,
      'status': 'pending',
      'trackingNumber': trackingNo,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 🔥 CLEAR CART
    await CartService.clearCart();

    setState(() => loading = false);

    // 🔔 ALERT DIALOG
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext con) {
        return AlertDialog(
          title: Text(
            "Order Confirmed 🎉",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Your order has been placed successfully.",
                style: TextStyle(color: Colors.grey[700]),
              ),
              SizedBox(height: 16),
              Text(
                "Tracking Number:",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  trackingNo,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 12),
              Text(
                "You can track your order using this number.",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(con); // close dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => UserDashboard()),
                  (route) => false, // saari previous screens remove
                );
              },
              child: Text(
                "Continue",
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Checkout",
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                "Shipping Details",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),

              buildField("Full Name", nameCtrl),
              buildField(
                "Email",
                emailCtrl,
                keyboard: TextInputType.emailAddress,
                readOnly: true,
              ),
              buildField("Phone", phoneCtrl, keyboard: TextInputType.phone),
              buildField("Address", addressCtrl, maxLines: 3),

              SizedBox(height: 24),

              Text(
                "Order Summary",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),

              Container(
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
                          "${widget.cartItems.length} items",
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
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total Amount",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          "₹${widget.totalAmount.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : confirmOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: loading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          "Confirm Order",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildField(
    String label,
    TextEditingController ctrl, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        readOnly: readOnly,
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: (v) => v!.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.black87, width: 1.5),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: TextStyle(color: Colors.black87),
      ),
    );
  }
}