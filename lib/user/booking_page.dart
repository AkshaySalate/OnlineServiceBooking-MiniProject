import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:online_service_booking/user/shared_footer.dart';

class BookingPage extends StatefulWidget {
  final String customerId;
  BookingPage({required this.customerId});
  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> userBookings = [];

  @override
  void initState() {
    super.initState();
    _fetchUserBookings();
  }

  /// **Fetch all bookings for the current user**
  Future<void> _fetchUserBookings() async {
    try {
      print("🔄 Fetching bookings for customerID: ${widget.customerId}");
      QuerySnapshot bookingSnapshot = await FirebaseFirestore.instance
          .collection("bookings")
          .where("customerID", isEqualTo: widget.customerId)
          .get();

      print("✅ Found ${bookingSnapshot.docs.length} bookings in Firestore");
      print("🔄 Processing bookings...");

      List<Map<String, dynamic>> fetchedBookings = bookingSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      fetchedBookings.sort((a, b) => b["eventDate"].compareTo(a["eventDate"])); // Sort manually

      for (var doc in bookingSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        // Convert eventDate from Timestamp to String
        String eventDateFormatted = "";
        if (data["eventDate"] is Timestamp) {
          eventDateFormatted = (data["eventDate"] as Timestamp).toDate().toString();
        } else {
          eventDateFormatted = data["eventDate"].toString();
        }

        // Fetch service provider details
        DocumentSnapshot providerDoc = await FirebaseFirestore.instance
            .collection("service_providers")
            .doc(data["providerID"])
            .get();

        if (providerDoc.exists) {
          var providerData = providerDoc.data() as Map<String, dynamic>;

          fetchedBookings.add({
            "id": doc.id, // Booking ID
            "serviceName": data["serviceCategory"], // Service booked
            "eventDate": data["eventDate"], // Booking date
            "status": data["status"], // Booking status
            "providerName": providerData["name"], // Provider's name
            "providerAddress": providerData["address"], // Provider's address
          });
          print("✅ Added booking: ${data["serviceCategory"]} by ${providerData["name"]}");
        }
      }

      setState(() {
        userBookings = fetchedBookings;
        _isLoading = false;
      });
      print("🎉 Total Bookings Displayed: ${userBookings.length}");
    } catch (e) {
      print("⚠️ Error fetching bookings: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Bookings")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : userBookings.isEmpty
          ? Center(child: Text("No bookings found."))
          : ListView.builder(
        itemCount: userBookings.length,
        itemBuilder: (context, index) {
          var booking = userBookings[index];
          return Card(
            margin: EdgeInsets.all(10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("📌 ${booking['serviceName']}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text("👤 Provider: ${booking['providerName']}", style: TextStyle(fontSize: 16)),
                  Text("📍 Address: ${booking['providerAddress']}", style: TextStyle(fontSize: 14)),
                  Text("📅 Date: ${booking['eventDate']}", style: TextStyle(fontSize: 14)),
                  Text("🟢 Status: ${booking['status']}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _getStatusColor(booking['status']))),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SharedFooter(customerId: widget.customerId, currentIndex: 2),
    );
  }

  /// **Color coding for booking status**
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;
      case "confirmed":
        return Colors.green;
      case "completed":
        return Colors.blue;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
