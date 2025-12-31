import 'package:bookstore/admin/admin_dashboard.dart';
import 'package:bookstore/login.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminLoginPage extends StatefulWidget {
  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final String adminEmail = "admin@bookstore.com";
  final String adminPassword = "admin123";

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
        ));
  }

  Future<void> loginAdmin() async {
    String enteredEmail = emailController.text.trim();
    String enteredPassword = passwordController.text.trim();

    if (enteredEmail == adminEmail && enteredPassword == adminPassword) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAdminLoggedIn', true);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AdminDashboard()),
      );
    } else {
      showMessage("Invalid admin credentials!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.grey[50]!,
              Colors.grey[100]!,
              Colors.grey[200]!,
              Colors.grey[300]!,
            ],
            stops: [0.0, 0.2, 0.5, 0.8, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo/Icon Section
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black87,
                          Colors.grey[800]!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(60),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  
                  SizedBox(height: 30),
                  
                  // Title
                  Text(
                    "ADMIN PORTAL",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: Colors.black87,
                      shadows: [
                        Shadow(
                          blurRadius: 2,
                          color: Colors.grey.withOpacity(0.3),
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  
                  Text(
                    "Secure Access Only",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  SizedBox(height: 40),
                  
                  // Login Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    padding: EdgeInsets.all(30),
                    child: Column(
                      children: [
                        Text(
                          "Login to Dashboard",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        
                        SizedBox(height: 25),
                        
                        // Email Field
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: emailController,
                            style: TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              labelText: "Admin Email",
                              labelStyle: TextStyle(color: Colors.grey[700]),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: Colors.grey[700],
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.black54,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Password Field
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: passwordController,
                            obscureText: true,
                            style: TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              labelText: "Password",
                              labelStyle: TextStyle(color: Colors.grey[700]),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: Colors.grey[700],
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.black54,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 30),
                        
                        // Login Button
                        Container(
                          width: double.infinity,
                          height: 55,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                Colors.black87,
                                Colors.grey[900]!,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: loginAdmin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "ACCESS DASHBOARD",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey[300],
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              child: Text(
                                "OR",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey[300],
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 20),
                        
                        // User Login Button
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => login()),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  color: Colors.grey[700],
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Go to User Login",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 30),
                  
                  // Footer
                  Text(
                    "For authorized personnel only",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  
                  SizedBox(height: 10),
                  
                  Text(
                    "© 2024 BookStore Admin System",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}