import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'shared_footer.dart';

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
        .listen((snapshot) {
      setState(() {
        bookings = snapshot.docs.map((doc) {
          var data = doc.data();
          data['id'] = doc.id; // Store document ID
          return data;
        }).toList();
        _isLoading = false;
      });
    });
  }

  /// **📌 Update Booking Status (Accept / Complete)**
  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection("bookings")
        .doc(bookingId)
        .update({"status": newStatus});
  }

  /// **📌 Booking Card Widget**
  Widget _buildBookingCard(Map<String, dynamic> booking) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text("Service: ${booking['serviceCategory']}",
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Date: ${booking['eventDate']}\nStatus: ${booking['status']}"),
        trailing: booking['status'] == "pending"
            ? ElevatedButton(
          onPressed: () => _updateBookingStatus(booking['id'], "Upcoming"),
          child: Text("Accept"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        )
            : (booking['status'] == "Upcoming"
            ? ElevatedButton(
          onPressed: () => _updateBookingStatus(booking['id'], "Completed"),
          child: Text("Complete"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        )
            : Icon(Icons.check_circle, color: Colors.grey)),
      ),
    );
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
