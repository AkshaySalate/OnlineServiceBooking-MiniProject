import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:online_service_booking/theme.dart';
import 'shared_footer.dart';
import 'package:online_service_booking/user/map_picker_screen.dart';

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
  bool isFetchingLocation = false;
  double currentLat = 0.0;
  double currentLng = 0.0;

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
        _addressController.text = userData["address"] ?? "No Address Set";

        if (userData.containsKey('location')) {
          GeoPoint location = userData['location'];
          currentLat = location.latitude;
          currentLng = location.longitude;
        }
      });
    }
  }

  /// **Fetch current GPS location and update address**
  void _fetchCurrentLocation() async {
    setState(() {
      isFetchingLocation = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String fullAddress = "${place.name}, ${place.subLocality}, ${place.locality}, "
            "${place.administrativeArea}, ${place.postalCode}, ${place.country}";

        setState(() {
          _addressController.text = fullAddress;
          currentLat = position.latitude;
          currentLng = position.longitude;
          isFetchingLocation = false;
        });

        // ✅ Update Firestore with new location
        await FirebaseFirestore.instance.collection("users").doc(widget.customerId).update({
          "location": GeoPoint(position.latitude, position.longitude),
          "address": fullAddress,
        });
      }
    } catch (e) {
      setState(() {
        isFetchingLocation = false;
      });
      print("⚠️ Error fetching location: $e");
    }
  }

  // **Update User Profile in Firestore**
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
      Navigator.pop(context);
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
                  /// **📌 Name Field**
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Name",
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    validator: (value) => value!.isEmpty ? "Please enter your name" : null,
                  ),
                  SizedBox(height: 10),

                  /// **📌 Phone Field**
                  TextFormField(
                    controller: _phoneController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Phone",
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value!.isEmpty ? "Please enter your phone number" : null,
                  ),
                  SizedBox(height: 10),

                  /// **📌 Address Field with Refresh & Map Button**
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _addressController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Address",
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                          readOnly: true,
                        ),
                      ),
                      SizedBox(width: 8),
                      isFetchingLocation
                          ? CircularProgressIndicator() // Show loading when fetching
                          : IconButton(
                        icon: Icon(Icons.refresh, color: Colors.blue),
                        onPressed: isFetchingLocation ? null : _fetchCurrentLocation,
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Image.network(
                          "https://cdn-icons-png.flaticon.com/512/854/854878.png",
                          width: 24,
                          height: 24,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MapPickerScreen(
                                initialLocation: LatLng(currentLat, currentLng),
                                onLocationSelected: (LatLng selectedLocation, String selectedAddress) {
                                  setState(() {
                                    _addressController.text = selectedAddress;
                                    currentLat = selectedLocation.latitude;
                                    currentLng = selectedLocation.longitude;
                                  });

                                  FirebaseFirestore.instance.collection("users").doc(widget.customerId).update({
                                    "location": GeoPoint(selectedLocation.latitude, selectedLocation.longitude),
                                    "address": selectedAddress,
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 10),

                  /// **📌 Date of Birth Field**
                  TextFormField(
                    controller: _dobController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Date of Birth",
                      hintText: "DD/MM/YYYY",
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    validator: (value) => value!.isEmpty ? "Please enter your DOB" : null,
                  ),

                  SizedBox(height: 20),

                  /// **📌 Update Profile Button**
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _updateProfile,
                    child: Text("Update Profile", style: TextStyle(color: Colors.black)),
                    style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFF8CB20)),
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
