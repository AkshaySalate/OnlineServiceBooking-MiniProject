import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'shared_footer.dart';
import 'package:online_service_booking/chat_screen.dart';
import 'package:geocoding/geocoding.dart';

class ProviderBookingsPage extends StatefulWidget {
  final String providerId;
  ProviderBookingsPage({required this.providerId});

  @override
  _ProviderBookingsPageState createState() => _ProviderBookingsPageState();
}

class _ProviderBookingsPageState extends State<ProviderBookingsPage> {
  List<Map<String, dynamic>> bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _listenToBookings();
  }

  /// **📌 Real-time Booking Updates**
  void _listenToBookings() {
    FirebaseFirestore.instance
        .collection("bookings")
        .where("providerID", isEqualTo: widget.providerId)
        .snapshots()
        .listen((snapshot) async {
      List<Map<String, dynamic>> updatedBookings = [];

      for (var doc in snapshot.docs) {
        var data = doc.data();
        data['id'] = doc.id; // Store document ID

        // Fetch Customer Details (Name & Location)
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(data["customerID"])
            .get();

        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>;
          data["customerName"] = userData["name"] ?? "Unknown User";

          // ✅ Fetch Customer's Location
          if (userData.containsKey("location")) {
            GeoPoint customerLocation = userData["location"];
            data["customerAddress"] = await _getAddressFromLatLng(
                customerLocation.latitude, customerLocation.longitude);
          } else {
            data["customerAddress"] = "Address not available";
          }
        } else {
          data["customerName"] = "Unknown User";
          data["customerAddress"] = "Address not available";
        }

        // Fetch Service Details using the document ID from the booking's serviceCategory field
        DocumentSnapshot serviceDoc = await FirebaseFirestore.instance
            .collection("services")
            .doc(data["serviceCategory"]) // booking.serviceCategory should match the service document ID
            .get();

        if (serviceDoc.exists) {
          var serviceData = serviceDoc.data() as Map<String, dynamic>;
          // Extract the serviceCategory field from the services document as the service type.
          data["serviceType"] = serviceData["serviceCategory"] ?? "Unknown Service";
        } else {
          data["serviceType"] = "Unknown Service";
        }

        updatedBookings.add(data);
      }

      setState(() {
        bookings = updatedBookings;
        _isLoading = false;
      });
    });
  }

  /// **📌 Convert LatLng to Address**
  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return "${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      }
    } catch (e) {
      print("⚠️ Error fetching address: $e");
    }
    return "Unknown Location";
  }

  /// **📌 Update Booking Status (Accept / Complete)**
  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection("bookings")
        .doc(bookingId)
        .update({"status": newStatus});
  }

  /// **📌 Navigate to Chat Screen**
  void _openChat(String customerId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          providerId: widget.providerId,
          customerId: customerId,
        ),
      ),
    );
  }

  /// **📌 Booking Card Widget**
  /// **📌 Booking Card Widget**
  Widget _buildBookingCard(Map<String, dynamic> booking) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display Service Type fetched from services collection
            Text("📌 Service Type: ${booking['serviceType']}",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 5),
            Text("👤 Customer: ${booking['customerName']}"),
            Text("📍 Address: ${booking['customerAddress']}"),
            Text("📅 Date: ${booking['eventDate']}"),
            Text("🟢 Status: ${booking['status']}",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(booking['status']))),
            SizedBox(height: 10),

            // Accept & Complete Buttons
            booking['status'] == "pending"
                ? ElevatedButton(
              onPressed: () => _updateBookingStatus(booking['id'], "Upcoming"),
              child: Text("Accept"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            )
                : (booking['status'] == "Upcoming"
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () =>
                      _updateBookingStatus(booking['id'], "Completed"),
                  child: Text("Complete"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange),
                ),
                SizedBox(height: 10), // Space between buttons
                ElevatedButton(
                  onPressed: () => _openChat(booking['customerID']),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat, color: Colors.white),
                      SizedBox(width: 8),
                      Text("Chat with Customer"),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue),
                ),
              ],
            )
                : Icon(Icons.check_circle, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  /// **📌 Color Coding for Status**
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;
      case "upcoming":
        return Colors.blue;
      case "completed":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Bookings")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(bookings[index]);
        },
      ),
      bottomNavigationBar: SharedFooter(providerId: widget.providerId, currentIndex: 2,),
    );
  }
}
