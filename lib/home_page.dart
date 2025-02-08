import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatelessWidget {
  final String customerId;

  HomePage({required this.customerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Customer Home")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection("users").doc(customerId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Error: Customer data not found."));
          }

          // Extract user details
          var customerData = snapshot.data!;
          String name = customerData.get('name');
          String email = customerData.get('email');
          String phone = customerData.get('phone');

          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Details
                Text("Customer Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("Name: $name", style: TextStyle(fontSize: 16)),
                Text("Email: $email", style: TextStyle(fontSize: 16)),
                Text("Phone: $phone", style: TextStyle(fontSize: 16)),

                // Divider
                Divider(thickness: 2, height: 30),

                // Available Services Section
                Text("Available Services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(
                  child: FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance.collection("services").get(),
                    builder: (context, serviceSnapshot) {
                      if (serviceSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (!serviceSnapshot.hasData || serviceSnapshot.data!.docs.isEmpty) {
                        return Center(child: Text("No services available."));
                      }

                      List<QueryDocumentSnapshot> services = serviceSnapshot.data!.docs;

                      return ListView.builder(
                        itemCount: services.length,
                        itemBuilder: (context, index) {
                          var service = services[index].data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(service['name']),
                            subtitle: Text("By ${service['provider']} - ₹${service['price']}"),
                            trailing: ElevatedButton(
                              onPressed: () {
                                // Navigate to booking page
                              },
                              child: Text("Book Now"),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
