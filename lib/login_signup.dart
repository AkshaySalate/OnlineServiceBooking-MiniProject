import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';  // For getting location
import 'package:permission_handler/permission_handler.dart';
import 'home_page.dart';
import 'package:online_service_booking/provider/home_page.dart';

class LoginSignupPage extends StatefulWidget {
  @override
  _LoginSignupPageState createState() => _LoginSignupPageState();
}

class _LoginSignupPageState extends State<LoginSignupPage> {
  bool _obscurePassword = true;
  bool isLogin = true;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController servicesController = TextEditingController();  // For service providers

  String role = "customer"; // Default role selection
  Position? currentLocation;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Function to Get Current Location
  Future<void> getCurrentLocation() async {
    try {
      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print("❌ Location permission denied by user.");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print("⚠️ Location permission permanently denied. Go to app settings to enable it.");
        return;
      }

      print("✅ Location permission granted! Fetching location...");

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentLocation = position;
      print("📍 Location obtained: ${position.latitude}, ${position.longitude}");

    } catch (e) {
      print("⚠️ Error fetching location: $e");
      currentLocation = null; // Handle location failure
    }
  }

  // 🔹 Function to Handle Login
  Future<void> login() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      print("User logged in: ${_auth.currentUser!.uid}");

      String userId = userCredential.user!.uid;

      // Try fetching from 'users' collection first
      DocumentSnapshot userDoc = await _firestore.collection("users").doc(userId).get();

      if (userDoc.exists) {
        String userRole = userDoc.get('role');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(customerId: userId)),
        );
      } else {
        // If not found in 'users', check 'service_providers'
        DocumentSnapshot providerDoc = await _firestore.collection("service_providers").doc(userId).get();
        if (providerDoc.exists) {
          String userRole = providerDoc.get('role');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ServiceProviderHomePage(providerId: userId)),
          );
        } else {
          print("Login Error: No matching user found.");
        }
      }
    } catch (e) {
      print("Login Error: $e");
    }
  }


  // 🔹 Function to Handle Sign-Up
  Future<void> signUp() async {
    try {
      if (role == "service_provider") {
        print("Checking location permission before sign-up...");
        await getCurrentLocation();
        if (currentLocation == null) {
          print("⚠️ No location obtained! Defaulting to 0,0.");
        }
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String userId = userCredential.user!.uid;

      if (role == "service_provider") {
        // Store service provider details in `service_providers`
        await _firestore.collection("service_providers").doc(userId).set({
          "name": nameController.text.trim(),
          "email": emailController.text.trim(),
          "phone": phoneController.text.trim(),
          "role": role,
          "location": currentLocation != null
              ? GeoPoint(currentLocation!.latitude, currentLocation!.longitude)
              : GeoPoint(0.0, 0.0),
          "services_offered": servicesController.text.trim().split(","),
        });
      } else {
        // Store customer details in `users`
        await _firestore.collection("users").doc(userId).set({
          "name": nameController.text.trim(),
          "email": emailController.text.trim(),
          "phone": phoneController.text.trim(),
          "role": role, // Ensures role is stored
          "location": currentLocation != null
              ? GeoPoint(currentLocation!.latitude, currentLocation!.longitude)
              : GeoPoint(0.0, 0.0)
        });
      }

      print("✅ User signed up successfully: $userId");

    } catch (e) {
      print("❌ Sign-up Error: $e");
    }
  }




  @override
  void initState() {
    super.initState();
    if (role == "service_provider") {
      // Get current location when user chooses service provider
      getCurrentLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.5,
            colors: [
              Colors.red.shade300,
              Colors.red.shade500,
              Colors.red.shade700,
              Colors.red.shade900,
            ],
            stops: [0.1, 0.4, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Randomly positioned icons with different sizes
            Positioned(
              top: 50,
              left: 30,
              child: Icon(Icons.local_florist, color: Colors.red.shade200, size: 20 + (30 * 1).toDouble()),
            ),
            Positioned(
              top: 150,
              right: 30,
              child: Icon(Icons.eco, color: Colors.red.shade200, size: 20 + (30 * 2).toDouble()),
            ),
            Positioned(
              bottom: 100,
              left: 80,
              child: Icon(Icons.ac_unit, color: Colors.red.shade200, size: 20 + (30 * 1.5).toDouble()),
            ),
            Positioned(
              bottom: 180,
              right: 80,
              child: Icon(Icons.eco, color: Colors.red.shade200, size: 20 + (30 * 0.8).toDouble()),
            ),
            Positioned(
              top: 100,
              left: 150,
              child: Icon(Icons.local_florist, color: Colors.red.shade200, size: 20 + (30 * 1.2).toDouble()),
            ),
            Positioned(
              top: 200,
              left: 200,
              child: Icon(Icons.eco, color: Colors.red.shade200, size: 20 + (30 * 1.5).toDouble()),
            ),
            Positioned(
              bottom: 50,
              right: 150,
              child: Icon(Icons.local_florist, color: Colors.red.shade200, size: 20 + (30 * 1.1).toDouble()),
            ),
            Positioned(
              top: 250,
              left: 250,
              child: Icon(Icons.eco, color: Colors.red.shade200, size: 20 + (30 * 0.9).toDouble()),
            ),
            Positioned(
              bottom: 250,
              right: 250,
              child: Icon(Icons.ac_unit, color: Colors.red.shade200, size: 20 + (30 * 1.3).toDouble()),
            ),
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white, // Container background color
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(isLogin ? "Login" : "Sign Up", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          SizedBox(height: 20),

                          // Show Name & Phone field only for Sign-Up
                          if (!isLogin)
                            Column(
                              children: [
                                TextField(controller: nameController, decoration: InputDecoration(labelText: "Full Name")),
                                TextField(controller: phoneController, decoration: InputDecoration(labelText: "Phone")),
                              ],
                            ),

                          TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
                          TextField(
                            controller: passwordController,
                            decoration: InputDecoration(
                              labelText: "Password",
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
                          ),

                          // Show Role Selection for Sign-Up
                          if (!isLogin)
                            DropdownButton<String>(
                              value: role,
                              items: ["customer", "service_provider"].map((role) {
                                return DropdownMenuItem(value: role, child: Text(role));
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  role = value!;
                                });
                              },
                            ),

                          // Show Location and Services Offered only for Service Provider
                          if (role == "service_provider")
                            Column(
                              children: [
                                currentLocation == null
                                    ? CircularProgressIndicator()  // Show loading while fetching location
                                    : Text("Location: Latitude ${currentLocation?.latitude}, Longitude ${currentLocation?.longitude}"),
                                TextField(
                                  controller: servicesController,
                                  decoration: InputDecoration(labelText: "Services Offered (comma separated)"),
                                ),
                              ],
                            ),

                          SizedBox(height: 20),

                          ElevatedButton(
                            onPressed: () {
                              isLogin ? login() : signUp();
                            },
                            child: Text(isLogin ? "Login" : "Sign Up"),
                          ),

                          TextButton(
                            onPressed: () {
                              setState(() {
                                isLogin = !isLogin;
                              });
                            },
                            child: Text(isLogin ? "Create an account" : "Already have an account? Login"),
                          ),
                        ],
                      ),
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