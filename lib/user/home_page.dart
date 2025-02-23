import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_service_booking/user/shared_footer.dart';
import 'dart:math';
import 'dart:ui';
import 'service_provider_list.dart';
import 'package:online_service_booking/theme.dart';
import 'shared_footer.dart';
import 'package:online_service_booking/user/notification_page.dart';

class HomePage extends StatefulWidget {
  final String customerId;

  HomePage({required this.customerId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Random random = Random();
  bool hasNewNotification = false;

  @override
  void initState() {
    super.initState();

    // Listen for notifications
    FirebaseFirestore.instance
        .collection("notifications")
        .where("customerId", isEqualTo: widget.customerId)
        .where("read", isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        hasNewNotification = snapshot.docs.isNotEmpty;
      });
    });

    // Listen for Completed bookings & trigger review popup
    FirebaseFirestore.instance
        .collection("bookings")
        .where("customerId", isEqualTo: widget.customerId)
        .where("status", isEqualTo: "Completed")
        .where("reviewed", isEqualTo: false) // Show only if not reviewed
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        print("✅ Booking marked as Completed. Showing review popup...");
      }
      for (var doc in snapshot.docs) {
        print("✅ Review needed for booking: ${doc.id}");
        _showReviewDialog(doc.id, doc["providerID"]);
      }
    });
  }

  // Function to show review popup
  void _showReviewDialog(String bookingId, String providerId) {
    print("📢 Review Dialog Triggered for Booking ID: $bookingId");
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
                print("✅ Submitting review...");
                // Save review to Firestore
                await FirebaseFirestore.instance.collection("reviews").add({
                  "providerID": providerId,
                  "customerID": widget.customerId,
                  "rating": rating,
                  "comment": reviewController.text,
                  "timestamp": FieldValue.serverTimestamp(),
                });

                // Update booking to indicate review was submitted
                await FirebaseFirestore.instance
                    .collection("bookings")
                    .doc(bookingId)
                    .update({"reviewed": true});
                print("✅ Review submitted for Booking ID: $bookingId");
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTheme.gradientUserAppBarWithNotification(
        title: 'HomePage',
        hasNewNotification: hasNewNotification,
        onNotificationPressed: () {
          // Mark notifications as read when clicked
          FirebaseFirestore.instance
              .collection("notifications")
              .where("customerId", isEqualTo: widget.customerId)
              .where("read", isEqualTo: false)
              .get()
              .then((snapshot) {
            for (var doc in snapshot.docs) {
              doc.reference.update({"read": true});
            }
          });

          setState(() {
            hasNewNotification = false; // Remove red dot
          });

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NotificationPage(customerId: widget.customerId),
            ),
          );
        },
      ),

      body: Container(
        child: Stack(
          children: [
            // Gradient Background
            Container(
              decoration: AppTheme.gradientBackground,
            ),

            // Floating Icons
            ...AppTheme.floatingIcons(context),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection("users").doc(widget.customerId).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(child: Text("Error: Customer data not found."));
                }

                var customerData = snapshot.data!;
                String name = customerData.get('name');
                String email = customerData.get('email');
                String phone = customerData.get('phone');

                return Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Available Services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance.collection("services").get(),
                          builder: (context, serviceSnapshot) {
                            if (serviceSnapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }

                            if (!serviceSnapshot.hasData || serviceSnapshot.data!.docs.isEmpty) {
                              return Center(child: Text("No services available."));
                            }

                            List<QueryDocumentSnapshot> services = serviceSnapshot.data!.docs;

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: services.length,
                              itemBuilder: (context, index) {
                                var serviceData = services[index].data() as Map<String, dynamic>;
                                return ServiceCard(
                                  service: serviceData,
                                  docId: services[index].id,
                                );
                              },
                            );
                          },
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
      bottomNavigationBar: SharedFooter(customerId: widget.customerId, currentIndex: 0,), // Add footer here
    );
  }
}

class ServiceCard extends StatefulWidget {
  final Map<String, dynamic> service;
  final String docId; // Firestore document id for this service


  ServiceCard({required this.service, required this.docId});

  @override
  _ServiceCardState createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(cardTheme: AppTheme.cardTheme()),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(widget.service['icon']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.service['serviceCategory'],
                      /*style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(1.5, 1.5),
                            blurRadius: 5.0,
                            color: Colors.black.withOpacity(0.7),
                          ),
                        ],
                      ),*/
                      style: AppTheme.cardTitleTextStyle(),
                    ),
                    SizedBox(height: 5),
                    Text(
                      widget.service['description'],
                      /*style: TextStyle(
                        fontSize: 14, color: Colors.grey[300],
                        shadows: [
                          Shadow(
                            offset: Offset(1.5, 1.5),
                            blurRadius: 7.0,
                            color: Colors.black,
                          ),
                        ],
                      ),*/
                      style: AppTheme.cardDescriptionTextStyle(),
                    ),
                    if (isExpanded) ...[
                      SizedBox(height: 5),
                      Text(
                        widget.service['fullDescription'],
                        /*style: TextStyle(
                          fontSize: 14, color: Colors.grey[350],
                          shadows: [
                            Shadow(
                              offset: Offset(0.5, 1.5),
                              blurRadius: 7.0,
                              color: Colors.black,
                            ),
                          ],
                        ),*/
                        style: AppTheme.fullDescriptionTextStyle(),
                      ),
                    ],
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "₹${widget.service['priceRange']}",
                          /*style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green,
                            shadows: [
                              Shadow(
                                offset: Offset(0.1, 0.1),
                                blurRadius: 9.0,
                                color: Colors.black.withOpacity(0.7),
                              ),
                            ],
                          ),*/
                          style: AppTheme.priceRangeTextStyle(),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  isExpanded = !isExpanded;
                                });
                              },

                              child: Text(isExpanded ? "Less" : "More", style: TextStyle(
                                shadows: [
                                  Shadow(
                                    offset: Offset(0.1, 0.1),
                                    blurRadius: 3.0,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ],
                              ),),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // When the Book button is pressed,
                                // navigate to the ServiceProviderList page,
                                // passing the service document id and icon URL.
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ServiceProviderList(
                                      serviceCategoryDocId: widget.docId,
                                      iconUrl: widget.service['icon'],
                                    ),
                                  ),
                                );
                              },
                              style: AppTheme.cardButtonStyle(),
                              child: Text("Book"),
                              /*style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFF8CB20)
                              ),*/
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
