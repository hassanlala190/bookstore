import 'dart:async';
import 'package:bookstore/admin/add_author.dart';
import 'package:bookstore/admin/add_book.dart';
import 'package:bookstore/admin/admin_dashboard.dart';
import 'package:bookstore/admin/admin_login.dart';
import 'package:bookstore/admin/show_authors.dart';
import 'package:bookstore/dashboard.dart';
import 'package:bookstore/firebase_options.dart';
import 'package:bookstore/login.dart';
import 'package:bookstore/usershow_books.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      builder: (context) => MyApp(), // Wrap your app
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _bookRotateAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations with 8 seconds duration
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    // Logo fade in animation (0-2 seconds)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.25, curve: Curves.easeInOut),
      ),
    );
    
    // Logo scale animation (0.5-3 seconds)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.5, end: 1.1),
        weight: 50,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.1, end: 1.0),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.375, curve: Curves.easeInOut),
      ),
    );
    
    // Book rotation animation (1-4 seconds)
    _bookRotateAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 50,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.125, 0.5, curve: Curves.easeInOut),
      ),
    );
    
    // Title slide animation (2-5 seconds)
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: const Offset(0, 0),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.25, 0.625, curve: Curves.elasticOut),
      ),
    );
    
    // Progress bar animation (3-8 seconds)
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.375, 1.0, curve: Curves.linear),
      ),
    );
    
    // Start animations
    _controller.forward();
    
    // Navigate after 8 seconds
    Timer(
      const Duration(seconds: 8),
      () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminLoginPage()),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated Background Pattern
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _controller.value > 0.1 ? 1.0 : 0.0,
                  child: CustomPaint(
                    painter: _BookPatternPainter(animationValue: _controller.value),
                  ),
                );
              },
            ),
            
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with multiple animations
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: RotationTransition(
                        turns: _bookRotateAnimation,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black87,
                                Colors.grey[900]!,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            size: 70,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // App Title with slide animation
                  SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              colors: [
                                Colors.black87,
                                Colors.grey[800]!,
                              ],
                            ).createShader(bounds);
                          },
                          child: Text(
                            "BOOKSTORE",
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _controller.value > 0.3 ? 1.0 : 0.0,
                              child: Transform.translate(
                                offset: Offset(0, _controller.value > 0.3 ? 0 : 10),
                                child: Text(
                                  "Admin Management System",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                  
                  // Loading Progress Container
                  Container(
                    width: 250,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Progress Bar
                        Container(
                          width: 200,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Stack(
                            children: [
                              AnimatedBuilder(
                                animation: _progressAnimation,
                                builder: (context, child) {
                                  return Container(
                                    width: 200 * _progressAnimation.value,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black87,
                                          Colors.grey[800]!,
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // Loading Text
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            List<String> loadingTexts = [
                              "Initializing Admin Panel...",
                              "Loading Database...",
                              "Configuring Security...",
                              "Preparing Dashboard...",
                              "Almost Ready...",
                              "Launching Admin Portal..."
                            ];
                            
                            int textIndex = (_controller.value * loadingTexts.length).floor();
                            textIndex = textIndex.clamp(0, loadingTexts.length - 1);
                            
                            return Column(
                              children: [
                                Text(
                                  loadingTexts[textIndex],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "${(_progressAnimation.value * 100).toInt()}%",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Animated Dots
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      double dot1Opacity = _controller.value > 0.4 ? 1.0 : 0.3;
                      double dot2Opacity = _controller.value > 0.6 ? 1.0 : 0.3;
                      double dot3Opacity = _controller.value > 0.8 ? 1.0 : 0.3;
                      
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[700]!.withOpacity(dot1Opacity),
                              shape: BoxShape.circle,
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[700]!.withOpacity(dot2Opacity),
                              shape: BoxShape.circle,
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[700]!.withOpacity(dot3Opacity),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Version Info
                  AnimatedOpacity(
                    opacity: _controller.value > 0.5 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.security,
                            color: Colors.grey[700],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Secure Admin Access v1.0",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Footer
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _controller.value > 0.7 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: Column(
                  children: [
                    Text(
                      "© 2024 BookStore Management System",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        List<String> footerTexts = [
                          "Loading System Modules...",
                          "Establishing Secure Connection...",
                          "Verifying Admin Credentials...",
                          "Preparing User Interface...",
                          "Finalizing Setup...",
                          "Ready to Launch!"
                        ];
                        
                        int textIndex = (_controller.value * footerTexts.length).floor();
                        textIndex = textIndex.clamp(0, footerTexts.length - 1);
                        
                        return Text(
                          footerTexts[textIndex],
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookPatternPainter extends CustomPainter {
  final double animationValue;

  _BookPatternPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[100]!.withOpacity(0.3 + (animationValue * 0.5))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw animated book patterns
    for (double i = 0; i < size.width; i += 40) {
      for (double j = 0; j < size.height; j += 40) {
        // Animate book appearance based on animation value
        if ((i/40 + j/40) / ((size.width/40) + (size.height/40)) < animationValue) {
          final rect = Rect.fromLTWH(
            i,
            j + (animationValue * 10 * (i % 3).toDouble()),
            20,
            30
          );
          canvas.drawRect(rect, paint);
          
          // Draw book spine
          final spineRect = Rect.fromLTWH(i + 18, j, 2, 30);
          final spinePaint = Paint()
            ..color = Colors.grey[300]!.withOpacity(0.5 + (animationValue * 0.5))
            ..style = PaintingStyle.fill;
          canvas.drawRect(spineRect, spinePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Keep your original MyHomePage class for reference
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 8),
      () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminLoginPage()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.network(
          "https://images.unsplash.com/photo-1511367461989-f85a21fda167?fm=jpg&q=60&w=3000&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8cHJvZmlsZXxlbnwwfHwwfHx8MA%3D%3D",
        ),
      ),
    );
  }
}