import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'dart:html' as html;
import 'dart:convert';

class EarningsPage extends StatefulWidget {
  @override
  _EarningsPageState createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  String selectedSort = "amount";
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  num totalEarnings = 0;
  final int _perPage = 10;
  DocumentSnapshot? _lastDocument;
  List<DocumentSnapshot> _earnings = [];
  Map<String, num> _providerEarnings = {};
  bool _isLoading = false;
  bool _hasMore = true;

  Future<void> _calculateTotalEarnings() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('earnings').get();
    num sum = snapshot.docs.fold(0, (total, doc) => total + (doc['amount'] as num));
    setState(() {
      totalEarnings = sum;
    });
  }

  Future<void> _calculateProviderEarnings() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('earnings').get();
    Map<String, num> providerTotals = {};

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String providerId = data['providerID'];
      num amount = data['amount'];

      if (providerTotals.containsKey(providerId)) {
        providerTotals[providerId] = providerTotals[providerId]! + amount;
      } else {
        providerTotals[providerId] = amount;
      }
    }

    setState(() {
      _providerEarnings = providerTotals;
    });
  }

  Future<String> _fetchProviderName(String providerId) async {
    DocumentSnapshot providerDoc = await FirebaseFirestore.instance.collection('service_providers').doc(providerId).get();
    return providerDoc.exists ? providerDoc['name'] ?? 'Unknown' : 'Unknown';
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
      _calculateTotalEarnings();
    }
  }

  Future<void> _exportEarningsToCSV() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('earnings').get();
    List<List<String>> csvData = [
      ["Provider Name", "Amount", "Date"]
    ];

    for (var earning in snapshot.docs) {
      var data = earning.data() as Map<String, dynamic>;
      String providerName = await _fetchProviderName(data['providerID']);
      csvData.add([
        providerName,
        data['amount'].toString(),
        DateFormat.yMMMd().format((data['date'] as Timestamp).toDate()),
      ]);
    }

    String csv = const ListToCsvConverter().convert(csvData);
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "earnings.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _loadEarnings() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('earnings')
        .orderBy(selectedSort, descending: true)
        .limit(_perPage);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    QuerySnapshot snapshot = await query.get();
    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _earnings.addAll(snapshot.docs);
        _lastDocument = snapshot.docs.last;
        if (snapshot.docs.length < _perPage) _hasMore = false;
      });
    } else {
      setState(() => _hasMore = false);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadAllEarnings() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('earnings').orderBy(selectedSort, descending: true).get();
    setState(() {
      _earnings = snapshot.docs;
      _hasMore = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculateTotalEarnings();
    _calculateProviderEarnings();
    _loadEarnings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Earnings Report"),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _exportEarningsToCSV,
          ),
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 7,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Total Earnings: \₹${totalEarnings.toStringAsFixed(2)}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _earnings.length,
                    itemBuilder: (context, index) {
                      var earning = _earnings[index];
                      return FutureBuilder(
                        future: _fetchProviderName(earning['providerID']),
                        builder: (context, AsyncSnapshot<String> providerSnapshot) {
                          String providerName = providerSnapshot.hasData ? providerSnapshot.data! : 'Loading...';
                          return ListTile(
                            title: Text("Provider: $providerName"),
                            subtitle: Text("Amount: \₹${earning['amount']}\nDate: ${DateFormat.yMMMd().format((earning['date'] as Timestamp).toDate())}"),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _hasMore ? _loadEarnings : null,
                        child: Text("Load More"),
                      ),
                      TextButton(
                        onPressed: _loadAllEarnings,
                        child: Text("Load All"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          VerticalDivider(),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                //Text("Earnings Breakdown by Provider", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Text("Earnings Breakdown by Provider", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: _providerEarnings.isNotEmpty
                            ? ListView(
                          children: _providerEarnings.entries.map((entry) {
                            return FutureBuilder(
                              future: _fetchProviderName(entry.key),
                              builder: (context, AsyncSnapshot<String> providerSnapshot) {
                                String providerName = providerSnapshot.hasData ? providerSnapshot.data! : 'Loading...';
                                return ListTile(
                                  title: Text("Provider: $providerName"),
                                  subtitle: Text("Total Earnings: \₹${entry.value.toStringAsFixed(2)}"),
                                );
                              },
                            );
                          }).toList(),
                        )
                            : Center(child: Text("No earnings data available")),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
