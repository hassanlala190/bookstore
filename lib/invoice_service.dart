import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

// Web ke liye
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class InvoiceService {
  static Future<void> generateInvoice({
    required BuildContext context,
    required String orderId,
    required Map<String, dynamic> order,
  }) async {
    try {
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
                      fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
                pw.Text("Order ID: $orderId"),
                pw.Text("Status: ${order['status']}"),
                pw.Text("Tracking: ${order['trackingNumber']}"),
                pw.SizedBox(height: 15),
                pw.Text("Items:",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                ...order['items'].map<pw.Widget>((item) {
                  return pw.Text("${item['bookName']} x${item['quantity']}");
                }).toList(),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.Text(
                  "Total Amount: Rs ${order['totalAmount']}",
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();

      if (kIsWeb) {
        // 🌐 Web platform
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'invoice_$orderId.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // 📱 Mobile (Android/iOS)
        final dir = await getApplicationDocumentsDirectory();
        final file = File("${dir.path}/invoice_$orderId.pdf");
        await file.writeAsBytes(bytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Invoice saved at:\n${file.path}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error generating invoice: $e"),
        ),
      );
    }
  }
}
