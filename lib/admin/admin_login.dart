import 'package:bookstore/admin/admin_dashboard.dart';
import 'package:bookstore/login.dart';
import 'package:flutter/material.dart'; // Aapka admin dashboard ya home page

class AdminLoginPage extends StatefulWidget {
  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  // Hardcoded admin credentials
  final String adminEmail = "admin@bookstore.com";
  final String adminPassword = "admin123";

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void loginAdmin() {
    String enteredEmail = emailController.text.trim();
    String enteredPassword = passwordController.text.trim();

    // Check if the entered credentials match the hardcoded ones
    if (enteredEmail == adminEmail && enteredPassword == adminPassword) {
      showMessage("Admin login successful!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdminDashboard()), // Admin Dashboard
      );
    } else {
      showMessage("Invalid admin credentials!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Login")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Admin Login",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              // Email field for admin login
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Enter Admin Email",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),

              // Password field for admin login
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Enter Password",
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),

              // Login button
              ElevatedButton(
                onPressed: loginAdmin,
                child: Text("Login"),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
              TextButton(
                onPressed: (){
                Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => login()), // Admin Dashboard
      );
                },
                child: Text(" Go to User Login"),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
