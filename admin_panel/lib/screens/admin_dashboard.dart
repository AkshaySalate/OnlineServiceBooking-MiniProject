
import 'package:admin_panel/screens/providers_page.dart';
import 'package:admin_panel/screens/users_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'admin_login_screen.dart';
import 'bookings_page.dart';
import 'earnings_page.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int totalUsers = 0;
  int totalProviders = 0;
  int totalBookings = 0;
  double totalEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      QuerySnapshot providersSnapshot = await FirebaseFirestore.instance.collection('service_providers').get();
      QuerySnapshot bookingsSnapshot = await FirebaseFirestore.instance.collection('bookings').get();
      QuerySnapshot earningsSnapshot = await FirebaseFirestore.instance.collection('earnings').get();

      double earnings = earningsSnapshot.docs.fold(0.0, (sum, doc) => sum + (doc['amount'] as double));

      setState(() {
        totalUsers = usersSnapshot.docs.length;
        totalProviders = providersSnapshot.docs.length;
        totalBookings = bookingsSnapshot.docs.length;
        totalEarnings = earnings;
      });
    } catch (e) {
      print("Error fetching stats: $e");
    }
  }

  void _navigateToUsersPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UsersPage()),
    );
  }
  void _navigateToProvidersPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProvidersPage()),
    );
  }
  void _navigateToBookingsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookingsPage()),
    );
  }
  void _navigateToEarningsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EarningsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Center(child: Text("Error: ${details.exceptionAsString()}", style: TextStyle(color: Colors.red)));
    };
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut(); // Sign out the admin

              // Redirect to Login Page and remove all previous routes
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
                    (route) => false, // This removes all routes from the stack
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text("Admin Panel", style: TextStyle(fontSize: 24))),
            ListTile(title: Text("Users"), onTap: _navigateToUsersPage),
            ListTile(title: Text("Providers"), onTap: _navigateToProvidersPage),
            ListTile(title: Text("Bookings"), onTap: _navigateToBookingsPage),
            ListTile(title: Text("Earnings"), onTap: _navigateToEarningsPage),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Dashboard Stats", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statCard("Total Users", totalUsers.toString()),
                _statCard("Total Providers", totalProviders.toString()),
                _statCard("Total Bookings", totalBookings.toString()),
                _statCard("Total Earnings", "\$${totalEarnings.toStringAsFixed(2)}"),
              ],
            ),
            SizedBox(height: 30),
            Expanded(child: _buildBookingsChart()),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value) {
    return Card(
      elevation: 4,
      color: Colors.blueGrey,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.yellow)),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Bookings Over Time", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [FlSpot(1, 10), FlSpot(2, 20), FlSpot(3, 30), FlSpot(4, 50)],
                      isCurved: true,
                      gradient: LinearGradient(  // ✅ Fix applied here
                        colors: [Colors.blue, Colors.blueAccent],
                      ),
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}