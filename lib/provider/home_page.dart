import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:online_service_booking/provider//shared_footer.dart';
import 'package:online_service_booking/theme.dart';

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
  }

  /// Load Service Provider Data from Firestore
  Future<void> _loadServiceProviderData() async {
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

      // Fetch Booking & Earnings Data
      QuerySnapshot bookingSnapshot = await FirebaseFirestore.instance
          .collection("bookings")
          .where("providerId", isEqualTo: widget.providerId)
          .get();

      if (bookingSnapshot.docs.isNotEmpty) {
        totalBookings = bookingSnapshot.docs.length;
        upcomingBookings = bookingSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

        double earnings = 0.0;
        double ratingSum = 0.0;
        int ratingCount = 0;

        for (var doc in bookingSnapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          if (data.containsKey("amount")) earnings += data["amount"];
          if (data.containsKey("rating")) {
            ratingSum += data["rating"];
            ratingCount++;
          }

          if (data["status"] == "Upcoming") {
            upcomingBookings.add(data);
          }
        }

        totalEarnings = earnings;
        avgRating = ratingCount > 0 ? ratingSum / ratingCount : 0.0;
      }
      // Fetch Payment History
      QuerySnapshot paymentsSnapshot = await FirebaseFirestore.instance
          .collection("payments")
          .where("providerId", isEqualTo: widget.providerId)
          .orderBy("date", descending: true)
          .get();

      paymentHistory = paymentsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      // Fetch notifications
      QuerySnapshot notificationSnapshot = await FirebaseFirestore.instance
          .collection("notifications")
          .where("providerId", isEqualTo: widget.providerId)
          .orderBy("timestamp", descending: true)
          .get();

      notifications = notificationSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      unreadNotifications = notifications.where((n) => !(n['read'] ?? false)).length;
    } catch (e) {
      print("⚠️ Error loading data: $e");
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// **2️⃣ Listen for Real-time Updates**
  void _listenForUpdates() {
    FirebaseFirestore.instance
        .collection("notifications")
        .where("providerId", isEqualTo: widget.providerId)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        notifications = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        unreadNotifications = notifications.where((n) => !(n['read'] ?? false)).length;
      });
    });
  }

  /// **4️⃣ Mark Notifications as Read**
  Future<void> _markNotificationsAsRead() async {
    for (var notification in notifications) {
      await FirebaseFirestore.instance
          .collection("notifications")
          .doc(notification["id"])
          .update({"read": true});
    }
    setState(() {
      unreadNotifications = 0;
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
                    _dashboardStat("Total Earnings", "₹${totalEarnings.toStringAsFixed(2)}", Icons.attach_money),
                    _dashboardStat("Rating", avgRating > 0 ? avgRating.toStringAsFixed(1) : "N/A", Icons.star),
                  ],
                ),
                SizedBox(height: 20),

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
                Text("Upcoming Bookings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
              icon: Icon(Icons.phone, color: Colors.green),
              onPressed: () => _callCustomer(booking['customerPhone']),
            ),
            IconButton(
              icon: Icon(Icons.chat, color: Colors.blue),
              onPressed: () {}, // Add Chat Functionality Later
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
