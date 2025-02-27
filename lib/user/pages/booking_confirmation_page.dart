import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingConfirmationPage extends StatelessWidget {
  final String bookingId;

  BookingConfirmationPage({required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Booking Confirmation")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection("bookings").doc(bookingId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return Center(child: Text("Booking details not found"));

          var bookingData = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Booking ID: ${bookingData['bookingID']}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("Service Category: ${bookingData['serviceCategory']}", style: TextStyle(fontSize: 16)),
                Text("Provider ID: ${bookingData['providerID']}", style: TextStyle(fontSize: 16)),
                Text("Event Date: ${bookingData['eventDate']}", style: TextStyle(fontSize: 16)),
                Text("Status: ${bookingData['status']}", style: TextStyle(fontSize: 16, color: Colors.blue)),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Back to Home"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
