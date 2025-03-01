import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingsPage extends StatefulWidget {
  @override
  _BookingsPageState createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String _selectedStatus = "All";

  Future<String> _fetchUserName(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.exists ? userDoc['name'] ?? 'Unknown' : 'Unknown';
  }

  Future<String> _fetchProviderName(String providerId) async {
    DocumentSnapshot providerDoc = await FirebaseFirestore.instance.collection('service_providers').doc(providerId).get();
    return providerDoc.exists ? providerDoc['name'] ?? 'Unknown' : 'Unknown';
  }

  Future<void> _completeBooking(String bookingId, String providerId, num amount) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({'status': 'Completed'});

    await FirebaseFirestore.instance.collection('earnings').add({
      'providerID': providerId,
      'amount': amount,
      'date': Timestamp.now(),
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      'providerID': providerId,
      'message': 'Your booking has been marked as completed!',
      'read': false,
      'timestamp': Timestamp.now(),
    });
  }

  void _pickDateRange() async {
    DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedRange != null) {
      setState(() {
        _selectedStartDate = pickedRange.start;
        _selectedEndDate = pickedRange.end;
      });
    }
  }

  void _showBookingDetails(BuildContext context, DocumentSnapshot booking, String userName, String providerName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Booking Details"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Booking ID: ${booking.id}"),
              Text("Customer: $userName"),
              Text("Provider: $providerName"),
              Text("Status: ${booking['status'] ?? 'pending'}"),
              Text("Amount: ${booking['amount']}"),
              Text("Event Date: ${DateFormat.yMMMd().format(DateTime.parse(booking['eventDate']))}"),
              if ((booking.data() as Map<String, dynamic>).containsKey('notes'))
                Text("Notes: ${booking['notes']}", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bookings"),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _pickDateRange,
          ),
          DropdownButton<String>(
            value: _selectedStatus,
            onChanged: (String? newValue) {
              setState(() {
                _selectedStatus = newValue!;
              });
            },
            items: ["All", "pending", "Completed", "Upcoming"].map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status),
              );
            }).toList(),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          var bookings = snapshot.data!.docs;

          if (_selectedStartDate != null && _selectedEndDate != null) {
            bookings = bookings.where((booking) {
              DateTime bookingDate = DateTime.parse(booking['eventDate']);
              return bookingDate.isAfter(_selectedStartDate!) && bookingDate.isBefore(_selectedEndDate!);
            }).toList();
          }

          if (_selectedStatus != "All") {
            bookings = bookings.where((booking) => booking['status'] == _selectedStatus).toList();
          }

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
                  return Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      title: Text("Booking ID: ${booking.id}"),
                      subtitle: Text("User: $userName\nProvider: $providerName\nStatus: ${booking['status'] ?? 'pending'}\nAmount: ${booking['amount']}"),
                      onTap: () => _showBookingDetails(context, booking, userName, providerName),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (booking['status'] != 'Completed')
                            IconButton(
                              icon: Icon(Icons.check, color: Colors.green),
                              onPressed: () {
                                _completeBooking(booking.id, booking['providerID'], booking['amount']);
                              },
                            ),
                        ],
                      ),
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
