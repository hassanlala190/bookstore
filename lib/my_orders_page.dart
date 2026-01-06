import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'invoice_service.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  Color statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 80, color: Colors.grey[400]),
              SizedBox(height: 20),
              Text(
                "Please login first",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "My Orders",
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
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
                  Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[400]),
                  SizedBox(height: 20),
                  Text(
                    "No orders found",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final data = doc.data() as Map<String, dynamic>;

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
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Order #${doc.id.substring(0, 6)}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor(data['status']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusColor(data['status']).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              data['status'].toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor(data['status']),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Tracking: ${data['trackingNumber']}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Total: ₹${data['totalAmount']}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 12),
                      Divider(color: Colors.grey[200]),
                      SizedBox(height: 12),
                      ...(data['items'] as List).map(
                        (item) => Padding(
                          padding: EdgeInsets.only(bottom: 6),
                          child: Text(
                            "• ${item['bookName']} x${item['quantity']}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Divider(color: Colors.grey[200]),
                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.receipt_long, size: 18),
                          label: Text(
                            "Download Invoice",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onPressed: () {
                            InvoiceService.generateInvoice(
                              context: context,
                              orderId: doc.id,
                              order: data,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}