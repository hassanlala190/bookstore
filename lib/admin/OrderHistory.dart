import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class OrdersHistoryPage extends StatefulWidget {
  const OrdersHistoryPage({super.key});

  @override
  State<OrdersHistoryPage> createState() => _OrdersHistoryPageState();
}

class _OrdersHistoryPageState extends State<OrdersHistoryPage> {
  bool isSending = false;

  Color statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'not_completed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String statusText(String status) {
    return status == 'completed' ? 'COMPLETED' : 'NOT COMPLETED';
  }

  Widget infoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            "$label:",
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> sendOrdersEmail(List<QueryDocumentSnapshot> orders) async {
    setState(() {
      isSending = true;
    });

    try {
      final ordersData = orders.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'name': data['name'],
          'email': data['email'],
          'trackingNumber': data['trackingNumber'],
          'totalAmount': data['totalAmount'],
          'status': data['status'],
          'notCompleteReason': data['notCompleteReason'],
        };
      }).toList();

      final callable =
          FirebaseFunctions.instance.httpsCallable('sendOrdersEmail');

      final response = await callable.call({
        'to': 'recipient@example.com', // jisko email bhejna hai
        'orders': ordersData,
        'subject': 'Orders History',
        'message': 'Please find attached orders history.',
      });

      if (response.data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email sent successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.data['error']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Orders History"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
       
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('status', whereIn: ['completed', 'not_completed'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No order history found"));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            data['name'] ?? 'Customer',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor(status).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusText(status),
                              style: TextStyle(
                                  color: statusColor(status),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      infoRow("Email", data['email'] ?? '', Icons.email),
                      infoRow("Tracking", data['trackingNumber'] ?? '-',
                          Icons.local_shipping),
                      infoRow(
                        "Total",
                        "Rs ${data['totalAmount']}",
                        Icons.payments,
                      ),
                      if (status == 'not_completed' &&
                          data['notCompleteReason'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            "Reason: ${data['notCompleteReason']}",
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13),
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
