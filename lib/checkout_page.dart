import 'dart:math';
import 'package:bookstore/cart_Service.dart';
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
      builder: (_) => AlertDialog(
        title: const Text("Order Confirmed 🎉"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Your order has been placed successfully."),
            const SizedBox(height: 10),
            Text(
              "Tracking Number:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              trackingNo,
              style: const TextStyle(
                color: Colors.deepPurple,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text("You can track your order using this number."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back from checkout
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              buildField("Full Name", nameCtrl),
              buildField(
                "Email",
                emailCtrl,
                keyboard: TextInputType.emailAddress,
                readOnly: true,
              ),
              buildField("Phone", phoneCtrl, keyboard: TextInputType.phone),
              buildField("Address", addressCtrl, maxLines: 3),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Total Amount: Rs ${widget.totalAmount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: loading ? null : confirmOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Confirm Order",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        readOnly: readOnly,
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: (v) => v!.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
