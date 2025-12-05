import 'dart:async';
import 'package:bookstore/dashboard.dart';
import 'package:bookstore/firebase_options.dart';
import 'package:bookstore/forget.dart';
import 'package:bookstore/register.dart';
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
    builder: (context) => login(), // Wrap your app
  ),
);
}

class login extends StatelessWidget {
  const login({super.key});

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
  TextEditingController pswd = TextEditingController();

  void show_msg(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void add_user() async {
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      final email_regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',);

      //Required
      if (email.text.isEmpty || pswd.text.isEmpty) {
        show_msg("All Fields Are Required");
        return;
      }

      //Regular Expression
      if (!email_regex.hasMatch(email.text)) {
        show_msg("Email is invalid");
        return;
      }

      //Authentication
      UserCredential userdata = await auth.signInWithEmailAndPassword(
        email: email.text,
        password: pswd.text,
      );
      if(!userdata.user!.emailVerified){
        await auth.signOut();
        show_msg("Very Email First");
        return;
      }
      else{
        show_msg("Login Successfully");
        Navigator.push(context, MaterialPageRoute(builder: (a)=>dash()));
      }

      // Email Sent
      await userdata.user?.sendEmailVerification();
      show_msg(
        "User Registered Successfully, Verification email has been sent",
      );

      //fields empty
      email.text = "";
      pswd.text = "";
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
            Text("Login Yourself", style: TextStyle(fontSize: 24)),

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

            Container(
              margin: EdgeInsets.all(10),
              constraints: BoxConstraints(maxWidth: 300),
              child: TextField(
                controller: pswd,
                obscureText: true,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Enter Your Password",
                  suffixIcon: Icon(Icons.password),
                ),
              ),
            ),

            OutlinedButton.icon(
              onPressed: () {
                add_user();
              },
              label: Text("Login"),
              icon: Icon(Icons.app_registration),
            ),

             Container(
              margin: EdgeInsets.all(10),
              child: TextButton(
                onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (b)=>register()));
                }, child: Text("Don't have an account",
                style: TextStyle(color: Colors.greenAccent),)),
            ),

            Container(
              child: TextButton(
                onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (b)=>forget()));
                }, child: Text("Forget Password",
                style: TextStyle(color: Colors.red),)),
            ),
          ],
        ),
      ),
    
    );
  }
}
