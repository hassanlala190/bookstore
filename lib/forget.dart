import 'dart:async';
import 'package:bookstore/firebase_options.dart';
import 'package:bookstore/login.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_auth/firebase_auth.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
  DevicePreview(
    enabled: !kReleaseMode,
    builder: (context) => forget(), // Wrap your app
  ),
);
}

class forget extends StatelessWidget {
  const forget({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const MyHomePage(title: 'Bookstore'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController email = TextEditingController();

  void show_msg(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void add_user() async {
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      
      //Required
      if (email.text.isEmpty) {
        show_msg("All Fields Are Required");
        return;
      } 
    
    await auth.sendPasswordResetEmail(
      email: email.text);
      show_msg("Password Reset Email has been Send");

    } on FirebaseAuthException catch (e) {
      show_msg("Firebase: " + e.toString());
      print(e.toString());
    } catch (e) {
      show_msg("Error: " + toString());
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
  
    return Scaffold(
      
       body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Forget Password", style: TextStyle(fontSize: 24)),

            Container(
              margin: EdgeInsets.all(10),
              constraints: BoxConstraints(maxWidth: 300),
              child: TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Enter Your Email",
                  suffixIcon: Icon(Icons.email),
                ),
              ),
            ),


            OutlinedButton.icon(
              onPressed: () {
                add_user();
              },
              label: Text("Forget"),
              icon: Icon(Icons.app_registration),
            ),

             Container(
              margin: EdgeInsets.all(10),
              child: TextButton(
                onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (b)=>login()));
                }, child: Text("Back to login",
                style: TextStyle(color: Colors.greenAccent),)),
            ),
          ],
        ),
      ),
    
    );
  }
}
