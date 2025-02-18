import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';  // For getting location
import 'package:permission_handler/permission_handler.dart';
import 'home_page.dart';
import 'package:online_service_booking/provider/home_page.dart';
import 'dart:math';

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

  String role = "customer"; // Default role selection
  String? selectedServiceCategoryId;
  Position? currentLocation;

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
              : GeoPoint(0.0, 0.0)
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

  // List of icons to choose from
  final List<IconData> iconList = [
    Icons.local_florist,
    Icons.eco,
    Icons.ac_unit,
    Icons.local_florist_sharp,
    //Icons.star,
    //Icons.favorite,
    //Icons.cloud,
  ];


  // Generates a random Positioned icon
  Positioned randomIcon(double screenWidth, double screenHeight) {
    double left = random.nextDouble() * (screenWidth - 50); // Random left within bounds
    double top = random.nextDouble() * (screenHeight - 50); // Random top within bounds
    double size = 20 + random.nextDouble() * 40; // Size between 20 and 60
    IconData icon = iconList[random.nextInt(iconList.length)]; // Random icon

    return Positioned(
      left: left,
      top: top,
      child: Icon(icon, color: Colors.red.shade200, size: size),
    );
  }

  // Generates icons in a structured yet dynamic layout
  // Generates randomly scattered icons across the screen
  List<Widget> generateScatteredIcons(double screenWidth, double screenHeight) {
    List<Widget> iconWidgets = [];
    int iconCount = 12; // Adjusted for a well-spread layout

    for (int i = 0; i < iconCount; i++) {
      double left = random.nextDouble() * screenWidth;
      double top = random.nextDouble() * screenHeight;

      double iconSize = 30 + random.nextDouble() * 60; // Sizes between 30-70
      IconData icon = iconList[random.nextInt(iconList.length)];

      iconWidgets.add(
        Positioned(
          left: left.clamp(0, screenWidth - iconSize),
          top: top.clamp(0, screenHeight - iconSize),
          child: Icon(icon, color: Colors.red.shade200, size: iconSize),
        ),
      );
    }

    return iconWidgets;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    List<Widget> generateIcons() {
      return [
        Positioned(
          top: screenHeight * 0.05,
          left: screenWidth * 0.08,
          child: Icon(Icons.local_florist, color: Colors.red.shade200, size: screenWidth * 0.17),
        ),
        Positioned(
          top: screenHeight * 0.10,
          right: screenWidth * 0.12,
          child: Icon(Icons.eco, color: Colors.red.shade200, size: screenWidth * 0.10),
        ),
        Positioned(
          top: screenHeight * 0.22,
          left: screenWidth * 0.25,
          child: Icon(Icons.eco, color: Colors.red.shade200, size: screenWidth * 0.08),
        ),
        Positioned(
          top: screenHeight * 0.25,
          right: screenWidth * 0.15,
          child: Icon(Icons.local_florist_sharp, color: Colors.red.shade200, size: screenWidth * 0.19),
        ),
        Positioned(
          bottom: screenHeight * 0.12,
          left: screenWidth * 0.35,
          child: Icon(Icons.local_florist, color: Colors.red.shade200, size: screenWidth * 0.20),
        ),
        Positioned(
          bottom: screenHeight * 0.12,
          right: screenWidth * 0.10,
          child: Icon(Icons.eco, color: Colors.red.shade200, size: screenWidth * 0.08),
        ),
        Positioned(
          bottom: screenHeight * 0.25,
          left: screenWidth * 0.05,
          child: Icon(Icons.local_florist, color: Colors.red.shade200, size: screenWidth * 0.07),
        ),
        Positioned(
          bottom: screenHeight * 0.27,
          right: screenWidth * 0.10,
          child: Icon(Icons.local_florist, color: Colors.red.shade200, size: screenWidth * 0.2),
        ),
        Positioned(
          top: screenHeight * 0.40,
          left: screenWidth * 0.50,
          child: Icon(Icons.eco, color: Colors.red.shade200, size: screenWidth * 0.09),
        ),
        Positioned(
          bottom: screenHeight * 0.40,
          left: screenWidth * 0.150,
          child: Icon(Icons.eco, color: Colors.red.shade200, size: screenWidth * 0.25),
        ),
      ];
    }

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
            stops: [0.01, 0.4, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            /*
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
              child: Icon(Icons.local_florist, color: Colors.red.shade200, size: 20 + (30 * 1.5).toDouble()),
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
              child: Icon(Icons.eco, color: Colors.red.shade200, size: 20 + (30 * 1.3).toDouble()),
            ),*/

            // Generate 10 random icons
            //...List.generate(20, (_) => randomIcon(screenWidth, screenHeight,)),
            // Generate a grid of icons
            //...generateScatteredIcons(screenWidth, screenHeight),
            ...generateIcons(),
            Center(
              child: SingleChildScrollView(
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 500),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    // This tween will animate from π (180°) to 0 radians.
                    final flipAnimation = Tween(begin: pi, end: 0.0).animate(animation);
                    return AnimatedBuilder(
                      animation: flipAnimation,
                      child: child,
                      builder: (context, child) {
                        return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001) // This perspective value makes the 3D effect more pronounced.
                            ..rotateY(flipAnimation.value),
                          alignment: Alignment.center,
                          child: child,
                        );
                      },
                    );
                  },
                  child: Container(
                    // The key forces the AnimatedSwitcher to recognize changes between login and signup forms.
                    key: ValueKey<bool>(isLogin),
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

                        // Show Location and Services Offered only for Service Provider
                        if (!isLogin && role == "service_provider")
                          Column(
                            children: [
                              //currentLocation == null
                              //? CircularProgressIndicator()  // Show loading while fetching location
                              //: Text("Location: Latitude ${currentLocation?.latitude}, Longitude ${currentLocation?.longitude}", style: TextStyle(color: Colors.white)),
                              //SizedBox(height: 10),
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
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                    });
                  },
                  child: Text(
                    isLogin ? "Create an account" : "Already have an account? Login",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}