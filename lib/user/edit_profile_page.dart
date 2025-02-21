import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart'; // For reverse geocoding
import 'package:geolocator/geolocator.dart'; // For handling GPS location
import 'package:online_service_booking/theme.dart';
import 'shared_footer.dart';

class EditProfilePage extends StatefulWidget {
  final String customerId;

  EditProfilePage({required this.customerId});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController _nameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _dobController = TextEditingController();

  bool _isLoading = false;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("users").doc(widget.customerId).get();

    if (userDoc.exists) {
      var userData = userDoc.data() as Map<String, dynamic>;

      setState(() {
        _nameController.text = userData['name'] ?? '';
        _phoneController.text = userData['phone'] ?? '';
        _dobController.text = userData['dob'] ?? '';
      });

      if (userData.containsKey('location')) {
        GeoPoint location = userData['location'];
        _getAddressFromLatLng(location.latitude, location.longitude);
      }
    }
  }

  /// Fetch current GPS location and update address
  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _getAddressFromLatLng(position.latitude, position.longitude);

      // Update Firestore with new location
      await FirebaseFirestore.instance.collection("users").doc(widget.customerId).update({
        'location': GeoPoint(position.latitude, position.longitude),
      });

    } catch (e) {
      print("⚠️ Error fetching location: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to fetch location')));
    }

    setState(() {
      _isFetchingLocation = false;
    });
  }

  /// Reverse Geocode: Convert LatLng to Address
  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        String formattedAddress =
            "${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}";

        setState(() {
          _addressController.text = formattedAddress; // Auto-fill address
        });
      }
    } catch (e) {
      print("⚠️ Error fetching address: $e");
    }
  }

  //update User Profile in firestore
  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      await FirebaseFirestore.instance.collection("users").doc(widget.customerId).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'dob': _dobController.text.trim(),
      });

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
      Navigator.pop(context); // Go back to Profile Page
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTheme.gradientAppBar("Edit Profile"),
      body: Stack(
        children: [
          // 🌟 Gradient Background
          Container(
            decoration: AppTheme.gradientBackground,
          ),

          // 🌟 Floating Icons
          ...AppTheme.floatingIcons(context),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: Colors.white),  // 🌟 Text color set to white
                    decoration: InputDecoration(labelText: "Name",
                      labelStyle: TextStyle(color: Colors.white),),
                    validator: (value) => value!.isEmpty ? "Please enter your name" : null,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _phoneController,
                    style: TextStyle(color: Colors.white),  // 🌟 Text color set to white
                    decoration: InputDecoration(labelText: "Phone",
                      labelStyle: TextStyle(color: Colors.white),),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value!.isEmpty ? "Please enter your phone number" : null,
                  ),
                  SizedBox(height: 10),
                  /// Address Field with Refresh Button
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _addressController,
                          style: TextStyle(color: Colors.white),  // 🌟 Text color set to white
                          decoration: InputDecoration(labelText: "Address",
                            labelStyle: TextStyle(color: Colors.white),),
                          readOnly: true,
                        ),
                      ),
                      SizedBox(width: 10),
                      _isFetchingLocation
                          ? CircularProgressIndicator() // Show loading when fetching
                          : IconButton(
                        icon: Icon(Icons.refresh, color: Colors.blue),
                        onPressed: _fetchCurrentLocation,
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _dobController,
                    style: TextStyle(color: Colors.white),  // 🌟 Text color set to white
                    decoration: InputDecoration(
                      labelText: "Date of Birth",
                      hintText: "DD/MM/YYYY",
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    validator: (value) => value!.isEmpty ? "Please enter your DOB" : null,
                  ),
                  SizedBox(height: 20),
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _updateProfile,
                    child: Text("Update Profile", style: TextStyle(color: Colors.black),),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFF8CB20),
                    )
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SharedFooter(customerId: widget.customerId, currentIndex: 1),
    );
  }
}
