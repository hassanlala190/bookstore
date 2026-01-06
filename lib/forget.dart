import 'dart:async';
import 'package:bookstore/firebase_options.dart';
import 'package:bookstore/login.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const forget(),
    ),
  );
}

class forget extends StatelessWidget {
  const forget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const ForgetPasswordPage(),
    );
  }
}

class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({super.key});

  @override
  State<ForgetPasswordPage> createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> 
    with SingleTickerProviderStateMixin {
  TextEditingController email = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void show_msg(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> add_user() async {
    setState(() {
      _isLoading = true;
    });

    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      final email_regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

      // Required
      if (email.text.isEmpty) {
        show_msg("Email field is required");
        setState(() => _isLoading = false);
        return;
      }

      // Regular Expression
      if (!email_regex.hasMatch(email.text)) {
        show_msg("Email is invalid");
        setState(() => _isLoading = false);
        return;
      }

      await auth.sendPasswordResetEmail(email: email.text);
      show_msg("Password Reset Email has been Sent!");
      
      // Clear field
      email.text = "";
      
      // Navigate back after 2 seconds
      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (b) => const login()),
          );
        }
      });

    } on FirebaseAuthException catch (e) {
      String errorMessage = "Failed to send reset email";
      if (e.code == 'user-not-found') {
        errorMessage = "No user found with this email";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Incorrect password";
      } else if (e.code == 'too-many-requests') {
        errorMessage = "Too many attempts. Try again later";
      }
      show_msg(errorMessage);
    } catch (e) {
      show_msg("An error occurred. Please try again");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
            ],
            stops: [0.0, 0.2, 0.6, 1.0],
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SizedBox(height: 80),
                    
                    // Logo and Title
                    Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black87,
                                    Colors.grey[900]!,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.lock_reset,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 30),
                            Text(
                              "Reset Password",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Enter your email to receive reset link",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 50),
                    
                    // Reset Form
                    Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Email Field
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: email,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(color: Colors.black87),
                                  decoration: InputDecoration(
                                    labelText: "Email Address",
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
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 20,
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 25),
                              
                              // Info Text
                              Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue[100]!,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.blue[800],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "We'll send you a password reset link to your email address.",
                                        style: TextStyle(
                                          color: Colors.blue[800],
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 30),
                              
                              // Reset Button
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
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : add_user,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "SEND RESET LINK",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Icon(
                                              Icons.send,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              
                              const SizedBox(height: 25),
                              
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
                                    padding: const EdgeInsets.symmetric(horizontal: 15),
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
                              
                              const SizedBox(height: 25),
                              
                              // Back to Login Button
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
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (b) => const login()),
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
                                        Icons.arrow_back_outlined,
                                        color: Colors.grey[700],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        "BACK TO LOGIN",
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
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Footer
                    Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        children: [
                          Text(
                            "Check your inbox for the password reset link",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Link expires in 1 hour",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "© 2024 BookStore. All rights reserved.",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}