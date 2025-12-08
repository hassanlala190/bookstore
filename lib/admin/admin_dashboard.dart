import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Welcome to the Admin Dashboard!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Add more widgets or navigation options for the admin here
            ElevatedButton(
              onPressed: () {
                // Add more functionality as needed
              },
              child: Text("Manage Users"),
            ),
          ],
        ),
      ),
    );
  }
}
