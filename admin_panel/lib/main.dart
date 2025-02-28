import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'firebase_options.dart';
import 'package:admin_panel/screens/auth_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(AdminPanelApp());
  } catch (e) {
    print("Firebase Init Error: $e");
  }
}

class AdminPanelApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Panel',
      theme: ThemeData.dark(),
      home: AuthCheck(),
    );
  }
}

/*class AuthCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?> (
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return AdminDashboard();
        }
        return LoginPage();
      },
    );
  }
}*/

/*class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String errorMessage = '';
  bool isNewAdmin = false;

  Future<void> checkAdminExists() async {
    final email = emailController.text.trim();

    final querySnapshot = await FirebaseFirestore.instance
        .collection('admins')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final adminDoc = querySnapshot.docs.first;

      // ✅ Correct condition check
      if (adminDoc.data()['passwordSet'] == true) {
        login(); // 🔥 Directly login if password is already set
      } else {
        setState(() {
          isNewAdmin = true;
        });
      }
    } else {
      setState(() {
        errorMessage = 'Admin account does not exist';
      });
    }
  }

  Future<void> setPassword() async {
    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim().isEmpty
          ? 'qwerty@1234567'  // Default password if empty
          : passwordController.text.trim();

      // ✅ Step 1: Fetch the correct admin document
      final querySnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          errorMessage = "Admin account not found!";
        });
        return;
      }

      final adminDocRef = querySnapshot.docs.first.reference; // ✅ Get the correct document reference

      // ✅ Step 2: Create a new FirebaseAuth user
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ✅ Step 3: Update Firestore after successful authentication
      await adminDocRef.update({'passwordSet': true});

      setState(() {
        isNewAdmin = false; // ✅ Reset state to prevent unnecessary password prompts
      });

      // ✅ Step 4: Automatically log in after setting the password
      login();
    } catch (e) {
      setState(() {
        errorMessage = 'Error setting password: ${e.toString()}';
      });
    }
  }


  Future<void> login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Invalid email or password';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Login")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 10),
            if (errorMessage.isNotEmpty)
              Text(errorMessage, style: TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: isNewAdmin ? setPassword : checkAdminExists,
              child: Text(isNewAdmin ? "Set Password" : "Login"),
            ),
          ],
        ),
      ),
    );
  }
}*/

/*class AdminDashboard extends StatefulWidget {
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
}*/

/*class UsersPage extends StatefulWidget {
  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  void _editUser(String userId, String name, String email) {
    TextEditingController nameController = TextEditingController(text: name);
    TextEditingController emailController = TextEditingController(text: email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit User"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
            TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('users').doc(userId).update({
                'name': nameController.text,
                'email': emailController.text,
              });
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Users")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          var users = snapshot.data!.docs;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              return ListTile(
                title: Text(user['name'] ?? 'No Name'),
                subtitle: Text(user['email'] ?? 'No Email'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: Icon(Icons.edit), onPressed: () => _editUser(user.id, user['name'], user['email'])),
                    IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => FirebaseFirestore.instance.collection('users').doc(user.id).delete()),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}*/

/*class ProvidersPage extends StatefulWidget {
  @override
  _ProvidersPageState createState() => _ProvidersPageState();
}

class _ProvidersPageState extends State<ProvidersPage> {
  void _editProvider(String providerId, String name, String phone) {
    TextEditingController nameController = TextEditingController(text: name);
    TextEditingController phoneController = TextEditingController(text: phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Provider"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
            TextField(controller: phoneController, decoration: InputDecoration(labelText: "Phone")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('service_providers').doc(providerId).update({
                'name': nameController.text,
                'phone': phoneController.text,
              });
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Service Providers")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('service_providers').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          var providers = snapshot.data!.docs;
          return ListView.builder(
            itemCount: providers.length,
            itemBuilder: (context, index) {
              var provider = providers[index];
              return ListTile(
                title: Text(provider['name'] ?? 'No Name'),
                subtitle: Text(provider['phone'] ?? 'No Phone'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: (provider.data() as Map<String, dynamic>).containsKey('approved')
                          ? provider['approved']
                          : false, // Default to false if field is missing
                      onChanged: (bool value) {
                        FirebaseFirestore.instance
                            .collection('service_providers')
                            .doc(provider.id)
                            .update({'approved': value});
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _editProvider(provider.id, provider['name'], provider['phone']),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => FirebaseFirestore.instance.collection('service_providers').doc(provider.id).delete(),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}*/

/*class BookingsPage extends StatelessWidget {
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
}*/

/*class EarningsPage extends StatefulWidget {
  @override
  _EarningsPageState createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  String selectedSort = "amount";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Earnings Report")),
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
                return ListView.builder(
                  itemCount: earnings.length,
                  itemBuilder: (context, index) {
                    var earning = earnings[index];
                    return ListTile(
                      title: Text("Provider ID: ${earning['providerID']}"),
                      subtitle: Text("Amount: \$${earning['amount']}"),
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
}*/