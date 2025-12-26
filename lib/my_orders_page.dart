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
      return const Scaffold(
        body: Center(child: Text("Please login first")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No orders found"));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final data =
                  doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Order #${doc.id.substring(0, 6)}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          Chip(
                            label: Text(
                              data['status'].toUpperCase(),
                              style: TextStyle(
                                  color:
                                      statusColor(data['status'])),
                            ),
                            backgroundColor: statusColor(
                                    data['status'])
                                .withOpacity(0.2),
                          ),
                        ],
                      ),
                      Text(
                          "Tracking: ${data['trackingNumber']}"),
                      Text(
                        "Total: Rs ${data['totalAmount']}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      ...(data['items'] as List).map(
                        (item) => Text(
                          "• ${item['bookName']} x${item['quantity']}",
                        ),
                      ),
                      const Divider(),
                      ElevatedButton.icon(
                        icon:
                            const Icon(Icons.receipt_long),
                        label:
                            const Text("Download Invoice"),
                        onPressed: () {
                          InvoiceService.generateInvoice(
                            context: context,
                            orderId: doc.id,
                            order: data,
                          );
                        },
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
