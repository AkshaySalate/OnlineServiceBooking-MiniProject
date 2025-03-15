import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:online_service_booking/user/widgets/shared_footer.dart';
import 'package:online_service_booking/chat/chat_screen.dart';
import 'package:geocoding/geocoding.dart';
import 'package:online_service_booking/theme.dart';

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

      List<Future<Map<String, dynamic>>> bookingFutures = bookingSnapshot.docs.map((doc) async {
        var data = doc.data() as Map<String, dynamic>;

        double amount = (data["amount"] as num?)?.toDouble() ?? 0.0;
        String eventDateFormatted = data["eventDate"] is Timestamp
            ? (data["eventDate"] as Timestamp).toDate().toString()
            : data["eventDate"].toString();

        // Fetch service & provider details in parallel
        var serviceFuture = FirebaseFirestore.instance.collection("services").doc(data["serviceCategory"]).get();
        var providerFuture = FirebaseFirestore.instance.collection("service_providers").doc(data["providerID"]).get();

        var results = await Future.wait([serviceFuture, providerFuture]);
        var serviceDoc = results[0];
        var providerDoc = results[1];

        String serviceType = serviceDoc.exists ? serviceDoc["serviceCategory"] ?? "Unknown Service Type" : "Unknown Service Type";
        String providerName = providerDoc.exists ? providerDoc["name"] ?? "Unknown Provider" : "Unknown Provider";
        String providerAddress = providerDoc.exists && providerDoc["address"] != null ? providerDoc["address"] : "Address not available";

        return {
          "id": doc.id,
          "serviceType": serviceType,
          "eventDate": eventDateFormatted,
          "status": data["status"],
          "providerName": providerName,
          "amount": amount,
          "providerAddress": providerAddress,
          "providerID": data["providerID"],
        };
      }).toList();

      // Wait for all bookings to be processed
      userBookings = await Future.wait(bookingFutures);

      setState(() {
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

    /// **Convert LatLng to Detailed Address using Reverse Geocoding**
  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = "";

        // Append house/building number if available
        if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
          address += "${place.subThoroughfare} ";
        }
        // Append street name if available
        if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
          address += "${place.thoroughfare}, ";
        }
        // Append neighborhood (subLocality) if available
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          address += "${place.subLocality}, ";
        }
        // Append city (locality) if available
        if (place.locality != null && place.locality!.isNotEmpty) {
          address += "${place.locality}, ";
        }
        // Append state (administrativeArea) if available
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          address += "${place.administrativeArea}, ";
        }
        // Append postal code if available
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          address += "${place.postalCode}, ";
        }
        // Append country if available
        if (place.country != null && place.country!.isNotEmpty) {
          address += "${place.country}";
        }

        return address.trim().replaceAll(RegExp(r",\s*$"), "");
      }
    } catch (e) {
      print("⚠️ Error fetching address: $e");
    }
    return "Unknown Location";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTheme.gradientAppBar("My Bookings"),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: Stack(
          children: [
            ...AppTheme.floatingIcons(context),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : userBookings.isEmpty
                ? Center(child: Text("No bookings found.", style: Theme.of(context).textTheme.bodyMedium))
                  : ListView.builder(
                    itemCount: userBookings.length,
                    itemBuilder: (context, index) {
                      var booking = userBookings[index];
                      return Card(
                        shape: AppTheme.cardTheme().shape, // Themed Card
                        color: AppTheme.cardTheme().color,
                        elevation: AppTheme.cardTheme().elevation,
                        margin: AppTheme.cardTheme().margin,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Display the service type from the services collection
                              Text("📌 Service Type: ${booking['serviceType']}",
                                  style: AppTheme.cardTitleTextStyle()),
                              SizedBox(height: 5),
                              Text("👤 Provider: ${booking['providerName']}",
                                  style: AppTheme.cardDescriptionTextStyle()),
                              Text("📍 Address: ${booking['providerAddress']}",
                                  style: AppTheme.cardDescriptionTextStyle()),
                              Text("📅 Date: ${booking['eventDate']}",
                                  style: AppTheme.cardDescriptionTextStyle()),
                              Text("🟢 Status: ${booking['status']}",
                                  style: AppTheme.cardDescriptionTextStyle().copyWith(
                                      fontWeight: FontWeight.bold, color: _getStatusColor(booking['status']))),
                              if (booking['status'].toString().toLowerCase() == 'completed') ...[
                                SizedBox(height: 5),
                                Text("💰 Amount Paid: ₹${booking['amount']}",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                              SizedBox(height: 10),

                              // ⭐ Review and Chat Buttons in a Row
                              if (booking['status'] == "Completed" ||
                                  booking['status'].toString().toLowerCase() == 'pending' ||
                                  booking['status'].toString().toLowerCase() == 'upcoming')
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (booking['status'] == "Completed")
                                      SizedBox(
                                        width: MediaQuery.of(context).size.width * 0.7,
                                        child: booking["hasReviewed"]
                                            ? _displayExistingReview(booking["review"])
                                            : ElevatedButton(
                                          onPressed: () => _showReviewDialog(booking["providerID"]),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange.shade700,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: Text("Write a Review"),
                                        ),
                                      ),
                                    if (booking['status'].toString().toLowerCase() == 'pending' ||
                                        booking['status'].toString().toLowerCase() == 'upcoming')
                                      SizedBox(
                                        width: MediaQuery.of(context).size.width * 0.7,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ChatScreen(
                                                  customerId: widget.customerId,
                                                  providerId: booking['providerID'],
                                                ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green.shade700,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: Text("Chat"),
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                   ),
          ],
        ),
      ),
      bottomNavigationBar: SharedFooter(
          customerId: widget.customerId, currentIndex: 2),
    );
  }

  Widget _displayExistingReview(Map<String, dynamic> review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(thickness: 1),
        Text("Your Review", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        Text("⭐ ${review["rating"]}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
        Text(review["comment"], style: TextStyle(fontSize: 14)),
      ],
    );
  }

  void _showReviewDialog(String providerId) {
    double rating = 5.0;
    TextEditingController reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Leave a Review"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Rate your experience:"),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                    ),
                    onPressed: () {
                      setState(() {
                        rating = index + 1.0;
                      });
                    },
                  );
                }),
              ),
              TextField(
                controller: reviewController,
                decoration: InputDecoration(hintText: "Write your review..."),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text("Submit"),
              onPressed: () async {
                // Save review to Firestore
                await FirebaseFirestore.instance.collection("reviews").add({
                  "providerID": providerId,
                  "customerID": widget.customerId,
                  "rating": rating,
                  "comment": reviewController.text,
                  "timestamp": FieldValue.serverTimestamp(),
                });

                setState(() {
                  // Refresh bookings to show the submitted review
                  _fetchUserBookings();
                });

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
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
