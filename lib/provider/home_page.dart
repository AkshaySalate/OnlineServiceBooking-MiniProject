import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:online_service_booking/provider//shared_footer.dart';
import 'package:online_service_booking/theme.dart';
import 'package:online_service_booking/chat_screen.dart';
import 'bookings_page.dart';
import 'package:online_service_booking/provider/reviews_page.dart';
import 'package:online_service_booking/provider/provider_earnings_page.dart';

class ServiceProviderHomePage extends StatefulWidget {
  final String providerId;

  ServiceProviderHomePage({required this.providerId});

  @override
  _ServiceProviderHomePageState createState() => _ServiceProviderHomePageState();
}

class _ServiceProviderHomePageState extends State<ServiceProviderHomePage> {
  bool _isAvailable = false;
  bool _isLoading = true;
  int totalBookings = 0;
  double totalEarnings = 0.0;
  double avgRating = 0.0;
  List<Map<String, dynamic>> upcomingBookings = [];
  List<Map<String, dynamic>> paymentHistory = [];
  List<Map<String, dynamic>> notifications = [];
  int unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadServiceProviderData();
    _listenForUpdates();
    _loadProviderEarnings();
  }

  Future<void> acceptBooking(String bookingId, String customerId) async {
    await FirebaseFirestore.instance.collection("bookings").doc(bookingId).update({
      'status': 'Upcoming',
    });

    // 🔹 Add notification for the provider
    await FirebaseFirestore.instance.collection("notifications").add({
      "providerId": widget.providerId,
      "message": "You have accepted a new booking.",
      "timestamp": FieldValue.serverTimestamp(),
      "read": false,
    });

    // 🔹 Add notification for the customer
    await FirebaseFirestore.instance.collection("notifications").add({
      "customerId": customerId,
      "message": "Your booking has been accepted.",
      "timestamp": FieldValue.serverTimestamp(),
      "read": false,
    });

    setState(() {});
  }

  /// Load Provider Earnings from Firestore
  Future<void> _loadProviderEarnings() async {
    try {
      QuerySnapshot earningsSnapshot = await FirebaseFirestore.instance
          .collection("earnings")
          .where("providerID", isEqualTo: widget.providerId)
          .get();

      double totalEarnings = 0.0;
      for (var doc in earningsSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        totalEarnings += data["amount"];
      }

      setState(() {
        this.totalEarnings = totalEarnings;
      });
    } catch (e) {
      print("⚠️ Error loading earnings: $e");
    }
  }

  /// Load Service Provider Data from Firestore
  Future<void> _loadServiceProviderData() async {
    double ratingSum = 0.0;  // Define outside try block
    int ratingCount = 0;      // Define outside try block
    try {
      DocumentSnapshot providerDoc = await FirebaseFirestore.instance
          .collection("service_providers")
          .doc(widget.providerId)
          .get();

      if (providerDoc.exists) {
        var providerData = providerDoc.data() as Map<String, dynamic>;

        setState(() {
          _isAvailable = providerData['availability'] ?? false;
        });
      }

      // ✅ Fetch Reviews to Calculate Average Rating
      QuerySnapshot reviewSnapshot = await FirebaseFirestore.instance
          .collection("reviews")
          .where("providerID", isEqualTo: widget.providerId)
          .get();

      ratingCount = reviewSnapshot.docs.length; // Now accessible in catch block
      for (var doc in reviewSnapshot.docs) {
        var reviewData = doc.data() as Map<String, dynamic>;
        ratingSum += reviewData["rating"];
      }

      // ✅ Fetch Bookings
      QuerySnapshot bookingSnapshot = await FirebaseFirestore.instance
          .collection("bookings")
          .where("providerID", isEqualTo: widget.providerId)
          .get();

      List<Map<String, dynamic>> fetchedBookings = [];
      double earnings = 0.0;

      for (var doc in reviewSnapshot.docs) {
        var reviewData = doc.data() as Map<String, dynamic>;
        ratingSum += reviewData["rating"];
      }

      for (var doc in bookingSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        data["id"] = doc.id; // Store document ID

        if (data.containsKey("amount")) earnings += data["amount"];
        if (data.containsKey("rating")) {
          ratingSum += data["rating"];
          ratingCount++;
        }

        // ✅ Only include "Upcoming" bookings
        if (data["status"] == "Upcoming") {
          fetchedBookings.add(data);
        }
      }

      // ✅ Fetch Payment History
      QuerySnapshot paymentsSnapshot = await FirebaseFirestore.instance
          .collection("payments")
          .where("providerId", isEqualTo: widget.providerId)
          .orderBy("date", descending: true)
          .get();

      List<Map<String, dynamic>> fetchedPayments = paymentsSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // ✅ Fetch Notifications
      QuerySnapshot notificationSnapshot = await FirebaseFirestore.instance
          .collection("notifications")
          .where("providerId", isEqualTo: widget.providerId)
          .orderBy("timestamp", descending: true)
          .get();

      List<Map<String, dynamic>> fetchedNotifications = notificationSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      setState(() {
        totalBookings = bookingSnapshot.docs.length;
        upcomingBookings = fetchedBookings;
        totalEarnings = earnings;
        avgRating = ratingCount > 0 ? ratingSum / ratingCount : 0.0;
        paymentHistory = fetchedPayments;
        notifications = fetchedNotifications;
        unreadNotifications = fetchedNotifications.where((n) => !(n['read'] ?? false)).length;
        _isLoading = false;
      });

    } catch (e) {
      print("⚠️ Error loading data: $e");
      setState(() {
        avgRating = ratingCount > 0 ? ratingSum / ratingCount : 0.0;
        _isLoading = false;
      });
    }
  }


  /// **2️⃣ Listen for Real-time Updates**
  void _listenForUpdates() {
    FirebaseFirestore.instance
        .collection("notifications")
        .where("providerID", isEqualTo: widget.providerId)  // Ensure correct field name
        .orderBy("timestamp", descending: true)
        .snapshots()
        .listen((snapshot) {
      List<Map<String, dynamic>> updatedNotifications = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data["id"] = doc.id;  // Store document ID for updating
        return data;
      }).toList();

      setState(() {
        notifications = updatedNotifications;
        unreadNotifications = updatedNotifications.where((n) => !(n['read'] ?? false)).length;
      });

      if (unreadNotifications > 0) {
        _showNewBookingAlert();
      }
    });
  }


  void _showNewBookingAlert() {
    if (notifications.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("New Booking Request!"),
        content: Text("You have a new booking. Please check your bookings."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _markNotificationsAsRead();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProviderBookingsPage(providerId: widget.providerId),
                ),
              );
            },
            child: Text("View Bookings"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Dismiss"),
          ),
        ],
      ),
    );
  }



  /// **4️⃣ Mark Notifications as Read**
  Future<void> _markNotificationsAsRead() async {
    List<String> notificationIds = notifications
        .where((n) => !(n['read'] ?? false))
        .map((n) => n["id"].toString())
        .toList();

    if (notificationIds.isEmpty) return;

    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (String id in notificationIds) {
      batch.update(FirebaseFirestore.instance.collection("notifications").doc(id), {"read": true});
    }
    await batch.commit();

    setState(() {
      unreadNotifications = 0;
      notifications.forEach((n) => n["read"] = true);
    });
  }


  /// Toggle Availability Status
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
      appBar: AppTheme.gradientAppBarWithIcon(
        "Dashboard",
        Icons.notifications,
        unreadNotifications > 0 ? Colors.orange : Colors.white,
            () {
          _markNotificationsAsRead();
          showDialog(
            context: context,
            builder: (_) => _notificationDialog(),
          );
        },
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          // 🌟 Gradient Background
          Container(
            decoration: AppTheme.gradientBackground,
          ),

          // 🌟 Floating Icons
          ...AppTheme.floatingIcons(context),

          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// **1️⃣ Welcome Message**
                Text(
                  "Welcome, Service Provider!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 10),

                /// **2️⃣ Dashboard Stats**
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _dashboardStat("Total Bookings", totalBookings.toString(), Icons.calendar_today),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProviderEarningsPage(providerId: widget.providerId),
                          ),
                        );
                      },
                      child: _dashboardStat("Total Earnings", "₹${totalEarnings.toStringAsFixed(2)}", Icons.attach_money),
                    ),
                    _dashboardStat("Rating", avgRating > 0 ? "${avgRating.toStringAsFixed(1)} / 10" : "N/A", Icons.star),
                  ],
                ),
                SizedBox(height: 20),

                /// **🔹 3️⃣ Service Provider Reviews Section**
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("reviews")
                      .where("providerID", isEqualTo: widget.providerId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Text("No reviews yet.");
                    }

                    var reviews = snapshot.data!.docs;
                    double totalRating = 0;
                    for (var review in reviews) {
                      totalRating += review["rating"];
                    }

                    double averageRating = totalRating / reviews.length;

                    return Card(
                      margin: EdgeInsets.all(10),
                      child: ListTile(
                        leading: Icon(Icons.star, color: Colors.orange, size: 30),
                        title: Text("⭐ ${averageRating.toStringAsFixed(1)}"),
                        subtitle: Text("${reviews.length} reviews"),
                        trailing: TextButton(
                          child: Text("View Reviews"),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProviderReviewsPage(providerId: widget.providerId),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),

                /// **3️⃣ Availability Toggle**
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Available for Bookings?", style: TextStyle(fontSize: 18, color: Colors.white)),
                    Switch(
                      value: _isAvailable,
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.red,
                      onChanged: (value) => _toggleAvailability(value),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                /// **4️⃣ Earnings Summary**
                Text("Earnings & Payments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 10),
                paymentHistory.isEmpty
                    ? Text("No payment history available.", style: TextStyle(color: Colors.white))
                    : Expanded(
                  child: ListView.builder(
                    itemCount: paymentHistory.length,
                    itemBuilder: (context, index) {
                      var payment = paymentHistory[index];
                      return _paymentCard(payment);
                    },
                  ),
                ),

                SizedBox(height: 20),

                /// **4️⃣ Active Bookings**
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProviderBookingsPage(providerId: widget.providerId),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Upcoming Bookings",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 10),
                      upcomingBookings.isEmpty
                          ? Text("No upcoming bookings.", style: TextStyle(color: Colors.white))
                          : Expanded(
                        child: ListView.builder(
                          itemCount: upcomingBookings.length,
                          itemBuilder: (context, index) {
                            var booking = upcomingBookings[index];
                            return _bookingCard(booking);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                /// **5️⃣ Quick Actions**
                Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _quickActionButton("Edit Profile", Icons.edit, () {}),
                    _quickActionButton("Manage Services", Icons.settings, () {}),
                    _quickActionButton("Support", Icons.help, () {}),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),

      /// **Navigation Bar**
      bottomNavigationBar: SharedFooter(providerId: widget.providerId, currentIndex: 0),
    );
  }

  /// **📌 Dashboard Stat Widget**
  Widget _dashboardStat(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.white),
        SizedBox(height: 5),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(title, style: TextStyle(fontSize: 14, color: Colors.white70)),
      ],
    );
  }

  /// **📌 Booking Card**
  Widget _bookingCard(Map<String, dynamic> booking) {
    return Card(
      color: Colors.white.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text("${booking['customerName']} - ${booking['serviceType']}"),
        subtitle: Text("Date: ${booking['date']} | Time: ${booking['time']}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.phone, color: Colors.red),
              onPressed: () => _callCustomer(booking['customerPhone']),
            ),
            IconButton(
              icon: Icon(Icons.chat, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      providerId: widget.providerId,
                      customerId: booking['customerId'],
                    ),
                  ),
                );
              }, // Add Chat Functionality Later
            ),
          ],
        ),
      ),
    );
  }


  /// **📌 Booking Action Button**
  Widget _bookingActionButton(String status) {
    if (status == "Pending") {
      return ElevatedButton(
        onPressed: () {},
        child: Text("Accept"),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
      );
    } else if (status == "Upcoming") {
      return ElevatedButton(
        onPressed: () {},
        child: Text("Complete"),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
      );
    }
    return SizedBox();
  }

  /// **📌 Payment Card Widget**
  Widget _paymentCard(Map<String, dynamic> payment) {
    return Card(
      color: Colors.white.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.attach_money, color: Colors.green),
        title: Text("₹${payment['amount']}"),
        subtitle: Text("Date: ${payment['date']}\nStatus: ${payment['status']}"),
        trailing: payment['status'] == "Pending"
            ? Icon(Icons.warning, color: Colors.orange)
            : Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  /// **📌 Quick Action Button**
  Widget _quickActionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(icon, size: 30, color: Colors.white),
          ),
          SizedBox(height: 5),
          Text(label, style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
  /// **📌 Call Customer**
  void _callCustomer(String phoneNumber) async {
    final Uri phoneUri = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      print("Could not launch call.");
    }
  }

  /// **📌 Notification Dialog**
  Widget _notificationDialog() {
    return AlertDialog(
      title: Text("Notifications"),
      content: notifications.isEmpty
          ? Text("No new notifications.")
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: notifications.map((n) => ListTile(
          leading: Icon(Icons.notifications, color: Colors.orange),
          title: Text(n["message"]),
          subtitle: Text(n["timestamp"].toDate().toString()),
        )).toList(),
      ),
      actions: [
        TextButton(
          child: Text("Close"),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
