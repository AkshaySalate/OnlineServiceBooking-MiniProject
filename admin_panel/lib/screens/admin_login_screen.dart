import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String errorMessage = '';
  bool isNewAdmin = false;

  Future<void> checkAdminExists() async {
    final email = emailController.text.trim();

    final querySnapshot = await FirebaseFirestore.instance
        .collection('admins')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final adminDoc = querySnapshot.docs.first;

      // ✅ Correct condition check
      if (adminDoc.data()['passwordSet'] == true) {
        login(); // 🔥 Directly login if password is already set
      } else {
        setState(() {
          isNewAdmin = true;
        });
      }
    } else {
      setState(() {
        errorMessage = 'Admin account does not exist';
      });
    }
  }

  Future<void> setPassword() async {
    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim().isEmpty
          ? 'qwerty@1234567'  // Default password if empty
          : passwordController.text.trim();

      // ✅ Step 1: Fetch the correct admin document
      final querySnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          errorMessage = "Admin account not found!";
        });
        return;
      }

      final adminDocRef = querySnapshot.docs.first.reference; // ✅ Get the correct document reference

      // ✅ Step 2: Create a new FirebaseAuth user
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ✅ Step 3: Update Firestore after successful authentication
      await adminDocRef.update({'passwordSet': true});

      setState(() {
        isNewAdmin = false; // ✅ Reset state to prevent unnecessary password prompts
      });

      // ✅ Step 4: Automatically log in after setting the password
      login();
    } catch (e) {
      setState(() {
        errorMessage = 'Error setting password: ${e.toString()}';
      });
    }
  }


  Future<void> login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Invalid email or password';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Login")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 10),
            if (errorMessage.isNotEmpty)
              Text(errorMessage, style: TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: isNewAdmin ? setPassword : checkAdminExists,
              child: Text(isNewAdmin ? "Set Password" : "Login"),
            ),
          ],
        ),
      ),
    );
  }
}