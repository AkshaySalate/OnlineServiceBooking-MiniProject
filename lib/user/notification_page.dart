import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_service_booking/user/shared_footer.dart';

class NotificationPage extends StatefulWidget {
  final String customerId;

  NotificationPage({required this.customerId});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notifications")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("notifications")
            .where("customerId", isEqualTo: widget.customerId)
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No notifications available."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var notification = snapshot.data!.docs[index];
              String message = notification["message"];
              bool read = notification["read"] ?? false;

              return ListTile(
                title: Text(
                  message,
                  style: TextStyle(
                    fontWeight: read ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                leading: Icon(Icons.notifications, color: read ? Colors.grey : Colors.orange),
              );
            },
          );
        },
      ),
      bottomNavigationBar: SharedFooter(customerId: widget.customerId, currentIndex: 3),
    );
  }
}
