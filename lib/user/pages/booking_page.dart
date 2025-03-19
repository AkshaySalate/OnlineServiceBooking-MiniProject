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
      print("🔄 Processing bookings...");

      List<Map<String, dynamic>> fetchedBookings = [];

      // Loop through each booking document
      for (var doc in bookingSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        // ✅ Fetch the service price from `amount`
        double amount = data.containsKey("amount") ? (data["amount"] as num).toDouble() : 0.0;
        print("✅ Found amount: $amount");

        // Convert eventDate from Timestamp to a formatted string
        String eventDateFormatted = data["eventDate"].toString();
        if (data["eventDate"] is Timestamp) {
          eventDateFormatted =
              (data["eventDate"] as Timestamp).toDate().toString();
        } else {
          eventDateFormatted = data["eventDate"].toString();
        }

        // Fetch service provider details
        DocumentSnapshot providerDoc = await FirebaseFirestore.instance
            .collection("service_providers")
            .doc(data["providerID"])
            .get();

        // Fetch service details (service type)
        DocumentSnapshot serviceDoc = await FirebaseFirestore.instance
            .collection("services")
            .doc(data["serviceCategory"]) // booking's serviceCategory is the service document id
            .get();

        String serviceType = "Unknown Service Type";
        if (serviceDoc.exists) {
          var serviceData = serviceDoc.data() as Map<String, dynamic>;
          serviceType = serviceData["serviceCategory"] ?? serviceType;
        }

        // Fetch existing review (if any)
        QuerySnapshot reviewSnapshot = await FirebaseFirestore.instance
            .collection("reviews")
            .where("providerID", isEqualTo: data["providerID"])
            .where("customerID", isEqualTo: widget.customerId)
            .get();

        bool hasReviewed = reviewSnapshot.docs.isNotEmpty;
        Map<String, dynamic>? reviewData =
        hasReviewed ? reviewSnapshot.docs.first.data() as Map<String, dynamic> : null;

        String providerAddress = "Address not available";
        if (providerDoc.exists) {
          var providerData = providerDoc.data() as Map<String, dynamic>;
          // Check if provider has a location (GeoPoint) field
          if (providerData.containsKey("location") &&
              providerData["location"] != null) {
            GeoPoint providerLocation = providerData["location"];
            providerAddress = await _getAddressFromLatLng(
                providerLocation.latitude, providerLocation.longitude);
          } else if (providerData.containsKey("address")) {
            providerAddress = providerData["address"];
          }
        }

        if (providerDoc.exists) {
          var providerData = providerDoc.data() as Map<String, dynamic>;

          // Build a booking map with all necessary details
          Map<String, dynamic> booking = {
            "id": doc.id, // Booking ID
            // Here we use the serviceCategory field from the booking.
            "serviceType": serviceType,
            // You could update this logic if you wish to fetch details from the services collection.
            "serviceName": data["serviceCategory"],
            "eventDate": eventDateFormatted,
            "status": data["status"],
            "providerName": providerData["name"],
            "amount": amount,
            "providerAddress": providerAddress,
            // Add providerID so that it can be passed to ChatScreen
            "providerID": data["providerID"],
            "hasReviewed": hasReviewed,
            "review": reviewData,
          };

          fetchedBookings.add(booking);
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
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          double cardWidth = constraints.maxWidth * 0.9;
                          return Center(
                            child: Card(
                              shape: AppTheme.cardTheme().shape,
                              color: AppTheme.cardTheme().color,
                              elevation: AppTheme.cardTheme().elevation,
                              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              child: Container(
                                width: cardWidth,
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (booking['status'] == "Completed")
                                          SizedBox(
                                            width: cardWidth * 0.7,
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
                                            width: cardWidth * 0.7,
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
                            ),
                          );
                        },
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
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Leave a Review", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 15),
                    Text("Rate your experience:", style: TextStyle(fontSize: 16)),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              rating = index + 1.0;
                            });
                          },
                          child: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.orange,
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 10),
                    Text("Selected Rating: ${rating.toInt()} Stars", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    TextField(
                      controller: reviewController,
                      decoration: InputDecoration(
                        hintText: "Write your review...",
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Cancel", style: TextStyle(color: Colors.red, fontSize: 16)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text("Submit", style: TextStyle(fontSize: 16)),
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection("reviews").add({
                              "providerID": providerId,
                              "customerID": widget.customerId,
                              "rating": rating,
                              "comment": reviewController.text,
                              "timestamp": FieldValue.serverTimestamp(),
                            });

                            setState(() {
                              _fetchUserBookings();
                            });

                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
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
