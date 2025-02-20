import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';  // For getting location
import 'package:permission_handler/permission_handler.dart';
import 'user/home_page.dart';
import 'package:online_service_booking/provider/home_page.dart';
import 'dart:math';
import 'theme.dart';

class LoginSignupPage extends StatefulWidget {
  @override
  _LoginSignupPageState createState() => _LoginSignupPageState();
}

class _LoginSignupPageState extends State<LoginSignupPage> {
  final Random random = Random();
  bool _obscurePassword = true;
  bool isLogin = true;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController servicesController = TextEditingController();  // For service providers
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController dobController = TextEditingController();

  String role = "customer"; // Default role selection
  String? selectedServiceCategoryId;
  Position? currentLocation;
  String? gender;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //Variables to hold msgs
  String successMessage = "";
  String errorMessage = "";

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
        setState(() {
          successMessage = "✅ Login successful! Welcome back.";
          errorMessage = "";
        });
        // Clear success message after 3 seconds
        Future.delayed(Duration(seconds: 3), () {
          setState(() {
            successMessage = "";
          });
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(customerId: userId)),
        );
      } else {
        // If not found in 'users', check 'service_providers'
        DocumentSnapshot providerDoc = await _firestore.collection("service_providers").doc(userId).get();
        if (providerDoc.exists) {
          String userRole = providerDoc.get('role');
          setState(() {
            successMessage = "✅ Login successful! Welcome back.";
            errorMessage = "";
          });
          // Clear success message after 3 seconds
          Future.delayed(Duration(seconds: 3), () {
            setState(() {
              successMessage = "";
            });
          });
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ServiceProviderHomePage(providerId: userId)),
          );
        } else {
          setState(() {
            errorMessage = "❌ No matching user found.";
            successMessage = "";
          });
          // Clear error message after 3 seconds
          Future.delayed(Duration(seconds: 3), () {
            setState(() {
              errorMessage = "";
            });
          });
          print("Login Error: No matching user found.");
        }
      }
    }  on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          errorMessage = "❌ No user found for that email.";
        } else if (e.code == 'wrong-password') {
          errorMessage = "❌ Wrong password provided.";
        } else {
          errorMessage = "❌ Login failed: ${e.message}";
        }
        successMessage = "";
      });
      // Clear error message after 3 seconds
      Future.delayed(Duration(seconds: 3), () {
        setState(() {
          errorMessage = "";
        });
      });
      print("Login Error: ${e.message}");
    } catch (e) {
      setState(() {
        errorMessage = "❌ Login failed: $e";
        successMessage = "";
      });
      // Clear error message after 3 seconds
      Future.delayed(Duration(seconds: 3), () {
        setState(() {
          errorMessage = "";
        });
      });
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
      if (role == "customer") {
        print("Checking location permission before sign-up...");
        await getCurrentLocation();
        if (currentLocation == null) {
          print("⚠️ No location obtained! Defaulting to 0,0.");
        }
      }
      //attempt to create user
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String userId = userCredential.user!.uid;

      if (role == "service_provider") {
        // Ensure a service category is selected
        if (selectedServiceCategoryId == null) {
          print("❌ Please select a service category.");
          setState(() {
            errorMessage = "❌ Please select a service category.";
          });
          // Clear the message after 3 seconds
          Future.delayed(Duration(seconds: 3), () {
            setState(() {
              successMessage = "";
            });
          });
          return;
        }
        // Store service provider details in `service_providers`
        await _firestore.collection("service_providers").doc(userId).set({
          "name": nameController.text.trim(),
          "email": emailController.text.trim(),
          "phone": phoneController.text.trim(),
          "role": role,
          "location": currentLocation != null
              ? GeoPoint(currentLocation!.latitude, currentLocation!.longitude)
              : GeoPoint(0.0, 0.0),
          // Save the selected service category id instead of a comma-separated list
          "serviceCategory": selectedServiceCategoryId,
          "availability": true,
          "experience": int.tryParse(experienceController.text.trim()) ?? 0, // Experience in years
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
              : GeoPoint(0.0, 0.0),
          "dob": role == "customer" ? dobController.text : null,
          "iconUrl": "https://cdn-icons-png.flaticon.com/512/7880/7880189.png",
          "gender": role == "customer" && gender != null ? gender : "Not specified",
        });
      }

      print("✅ User signed up successfully: $userId");
      setState(() {
        successMessage = "✅ Sign-up successful! Welcome to the platform.";
        errorMessage = ""; // Clear error message
      });
      // Clear the message after 3 seconds
      Future.delayed(Duration(seconds: 3), () {
        setState(() {
          successMessage = "";
        });
      });

    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') {
          errorMessage = "❌ This email is already registered. Try logging in.";
        } else if (e.code == 'weak-password') {
          errorMessage = "❌ Password must be at least 6 characters.";
        } else if (e.code == 'invalid-email') {
          errorMessage = "❌ Please enter a valid email address.";
        } else if (e.code == 'network-request-failed') {
          errorMessage = "❌ Network error. Please check your connection.";
        } else {
          errorMessage = "❌ Sign-up failed: ${e.message}";
        }
        successMessage = ""; // Clear success message
      });
      // Clear error message after 3 seconds
      Future.delayed(Duration(seconds: 3), () {
        setState(() {
          errorMessage = "";
        });
      });
    }catch (e) {
      setState(() {
        errorMessage = "❌ An unexpected error occurred: $e";
        successMessage = ""; // Clear success message
      });
      Future.delayed(Duration(seconds: 3), () {
        setState(() {
          errorMessage = "";
        });
      });
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
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
                      constraints: BoxConstraints(maxWidth: 400), // Ensures it's not too wide on larger screens
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300.withOpacity(0.2), // Container background color
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 0.5), // Soft white border
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 3,
                            offset: Offset(3, 3), // 3D depth effect
                          ),
                        ],
                      ),

                      child: Column(
                        children: [
                          Text(isLogin ? "Login" : "Sign Up", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(height: 20),

                          // Show Name & Phone field only for Sign-Up
                          if (!isLogin)
                            Column(
                              children: [
                                TextField(
                                  controller: nameController,
                                  decoration: InputDecoration(labelText: "Business Name", labelStyle: TextStyle(color: Colors.white)),
                                  style: TextStyle(color: Colors.white),
                                ),
                                TextField(
                                  controller: phoneController,
                                  decoration: InputDecoration(labelText: "Phone", labelStyle: TextStyle(color: Colors.white)),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),

                          TextField(
                            controller: emailController,
                            decoration: InputDecoration(labelText: "Email", labelStyle: TextStyle(color: Colors.white)),
                            style: TextStyle(color: Colors.white),
                          ),
                          TextField(
                            controller: passwordController,
                            decoration: InputDecoration(
                              labelText: "Password",
                              labelStyle: TextStyle(color: Colors.white),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
                            style: TextStyle(color: Colors.white),
                          ),

                          // Show Role Selection for Sign-Up
                          if (!isLogin)
                            DropdownButton<String>(
                              value: role,
                              items: ["customer", "service_provider"].map((role) {
                                return DropdownMenuItem(value: role, child: Text(role, style: TextStyle(color: Colors.white)));
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  role = value!;
                                  // Reset the selected service category if role changes.
                                  if (role != "service_provider") {
                                    selectedServiceCategoryId = null;
                                  } else {
                                    // Optionally, fetch location when service provider is chosen.
                                    getCurrentLocation();
                                  }
                                });
                              },
                              dropdownColor: Colors.grey.shade800,
                            ),

                          if (!isLogin && role == "customer")
                            Column(
                              children: [
                                SizedBox(height: 10),
                                DropdownButton<String>(
                                  value: gender, // Ensure gender is set correctly
                                  hint: Text("Select Gender", style: TextStyle(color: Colors.white)),
                                  items: [
                                    DropdownMenuItem(value: "Male", child: Text("Male", style: TextStyle(color: Colors.white))),
                                    DropdownMenuItem(value: "Female", child: Text("Female", style: TextStyle(color: Colors.white))),
                                  ],
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      gender = newValue; // Update gender selection
                                    });
                                  },
                                  dropdownColor: Colors.grey.shade800,
                                ),
                                SizedBox(height: 10),
                                TextField(
                                  controller: dobController,
                                  readOnly: true,
                                  onTap: () async {
                                    DateTime? pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(1900),
                                      lastDate: DateTime.now(),
                                    );
                                    if (pickedDate != null) {
                                      setState(() {
                                        dobController.text = "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
                                      });
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText: "Date of Birth",
                                    labelStyle: TextStyle(color: Colors.white),
                                    suffixIcon: Icon(Icons.calendar_today, color: Colors.white),
                                  ),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),

                          // Show Location and Services Offered only for Service Provider
                          if (!isLogin && role == "service_provider")
                              Column(
                              children: [
                                //currentLocation == null
                                    //? CircularProgressIndicator()  // Show loading while fetching location
                                    //: Text("Location: Latitude ${currentLocation?.latitude}, Longitude ${currentLocation?.longitude}", style: TextStyle(color: Colors.white)),
                                SizedBox(height: 10),
                                // Service Category dropdown fetched from Firestore
                                FutureBuilder<QuerySnapshot>(
                                  future: _firestore.collection("services").get(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return CircularProgressIndicator();
                                    }
                                    if (snapshot.hasError) {
                                      return Text("Error: ${snapshot.error}", style: TextStyle(color: Colors.white));
                                    }
                                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                      return Text("No service categories available", style: TextStyle(color: Colors.white));
                                    }
                                    List<DropdownMenuItem<String>> categoryItems = snapshot.data!.docs.map((doc) {
                                      // Assuming each document has a field "name" for display purposes.
                                      String categoryName = doc.data().toString().contains("serviceCategory")
                                          ? doc.get("serviceCategory")
                                          : doc.id;
                                      return DropdownMenuItem<String>(
                                        value: doc.id,
                                        child: Text(categoryName, style: TextStyle(color: Colors.white)),
                                      );
                                    }).toList();

                                    return DropdownButton<String>(
                                      value: selectedServiceCategoryId,
                                      hint: Text("Select Service", style: TextStyle(color: Colors.white)),
                                      items: categoryItems,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedServiceCategoryId = value;
                                        });
                                      },
                                      dropdownColor: Colors.grey.shade800,
                                    );
                                  },
                                ),
                                SizedBox(height: 20),
                                // Experience field (asking in years as a number)
                                TextField(
                                  controller: experienceController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: "Experience (years)",
                                    labelStyle: TextStyle(color: Colors.white),
                                  ),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              isLogin ? login() : signUp();
                            },
                            child: Text(
                              isLogin ? "Login" : "Sign Up",
                              style: TextStyle(color: Colors.black), // Text color set to white
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFF8CB20),
                              minimumSize: Size(MediaQuery.of(context).size.width * 0.6, 45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20), // Reduced corner radius
                              ),
                            ),
                          ),

                          SizedBox(height: 10),  // Added spacing for better visual appearance
                          // Display error message if any
                          if (errorMessage.isNotEmpty)
                            Text(
                              errorMessage,
                              style: TextStyle(color: Colors.red, fontSize: 16),
                            ),

                          // Display success message if any
                          if (successMessage.isNotEmpty)
                            Text(
                              successMessage,
                              style: TextStyle(color: Colors.green, fontSize: 16),
                            ),
                        ],
                      ),
                    ),
                    // "Create an account" / "Already have an account?" button outside of the container
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isLogin = !isLogin;
                        });
                      },
                      child: Text(
                        isLogin ? "Create an account" : "Already have an account? Login",
                        style: TextStyle(color: Colors.white),
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