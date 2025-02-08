import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceProviderHomePage extends StatefulWidget {
  final String providerId;

  ServiceProviderHomePage({required this.providerId});

  @override
  _ServiceProviderHomePageState createState() => _ServiceProviderHomePageState();
}

class _ServiceProviderHomePageState extends State<ServiceProviderHomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController servicesController = TextEditingController();

  double latitude = 0.0;
  double longitude = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchServiceProviderDetails();
  }

  Future<void> fetchServiceProviderDetails() async {
    try {
      DocumentSnapshot doc = await _firestore.collection("service_providers").doc(widget.providerId).get();
      if (doc.exists) {
        setState(() {
          nameController.text = doc["name"];
          emailController.text = doc["email"];
          phoneController.text = doc["phone"];
          servicesController.text = (doc["services_offered"] as List).join(", ");
          latitude = doc["location"].latitude;
          longitude = doc["location"].longitude;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching provider details: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> updateServiceProviderDetails() async {
    try {
      List<String> updatedServices = servicesController.text.split(',').map((s) => s.trim()).toList();

      await _firestore.collection("service_providers").doc(widget.providerId).update({
        "name": nameController.text,
        "email": emailController.text,
        "phone": phoneController.text,
        "services_offered": updatedServices,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profile updated successfully!")));
    } catch (e) {
      print("Error updating provider details: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update profile.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Service Provider Home")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Edit Your Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            // Name Field
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
            SizedBox(height: 10),

            // Email Field
            TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
            SizedBox(height: 10),

            // Phone Field
            TextField(controller: phoneController, decoration: InputDecoration(labelText: "Phone")),
            SizedBox(height: 10),

            // Services Offered Field
            TextField(controller: servicesController, decoration: InputDecoration(labelText: "Services Offered (comma separated)")),
            SizedBox(height: 10),

            // Location
            Text("Location: ($latitude, $longitude)", style: TextStyle(fontSize: 16)),

            SizedBox(height: 20),

            // Save Button
            ElevatedButton(
              onPressed: updateServiceProviderDetails,
              child: Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}
