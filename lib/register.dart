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
    builder: (context) => register(), // Wrap your app
  ),
);
}

class register extends StatelessWidget {
  const register({super.key});

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
TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController pswd = TextEditingController();
  TextEditingController cpswd = TextEditingController();
  TextEditingController contact = TextEditingController();
  TextEditingController address = TextEditingController();

  void show_msg(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void add_user() async {
    try {
      FirebaseFirestore db = FirebaseFirestore.instance;
      FirebaseAuth auth = FirebaseAuth.instance;
      final name_regex = RegExp(r'^[a-zA-Z0-9_]{3,16}$');
      final contact_regex = RegExp(r'^[0-9]{11}$');
      final email_regex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      final pswd_regex = RegExp(
        r'^[a-zA-Z0-9_]{4,16}$',
      );

      //Required
      if (name.text.isEmpty ||
          email.text.isEmpty ||
          pswd.text.isEmpty ||
          cpswd.text.isEmpty ||
          contact.text.isEmpty ||
          address.text.isEmpty) {
        show_msg("All Fields Are Required");
        return;
      }
      //Confirm password or password match
      if (pswd.text != cpswd.text) {
        show_msg("Password Does not match");
        return;
      }
      //Regular Expression
      if (!name_regex.hasMatch(name.text)) {
        show_msg("Name is invalid");
        return;
      }
      if (!email_regex.hasMatch(email.text)) {
        show_msg("Email is invalid");
        return;
      }
      if (!contact_regex.hasMatch(contact.text)) {
        show_msg("Contact is invalid");
        return;
      }
      if (!pswd_regex.hasMatch(pswd.text)) {
        show_msg("Password is invalid");
        return;
      }

      //Authentication
      UserCredential userdata = await auth.createUserWithEmailAndPassword(
        email: email.text,
        password: pswd.text,
      );

      //Collection
      await db.collection("UserEntry").add({
        "name": name.text,
        "email": email.text,
        "address": address.text,
        "contact": int.parse(contact.text),
        "create_at": DateTime.now(),
      });

      // Email Sent
      await userdata.user?.sendEmailVerification();
      show_msg(
        "User Registered Successfully, Verification email has been sent",
      );

      //fields empty
      name.text = "";
      email.text = "";
      pswd.text = "";
      cpswd.text = "";
      address.text = "";
      contact.text = "";
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
            Text("Register Yourself", style: TextStyle(fontSize: 24)),
            Container(
              margin: EdgeInsets.all(10),
              constraints: BoxConstraints(maxWidth: 300),
              child: TextField(
                controller: name,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Enter Your Name",
                  suffixIcon: Icon(Icons.person),
                ),
              ),
            ),

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
            Container(
              margin: EdgeInsets.all(10),

              constraints: BoxConstraints(maxWidth: 300),
              child: TextField(
                controller: cpswd,
                obscureText: true,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Confirm Your Password",
                  suffixIcon: Icon(Icons.password),
                ),
              ),
            ),

            Container(
              margin: EdgeInsets.all(10),
              constraints: BoxConstraints(maxWidth: 300),
              child: TextField(
                controller: contact,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Enter Your Contact",
                  suffixIcon: Icon(Icons.phone),
                ),
              ),
            ),

            Container(
              margin: EdgeInsets.all(10),
              constraints: BoxConstraints(maxWidth: 300),
              child: TextField(
                controller: address,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Enter Your Address",
                  suffixIcon: Icon(Icons.home),
                ),
              ),
            ),

            OutlinedButton.icon(
              onPressed: () {
                add_user();
              },
              label: Text("Signup"),
              icon: Icon(Icons.app_registration),
            ),

            Container(
              margin: EdgeInsets.all(10),
              child: TextButton(
                onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (b)=>login()));
                }, child: Text("Have an account",
                style: TextStyle(color: Colors.greenAccent),)),
            ),
          ],
        ),
      ),
    
    );
  }
}
