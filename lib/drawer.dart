import 'dart:async';
import 'package:bookstore/firebase_options.dart';
import 'package:bookstore/library.dart';
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
    builder: (context) => drawer(), // Wrap your app
  ),
);
}

class drawer extends StatelessWidget {
  const drawer({super.key});

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
 
  @override
  Widget build(BuildContext context) {
  User? user = FirebaseAuth.instance.currentUser;  
    return Scaffold(
       drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
            currentAccountPicture: CircleAvatar(
              backgroundImage: NetworkImage("https://images.unsplash.com/photo-1511367461989-f85a21fda167?fm=jpg&q=60&w=3000&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8cHJvZmlsZXxlbnwwfHwwfHx8MA%3D%3D"),
            ),
            accountName: Text(""),
            accountEmail: Text("${user!.email}")),

            ListTile(
              leading: Icon(Icons.add),
              title: Text("Add Product"),
              onTap: (){
                Navigator.push(context,MaterialPageRoute(builder: (a)=>lib()));
              },
            ),
            ListTile(
              leading: Icon(Icons.show_chart),
              title: Text("Show Product"),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: user == null ? Text("Login"): Text("Logout"),
              onTap: () async{
                await FirebaseAuth.instance.signOut();
                Navigator.push(context, MaterialPageRoute(builder: (builder)=> login()));
              },
            )
          ],
        ),
      ),
      
    );
  }
}
