import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:online_service_booking/provider/widgets/shared_footer.dart';
import 'package:online_service_booking/theme.dart';

class ServiceProviderProfile extends StatefulWidget {
  final String providerId;

  ServiceProviderProfile({required this.providerId});

  @override
  _ServiceProviderProfileState createState() => _ServiceProviderProfileState();
}

class _ServiceProviderProfileState extends State<ServiceProviderProfile> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController _businessNameController = TextEditingController();
  //TextEditingController _ownerNameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  bool _isAvailable = false;
  bool _isFetchingLocation = false;
  bool _isUpdating = false;
  String? _selectedAvatar;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  Future<void> _loadAvatars() async {
    QuerySnapshot avatarsSnapshot = await FirebaseFirestore.instance.collection('avatars').get();
    List<String> avatarUrls = avatarsSnapshot.docs.map((doc) => doc['url'] as String).toList();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return GridView.builder(
          padding: EdgeInsets.all(10),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: avatarUrls.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () async {
                setState(() {
                  _selectedAvatar = avatarUrls[index];
                });
                await FirebaseFirestore.instance
                    .collection("service_providers")
                    .doc(widget.providerId)
                    .update({'avatarUrl': _selectedAvatar});
                Navigator.pop(context);
              },
              child: Image.network(avatarUrls[index], fit: BoxFit.cover),
            );
          },
        );
      },
    );
  }

  /// Load Service Provider Data from Firestore
  Future<void> _loadProviderData() async {
    DocumentSnapshot providerDoc = await FirebaseFirestore.instance
        .collection("service_providers")
        .doc(widget.providerId)
        .get();

    if (providerDoc.exists) {
      var providerData = providerDoc.data() as Map<String, dynamic>;

      setState(() {
        _businessNameController.text = providerData['name'] ?? '';
        //_ownerNameController.text = providerData['ownerName'] ?? '';
        _phoneController.text = providerData['phone'] ?? '';
        _isAvailable = providerData['availability'] ?? false;
        _selectedAvatar = providerData['avatarUrl'] ?? null; // Fetching avatar URL
      });

      if (providerData.containsKey('location')) {
        GeoPoint location = providerData['location'];
        _getAddressFromLatLng(location.latitude, location.longitude);
      }
    }
  }

  /// Fetch Current Location and Update Firestore
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
      await FirebaseFirestore.instance
          .collection("service_providers")
          .doc(widget.providerId)
          .update({
        'location': GeoPoint(position.latitude, position.longitude),
      });

    } catch (e) {
      print("⚠️ Error fetching location: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to fetch location')));
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
          _addressController.text = formattedAddress;
        });
      }
    } catch (e) {
      print("⚠️ Error fetching address: $e");
    }
  }

  /// Update Service Provider Profile in Firestore
  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUpdating = true;
      });

      await FirebaseFirestore.instance
          .collection("service_providers")
          .doc(widget.providerId)
          .update({
        'name': _businessNameController.text.trim(),
        //'ownerName': _ownerNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
      });

      setState(() {
        _isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')));
    }
  }

  /// Toggle Availability in Firestore
  Future<void> _toggleAvailability(bool newValue) async {
    setState(() {
      _isAvailable = newValue;
    });

    await FirebaseFirestore.instance
        .collection("service_providers")
        .doc(widget.providerId)
        .update({'availability': newValue});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTheme.gradientAppBar("Profile"),
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
                  /// Profile Avatar Section
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: MediaQuery.of(context).size.width * 0.2,
                          backgroundImage: _selectedAvatar != null
                              ? NetworkImage(_selectedAvatar!)
                              : AssetImage("assets/default_avatar.png") as ImageProvider,
                        ),
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: _loadAvatars,
                            child: Container(
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(2, 2),
                                  )
                                ],
                              ),
                              child: Icon(
                                Icons.edit,
                                color: Colors.black,
                                size: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  //
                  SizedBox(height: 20),
                  /// Business Name
                  TextFormField(
                    controller: _businessNameController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Business Name",
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    validator: (value) =>
                    value!.isEmpty ? "Please enter your business name" : null,
                  ),
                  SizedBox(height: 10),

                  /*/// Owner Name
                  TextFormField(
                    controller: _ownerNameController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Owner Name",
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    validator: (value) =>
                    value!.isEmpty ? "Please enter your name" : null,
                  ),
                  SizedBox(height: 10),*/

                  /// Phone Number
                  TextFormField(
                    controller: _phoneController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Phone",
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                    value!.isEmpty ? "Please enter your phone number" : null,
                  ),
                  SizedBox(height: 10),

                  /// Address Field with Refresh Button
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
                      SizedBox(width: 10),
                      _isFetchingLocation
                          ? CircularProgressIndicator()
                          : IconButton(
                        icon: Icon(Icons.refresh, color: Colors.blue),
                        onPressed: _fetchCurrentLocation,
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  /// Availability Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Availability", style: TextStyle(color: Colors.white, fontSize: 18)),
                      Switch(
                        value: _isAvailable,
                        activeColor: Colors.yellow,
                        inactiveThumbColor: Colors.red,
                        onChanged: (value) => _toggleAvailability(value),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),
                  _isUpdating
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _updateProfile,
                    child: Text("Update Profile",
                        style: TextStyle(color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFF8CB20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar:
      SharedFooter(providerId: widget.providerId, currentIndex: 1),
    );
  }
}
