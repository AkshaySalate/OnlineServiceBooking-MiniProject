import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  final String customerId;

  HomePage({required this.customerId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Customer Home")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection("users").doc(widget.customerId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Error: Customer data not found."));
          }

          var customerData = snapshot.data!;
          String name = customerData.get('name');
          String email = customerData.get('email');
          String phone = customerData.get('phone');

          return Padding(
            padding: EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Customer Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text("Name: $name", style: TextStyle(fontSize: 16)),
                  Text("Email: $email", style: TextStyle(fontSize: 16)),
                  Text("Phone: $phone", style: TextStyle(fontSize: 16)),
                  Divider(thickness: 2, height: 30),
                  Text("Available Services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  FutureBuilder<QuerySnapshot>(
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
                        shrinkWrap: true,  // Ensures list view only takes up space for its content
                        physics: NeverScrollableScrollPhysics(),  // Prevents scroll conflicts with parent scroll view
                        itemCount: services.length,
                        itemBuilder: (context, index) {
                          var service = services[index].data() as Map<String, dynamic>;
                          return ServiceCard(service: service);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ServiceCard extends StatefulWidget {
  final Map<String, dynamic> service;

  ServiceCard({required this.service});

  @override
  _ServiceCardState createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(widget.service['icon']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.service['name'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    widget.service['short_description'],
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  if (isExpanded) ...[
                    SizedBox(height: 5),
                    Text(
                      widget.service['full_description'],
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "₹${widget.service['price']}",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                isExpanded = !isExpanded;
                              });
                            },
                            child: Text(isExpanded ? "Less" : "More"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to booking page
                            },
                            child: Text("Book Now"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
