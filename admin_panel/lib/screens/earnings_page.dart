import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EarningsPage extends StatefulWidget {
  @override
  _EarningsPageState createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  String selectedSort = "amount";
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Earnings Report"),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedSort,
              onChanged: (String? newValue) {
                setState(() {
                  selectedSort = newValue!;
                });
              },
              items: ["amount", "providerID"].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text("Sort by: $value"),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('earnings').orderBy(selectedSort, descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                var earnings = snapshot.data!.docs;

                if (_selectedStartDate != null && _selectedEndDate != null) {
                  earnings = earnings.where((earning) {
                    DateTime earningDate = (earning['date'] as Timestamp).toDate();
                    return earningDate.isAfter(_selectedStartDate!) && earningDate.isBefore(_selectedEndDate!);
                  }).toList();
                }

                return ListView.builder(
                  itemCount: earnings.length,
                  itemBuilder: (context, index) {
                    var earning = earnings[index];
                    return ListTile(
                      title: Text("Provider ID: ${earning['providerID']}"),
                      subtitle: Text("Amount: \$${earning['amount']}\nDate: ${DateFormat.yMMMd().format((earning['date'] as Timestamp).toDate())}"),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
