import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

class InvoiceService {
  static Future<void> generateInvoice({
    required BuildContext context,
    required String orderId,
    required Map<String, dynamic> order,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "INVOICE",
                style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),

              pw.Text("Order ID: $orderId"),
              pw.Text("Status: ${order['status']}"),
              pw.Text("Tracking: ${order['trackingNumber']}"),

              pw.SizedBox(height: 15),
              pw.Text("Items:",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold)),

              pw.SizedBox(height: 8),

              ...order['items'].map<pw.Widget>((item) {
                return pw.Text(
                    "${item['bookName']} x${item['quantity']}");
              }).toList(),

              pw.SizedBox(height: 20),
              pw.Divider(),

              pw.Text(
                "Total Amount: Rs ${order['totalAmount']}",
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/invoice_$orderId.pdf");

    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Invoice saved:\n${file.path}"),
      ),
    );
  }
}
