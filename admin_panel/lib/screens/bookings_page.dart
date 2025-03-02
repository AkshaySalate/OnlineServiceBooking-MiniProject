import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'dart:html' as html;
import 'dart:convert';

class BookingsPage extends StatefulWidget {
  @override
  _BookingsPageState createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String _selectedStatus = "All";
  int _limit = 10;
  bool _loadAllData = false;

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

  Future<void> _cancelBooking(String bookingId) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({'status': 'Cancelled'});
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

  void _resetFilters() {
    setState(() {
      _selectedStartDate = null;
      _selectedEndDate = null;
      _selectedStatus = "All";
    });
  }

  void _loadMore() {
    setState(() {
      _limit += 10;
    });
  }

  void _setLoadAll() {
    setState(() {
      _loadAllData = true;
    });
  }

  void _addNoteToBooking(String bookingId, String existingNote) {
    TextEditingController noteController = TextEditingController(text: existingNote);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add/Edit Note"),
          content: TextField(
            controller: noteController,
            decoration: InputDecoration(labelText: "Enter notes"),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
                  'notes': noteController.text,
                });
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
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
            ElevatedButton(
              onPressed: () => _addNoteToBooking(booking.id, (booking.data() as Map<String, dynamic>)['notes'] ?? ""),
              child: Text("Edit Note"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportBookingsToCSV() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('bookings').get();
    List<List<String>> csvData = [
      ["Booking ID", "Customer ID", "Provider ID", "Amount", "Event Date", "Status", "Notes"]
    ];

    for (var booking in snapshot.docs) {
      var data = booking.data() as Map<String, dynamic>;
      csvData.add([
        booking.id,
        data['customerID'] ?? '',
        data['providerID'] ?? '',
        data['amount'].toString(),
        data['eventDate'] ?? '',
        data['status'] ?? 'pending',
        data.containsKey('notes') ? data['notes'] : ''
      ]);
    }

    String csv = const ListToCsvConverter().convert(csvData);
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "bookings.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bookings"),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _exportBookingsToCSV,
          ),
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
            items: ["All", "pending", "Completed", "Upcoming", "Cancelled"].map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status),
              );
            }).toList(),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetFilters,
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('bookings').limit(_loadAllData ? 1000 : _limit).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          var bookings = snapshot.data!.docs;

          if (_selectedStartDate != null && _selectedEndDate != null) {
            bookings = bookings.where((booking) {
              DateTime bookingDate = DateTime.parse(booking['eventDate']);
              return bookingDate.isAfter(_selectedStartDate!.subtract(Duration(days: 1))) &&
                  bookingDate.isBefore(_selectedEndDate!.add(Duration(days: 1)));
            }).toList();
          }

          if (_selectedStatus != "All") {
            bookings = bookings.where((booking) => booking['status'] == _selectedStatus).toList();
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
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
                            subtitle: Text("User: $userName\nProvider: $providerName\nStatus: ${booking['status'] ?? 'pending'}\nAmount: ${booking['amount']}\nEvent Date: ${DateFormat.yMMMd().format(DateTime.parse(booking['eventDate']))}"),
                            onTap: () => _showBookingDetails(context, booking, userName, providerName),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.cancel, color: Colors.red),
                                  onPressed: () => _cancelBooking(booking.id),
                                ),
                                IconButton(
                                  icon: Icon(Icons.check_circle, color: Colors.green),
                                  onPressed: () => _completeBooking(booking.id, booking['providerID'], booking['amount']),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _loadMore,
                    child: Text("Load More"),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _setLoadAll,
                    child: Text("Load All"),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
