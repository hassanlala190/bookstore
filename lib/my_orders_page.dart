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

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        backgroundColor: Colors.deepPurple,
      ),
      body: user == null
          ? const Center(child: Text("Please login first"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('userId', isEqualTo: user.uid)
                  // ❗ Index banane ke baad ye uncomment karna
                  // .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No orders found"));
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
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            /// HEADER
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Order #${doc.id.substring(0, 6)}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor(
                                            data['status'])
                                        .withOpacity(0.2),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    data['status']
                                        .toString()
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor(
                                          data['status']),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),
                            Text(
                                "Tracking: ${data['trackingNumber'] ?? 'N/A'}"),

                            const SizedBox(height: 6),
                            Text(
                              "Total: Rs ${data['totalAmount']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),

                            const Divider(height: 20),

                            const Text(
                              "Items:",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),

                            ...(data['items'] as List).map(
                              (item) => Text(
                                "• ${item['bookName']}  x${item['quantity']}",
                                style:
                                    const TextStyle(fontSize: 13),
                              ),
                            ),

                            const Divider(height: 20),

                            /// INVOICE BUTTON
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(
                                    Icons.receipt_long),
                                label: const Text("Download Invoice"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.deepPurple,
                                ),
                                onPressed: () async {
                                  await InvoiceService
                                      .generateInvoice(
                                    context: context,
                                    orderId: doc.id,
                                    order: data,
                                  );
                                },
                              ),
                            ),

                            /// STATUS MESSAGE
                            if (data['status'] == 'approved') ...[
                              const SizedBox(height: 10),
                              Row(
                                children: const [
                                  Icon(Icons.local_shipping,
                                      color: Colors.green),
                                  SizedBox(width: 6),
                                  Text(
                                    "Order approved & processing",
                                    style: TextStyle(
                                        color: Colors.green),
                                  ),
                                ],
                              ),
                            ],

                            if (data['status'] == 'rejected') ...[
                              const SizedBox(height: 10),
                              Row(
                                children: const [
                                  Icon(Icons.cancel,
                                      color: Colors.red),
                                  SizedBox(width: 6),
                                  Text(
                                    "Order rejected by admin",
                                    style: TextStyle(
                                        color: Colors.red),
                                  ),
                                ],
                              ),
                            ],
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
