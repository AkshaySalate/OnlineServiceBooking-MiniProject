import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'package:online_service_booking/theme.dart';
import 'package:online_service_booking/user/pages/home_page.dart';

class BookingConfirmationPage extends StatelessWidget {
  final String bookingId;

  BookingConfirmationPage({required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTheme.gradientAppBar("Booking Confirmation"),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection("bookings").doc(bookingId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                child: Text("Booking details not found", style: AppTheme.cardDescriptionTextStyle()),
              );
            }

            var bookingData = snapshot.data!.data() as Map<String, dynamic>;
            String serviceCategoryId = bookingData['serviceCategory'];
            String providerId = bookingData['providerID'];
            String customerId = bookingData['customerID'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection("services").doc(serviceCategoryId).get(),
              builder: (context, serviceSnapshot) {
                String serviceName = "Loading...";
                if (serviceSnapshot.hasData && serviceSnapshot.data!.exists) {
                  serviceName = serviceSnapshot.data!["serviceCategory"] ?? "Unknown Service";
                }

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection("service_providers").doc(providerId).get(),
                  builder: (context, providerSnapshot) {
                    String providerName = "Loading...";
                    if (providerSnapshot.hasData && providerSnapshot.data!.exists) {
                      providerName = providerSnapshot.data!["name"] ?? "Unknown Provider";
                    }

                    return Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.receipt_long, color: Colors.white, size: 30),
                                        SizedBox(width: 10),
                                        Text("Booking Details", style: AppTheme.cardTitleTextStyle().copyWith(color: Colors.white)),
                                      ],
                                    ),
                                    Divider(thickness: 1, color: Colors.white.withOpacity(0.5)),
                                    SizedBox(height: 10),
                                    _buildDetailRow("Booking ID:", bookingData['bookingID']),
                                    _buildDetailRow("Service Category:", serviceName),
                                    _buildDetailRow("Provider:", providerName),
                                    _buildDetailRow("Event Date:", bookingData['eventDate']),
                                    _buildDetailRow("Status:", bookingData['status'], color: Colors.blue.shade300),
                                    SizedBox(height: 20),
                                    Center(
                                      child: ElevatedButton(
                                        onPressed: () => Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => HomePage(customerId: customerId),
                                          ),
                                              (route) => false, // Removes all previous routes
                                        ),
                                        style: AppTheme.cardButtonStyle().copyWith(
                                          padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 30, vertical: 12)),
                                          shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                                          backgroundColor: MaterialStateProperty.all(Colors.white.withOpacity(0.2)),
                                        ),
                                        child: Text("Back to Home", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, {Color color = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(Icons.arrow_right, color: Colors.white.withOpacity(0.8)),
          SizedBox(width: 5),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
          SizedBox(width: 5),
          Expanded(
            child: Text(value, style: TextStyle(color: color, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
