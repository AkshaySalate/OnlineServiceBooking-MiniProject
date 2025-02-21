import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_service_booking/user/shared_footer.dart';
import 'dart:math';
import 'dart:ui';
import 'service_provider_list.dart';
import '../theme.dart';
import 'shared_footer.dart';

class HomePage extends StatefulWidget {
  final String customerId;

  HomePage({required this.customerId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Random random = Random();

  // List of icons to choose from
  final List<IconData> iconList = [
    Icons.local_florist,
    Icons.eco,
    Icons.ac_unit,
    Icons.local_florist_sharp,
    //Icons.star,
    //Icons.favorite,
    //Icons.cloud,
  ];

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    List<Widget> generateIcons() {
      return [
        Positioned(
          top: screenHeight * 0.05,
          left: screenWidth * 0.08,
          child: Icon(Icons.local_florist, color: Colors.red.shade200, size: screenWidth * 0.17),
        ),
        Positioned(
          top: screenHeight * 0.10,
          right: screenWidth * 0.12,
          child: Icon(Icons.eco, color: Colors.red.shade200, size: screenWidth * 0.10),
        ),
        Positioned(
          top: screenHeight * 0.22,
          left: screenWidth * 0.25,
          child: Icon(Icons.eco, color: Colors.red.shade200, size: screenWidth * 0.08),
        ),
        Positioned(
          top: screenHeight * 0.25,
          right: screenWidth * 0.15,
          child: Icon(Icons.local_florist_sharp, color: Colors.red.shade200, size: screenWidth * 0.19),
        ),
        Positioned(
          bottom: screenHeight * 0.12,
          left: screenWidth * 0.35,
          child: Icon(Icons.local_florist, color: Colors.red.shade200, size: screenWidth * 0.20),
        ),
        Positioned(
          bottom: screenHeight * 0.12,
          right: screenWidth * 0.10,
          child: Icon(Icons.eco, color: Colors.red.shade200, size: screenWidth * 0.08),
        ),
        Positioned(
          bottom: screenHeight * 0.25,
          left: screenWidth * 0.05,
          child: Icon(Icons.local_florist, color: Colors.red.shade200, size: screenWidth * 0.07),
        ),
        Positioned(
          bottom: screenHeight * 0.27,
          right: screenWidth * 0.10,
          child: Icon(Icons.local_florist, color: Colors.red.shade200, size: screenWidth * 0.2),
        ),
        Positioned(
          top: screenHeight * 0.40,
          left: screenWidth * 0.50,
          child: Icon(Icons.eco, color: Colors.red.shade200, size: screenWidth * 0.09),
        ),
        Positioned(
          bottom: screenHeight * 0.40,
          left: screenWidth * 0.150,
          child: Icon(Icons.eco, color: Colors.red.shade200, size: screenWidth * 0.25),
        ),
      ];
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("Customer Home", style: TextStyle(color: Colors.white),),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.5,
              colors: [
                Colors.red.shade900,
                Colors.red.shade900,
                Colors.red.shade900,
                Colors.red.shade900,
              ],
              stops: [0.01, 0.4, 0.7, 1.0],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.5,
            colors: [
              Colors.red.shade300,
              Colors.red.shade500,
              Colors.red.shade700,
              Colors.red.shade900,
            ],
            stops: [0.01, 0.4, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            ...generateIcons(),
            FutureBuilder<DocumentSnapshot>(
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
                        Text("Customer Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 8),
                        Text("Name: $name", style: TextStyle(fontSize: 16, color: Colors.white)),
                        Text("Email: $email", style: TextStyle(fontSize: 16, color: Colors.white)),
                        Text("Phone: $phone", style: TextStyle(fontSize: 16, color: Colors.white)),
                        Divider(thickness: 2, height: 30),
                        Text("Available Services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: services.length,
                              itemBuilder: (context, index) {
                                var serviceData = services[index].data() as Map<String, dynamic>;
                                return ServiceCard(
                                  service: serviceData,
                                  docId: services[index].id,
                                );
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
          ],
        ),
      ),
      bottomNavigationBar: SharedFooter(customerId: widget.customerId, currentIndex: 0,), // Add footer here
    );
  }
}

class ServiceCard extends StatefulWidget {
  final Map<String, dynamic> service;
  final String docId; // Firestore document id for this service


  ServiceCard({required this.service, required this.docId});

  @override
  _ServiceCardState createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(cardTheme: AppTheme.cardTheme()),
      child: Card(
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
                      widget.service['serviceCategory'],
                      /*style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(1.5, 1.5),
                            blurRadius: 5.0,
                            color: Colors.black.withOpacity(0.7),
                          ),
                        ],
                      ),*/
                      style: AppTheme.cardTitleTextStyle(),
                    ),
                    SizedBox(height: 5),
                    Text(
                      widget.service['description'],
                      /*style: TextStyle(
                        fontSize: 14, color: Colors.grey[300],
                        shadows: [
                          Shadow(
                            offset: Offset(1.5, 1.5),
                            blurRadius: 7.0,
                            color: Colors.black,
                          ),
                        ],
                      ),*/
                      style: AppTheme.cardDescriptionTextStyle(),
                    ),
                    if (isExpanded) ...[
                      SizedBox(height: 5),
                      Text(
                        widget.service['fullDescription'],
                        /*style: TextStyle(
                          fontSize: 14, color: Colors.grey[350],
                          shadows: [
                            Shadow(
                              offset: Offset(0.5, 1.5),
                              blurRadius: 7.0,
                              color: Colors.black,
                            ),
                          ],
                        ),*/
                        style: AppTheme.fullDescriptionTextStyle(),
                      ),
                    ],
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "₹${widget.service['priceRange']}",
                          /*style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green,
                            shadows: [
                              Shadow(
                                offset: Offset(0.1, 0.1),
                                blurRadius: 9.0,
                                color: Colors.black.withOpacity(0.7),
                              ),
                            ],
                          ),*/
                          style: AppTheme.priceRangeTextStyle(),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  isExpanded = !isExpanded;
                                });
                              },

                              child: Text(isExpanded ? "Less" : "More", style: TextStyle(
                                shadows: [
                                  Shadow(
                                    offset: Offset(0.1, 0.1),
                                    blurRadius: 3.0,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ],
                              ),),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // When the Book button is pressed,
                                // navigate to the ServiceProviderList page,
                                // passing the service document id and icon URL.
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ServiceProviderList(
                                      serviceCategoryDocId: widget.docId,
                                      iconUrl: widget.service['icon'],
                                    ),
                                  ),
                                );
                              },
                              style: AppTheme.cardButtonStyle(),
                              child: Text("Book"),
                              /*style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFF8CB20)
                              ),*/
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
      ),
    );
  }
}
