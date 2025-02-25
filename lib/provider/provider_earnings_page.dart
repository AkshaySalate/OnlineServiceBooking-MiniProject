import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderEarningsPage extends StatefulWidget {
  final String providerId;
  ProviderEarningsPage({required this.providerId});

  @override
  _ProviderEarningsPageState createState() => _ProviderEarningsPageState();
}

class _ProviderEarningsPageState extends State<ProviderEarningsPage> {
  double thisMonthEarnings = 0.0;
  double lastMonthEarnings = 0.0;
  double yearlyEarnings = 0.0;
  double totalEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  /// **📌 Fetch Provider Earnings Data**
  Future<void> _loadEarnings() async {
    try {
      QuerySnapshot earningsSnapshot = await FirebaseFirestore.instance
          .collection("earnings")
          .where("providerID", isEqualTo: widget.providerId)
          .get();

      double thisMonth = 0.0;
      double lastMonth = 0.0;
      double thisYear = 0.0;
      double total = 0.0;

      DateTime now = DateTime.now();
      DateTime firstDayOfThisMonth = DateTime(now.year, now.month, 1);
      DateTime firstDayOfLastMonth = DateTime(now.year, now.month - 1, 1);
      DateTime firstDayOfThisYear = DateTime(now.year, 1, 1);

      for (var doc in earningsSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        double amount = data["amount"];
        DateTime earningDate = (data["date"] as Timestamp).toDate();

        total += amount;
        if (earningDate.isAfter(firstDayOfThisMonth)) {
          thisMonth += amount;
        } else if (earningDate.isAfter(firstDayOfLastMonth)) {
          lastMonth += amount;
        } else if (earningDate.isAfter(firstDayOfThisYear)) {
          thisYear += amount;
        }
      }

      setState(() {
        thisMonthEarnings = thisMonth;
        lastMonthEarnings = lastMonth;
        yearlyEarnings = thisYear;
        totalEarnings = total;
      });
    } catch (e) {
      print("⚠️ Error loading earnings: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Earnings Summary")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📅 This Month's Earnings: ₹${thisMonthEarnings.toStringAsFixed(2)}", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text("📅 Last Month's Earnings: ₹${lastMonthEarnings.toStringAsFixed(2)}", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text("📅 This Year's Earnings: ₹${yearlyEarnings.toStringAsFixed(2)}", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text("💰 Total Earnings: ₹${totalEarnings.toStringAsFixed(2)}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
