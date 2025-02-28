import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BookingsPage extends StatelessWidget {
  Future<String> _fetchUserName(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.exists ? userDoc['name'] ?? 'Unknown' : 'Unknown';
  }

  Future<String> _fetchProviderName(String providerId) async {
    DocumentSnapshot providerDoc = await FirebaseFirestore.instance.collection('service_providers').doc(providerId).get();
    return providerDoc.exists ? providerDoc['name'] ?? 'Unknown' : 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bookings")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          var bookings = snapshot.data!.docs;
          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              var booking = bookings[index];
              return FutureBuilder(
                future: Future.wait([
                  _fetchUserName(booking['customerID']),
                  _fetchProviderName(booking['providerID'])
                ]),
                builder: (context, AsyncSnapshot<List<String>> userProviderSnapshot) {
                  if (!userProviderSnapshot.hasData) return ListTile(title: Text("Loading..."));
                  String userName = userProviderSnapshot.data![0];
                  String providerName = userProviderSnapshot.data![1];
                  return ListTile(
                    title: Text("Booking ID: ${booking.id}"),
                    subtitle: Text("User: $userName\nProvider: $providerName\nStatus: ${booking['status'] ?? 'Pending'}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.cancel, color: Colors.red),
                          onPressed: () {
                            FirebaseFirestore.instance.collection('bookings').doc(booking.id).update({'status': 'Cancelled'});
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.check, color: Colors.green),
                          onPressed: () {
                            FirebaseFirestore.instance.collection('bookings').doc(booking.id).update({'status': 'Completed'});
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}