
import 'package:admin_panel/screens/providers_page.dart';
import 'package:admin_panel/screens/users_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  String selectedFilter = "This Week";

  Stream<int> _getTotalUsers() {
    return FirebaseFirestore.instance.collection('users').snapshots().map((snapshot) => snapshot.docs.length);
  }

  Stream<int> _getTotalProviders() {
    return FirebaseFirestore.instance.collection('service_providers').snapshots().map((snapshot) => snapshot.docs.length);
  }

  Stream<int> _getTotalBookings() {
    return FirebaseFirestore.instance.collection('bookings').snapshots().map((snapshot) => snapshot.docs.length);
  }

  Stream<num> _getTotalEarnings() {
    return FirebaseFirestore.instance.collection('earnings').snapshots().map(
          (snapshot) => snapshot.docs.fold(0.0, (sum, doc) => sum + (doc['amount'] as double)),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void initState() {
    super.initState();
    _debugFirestoreData();
  }

  void _debugFirestoreData() async {
    var snapshot = await FirebaseFirestore.instance.collection('bookings').get();
    print("Total bookings found: \${snapshot.docs.length}");
    for (var doc in snapshot.docs) {
      print("Booking: \${doc.data()}");
    }
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
            ListTile(leading: Icon(Icons.person), title: Text("Users"), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UsersPage()))),
            ListTile(leading: Icon(Icons.business), title: Text("Providers"), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProvidersPage()))),
            ListTile(leading: Icon(Icons.book_online), title: Text("Bookings"), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BookingsPage()))),
            ListTile(leading: Icon(Icons.currency_rupee), title: Text("Earnings"), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EarningsPage()))),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Dashboard Stats", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard("Total Users", Icons.people, Colors.blue, _getTotalUsers()),
                  _buildStatCard("Total Providers", Icons.business, Colors.orange, _getTotalProviders()),
                  _buildStatCard("Total Bookings", Icons.book_online, Colors.green, _getTotalBookings()),
                  _buildStatCard("Total Earnings", Icons.currency_rupee, Colors.purple, _getTotalEarnings(), isCurrency: true),
                ],
              ),
              //SizedBox(height: 20),
              DropdownButton<String>(
                value: selectedFilter,
                items: ["This Week", "Last Week", "This Month", "Last Month", "This Year"]
                    .map((filter) => DropdownMenuItem(value: filter, child: Text(filter)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedFilter = value!;
                  });
                },
              ),
              SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(width: 500, height: 300, child: _buildBookingsChart()), // Booking Chart
                    SizedBox(width: 20),
                    Container(width: 250, height: 300, child: _buildUserDistributionPieChart()), // Pie Chart in the middle
                    SizedBox(width: 20),
                    Container(width: 500, height: 300, child: _buildMonthlyBookingsBarChart()), // Bar Chart on the right
                  ],
                ),
              ),
              //Expanded(child: _buildBookingsChart()),
              //SizedBox(height: 200, child: _buildUserDistributionPieChart()),
              //Expanded(child: _buildUserDistributionPieChart()),
              //SizedBox(height: 200, child: _buildBookingsChart()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserDistributionPieChart() {
    return StreamBuilder<int>(
      stream: _getTotalUsers(),
      builder: (context, userSnapshot) {
        return StreamBuilder<int>(
          stream: _getTotalProviders(),
          builder: (context, providerSnapshot) {
            if (!userSnapshot.hasData || !providerSnapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            int users = userSnapshot.data ?? 0;
            int providers = providerSnapshot.data ?? 0;

            List<PieChartSectionData> sections = [
              PieChartSectionData(
                value: users.toDouble(),
                title: "Users",
                color: Colors.blue,
                radius: 50,
              ),
              PieChartSectionData(
                value: providers.toDouble(),
                title: "Providers",
                color: Colors.orange,
                radius: 50,
              ),
            ];

            return SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  borderData: FlBorderData(show: false),
                  centerSpaceRadius: 40,
                ),
              ),
            );
          },
        );
      },
    );
  }

  /*Widget _buildMonthlyBookingsBarChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No booking data available"));
        }

        Map<String, int> monthlyData = {};
        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('eventDate')) {
            DateTime bookingDate = DateTime.parse(data['eventDate']);
            String monthYear = DateFormat('MMM yyyy').format(bookingDate);
            monthlyData[monthYear] = (monthlyData[monthYear] ?? 0) + 1;
          }
        }

        List<BarChartGroupData> bars = monthlyData.entries.toList().asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(toY: entry.value.value.toDouble(), gradient: LinearGradient(colors: [Colors.blue, Colors.lightBlueAccent])),
            ],
          );
        }).toList();

        return SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              barGroups: bars,
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(show: true),
            ),
          ),
        );
      },
    );
  }*/

  Widget _buildMonthlyBookingsBarChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No booking data available"));
        }

        Map<String, int> monthlyData = {};
        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('eventDate')) {
            DateTime bookingDate = DateTime.parse(data['eventDate']);
            String monthYear = DateFormat('MMM yyyy').format(bookingDate);
            monthlyData[monthYear] = (monthlyData[monthYear] ?? 0) + 1;
          }
        }

        List<String> monthLabels = monthlyData.keys.toList();
        List<BarChartGroupData> bars = monthLabels.asMap().entries.map((entry) {
          int index = entry.key;
          String monthName = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: monthlyData[monthName]!.toDouble(),
                gradient: LinearGradient(colors: [Colors.blue, Colors.lightBlueAccent]),
              ),
            ],
          );
        }).toList();

        return SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              barGroups: bars,
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index >= 0 && index < monthLabels.length) {
                        return Text(monthLabels[index], style: TextStyle(fontSize: 12));
                      }
                      return Text('');
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, IconData icon, Color color, Stream<num> stream, {bool isCurrency = false}) {
    return StreamBuilder<num>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Card(
            elevation: 4,
            color: color,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(icon, size: 30, color: Colors.white),
                  SizedBox(height: 10),
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 10),
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          );
        }

        String value = isCurrency ? "₹${snapshot.data?.toStringAsFixed(2) ?? "0.00"}" : snapshot.data?.toString() ?? "0";
        return Card(
          elevation: 4,
          color: color,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(icon, size: 30, color: Colors.white),
                SizedBox(height: 10),
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 10),
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingsChart() {
    DateTime now = DateTime.now();
    DateTime startDate;

    if (selectedFilter == "This Week") {
      startDate = now.subtract(Duration(days: now.weekday - 1));
    } else if (selectedFilter == "Last Week") {
      startDate = now.subtract(Duration(days: now.weekday + 6));
    } else if (selectedFilter == "This Month") {
      startDate = DateTime(now.year, now.month, 1);
    } else if (selectedFilter == "Last Month") {
      startDate = DateTime(now.year, now.month - 1, 1);
    } else {
      startDate = DateTime(now.year, 1, 1);
    }

    print("Fetching bookings from: \${startDate.toUtc()} to \${now.toUtc()}");

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No bookings available for \$selectedFilter"));
        }

        print("Total filtered bookings: \${snapshot.data!.docs.length}");

        Map<String, int> bookingsPerDay = {};
        DateFormat dateFormat = DateFormat('yyyy-MM-dd'); // Adjust format if needed

        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('eventDate')) {
            try {
              DateTime bookingDate = dateFormat.parse(data['eventDate']);
              print("Booking found on: \$bookingDate");
              if (bookingDate.isAfter(startDate) && bookingDate.isBefore(now)) {
                String dateStr = dateFormat.format(bookingDate);
                bookingsPerDay[dateStr] = (bookingsPerDay[dateStr] ?? 0) + 1;
              }
            } catch (e) {
              print("Error parsing date: \${data['eventDate']} - \${e.toString()}");
            }
          }
        }

        List<FlSpot> spots = bookingsPerDay.entries.toList().asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
        }).toList();

        return Card(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text("Bookings Over $selectedFilter", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          gradient: LinearGradient(colors: [Colors.blue, Colors.blueAccent]),
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}