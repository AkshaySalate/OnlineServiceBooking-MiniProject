import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'dart:math';

import 'package:flutter/widgets.dart';

class ServiceProviderHomePage extends StatefulWidget {
  final String providerId;

  ServiceProviderHomePage({required this.providerId});

  @override
  _ServiceProviderHomePageState createState() => _ServiceProviderHomePageState();
}

class _ServiceProviderHomePageState extends State<ServiceProviderHomePage> {
  final Random random = Random();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController servicesController = TextEditingController();

  double latitude = 0.0;
  double longitude = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchServiceProviderDetails();
  }

  Future<void> fetchServiceProviderDetails() async {
    try {
      DocumentSnapshot doc = await _firestore.collection("service_providers").doc(widget.providerId).get();
      if (doc.exists) {
        setState(() {
          nameController.text = doc["name"];
          emailController.text = doc["email"];
          phoneController.text = doc["phone"];
          servicesController.text = (doc["services_offered"] as List).join(", ");
          latitude = doc["location"].latitude;
          longitude = doc["location"].longitude;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching provider details: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> updateServiceProviderDetails() async {
    try {
      List<String> updatedServices = servicesController.text.split(',').map((s) => s.trim()).toList();

      await _firestore.collection("service_providers").doc(widget.providerId).update({
        "name": nameController.text,
        "email": emailController.text,
        "phone": phoneController.text,
        "services_offered": updatedServices,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profile updated successfully!")));
    } catch (e) {
      print("Error updating provider details: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update profile.")));
    }
  }

  List<Widget> generateIcons(double screenWidth, double screenHeight) {
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

  Future<void> addServiceDetails() async {
    List<Map<String, dynamic>> services = [
      /*{
        "serviceCategory": "Caterers",
        "description": "Food & beverage providers for events",
        "fullDescription": "We provide high-quality catering services for all types of events, from weddings to corporate gatherings. Our services include buffet-style catering, plated meals, and custom menus to suit your needs.",
        "priceRange": "2000-5000 INR",
        "icon": "https://cdn-icons-png.flaticon.com/512/13911/13911032.png"
      },
      {
        "serviceCategory": "Decorators",
        "description": "Balloon, floral, and theme decorations",
        "fullDescription": "Our decorators provide stunning visual setups for your events, including floral arrangements, balloon art, and themed décor to fit any occasion.",
        "priceRange": "3000-8000 INR",
        "icon": "https://cdn-icons-png.flaticon.com/512/2849/2849791.png"
      },
      {
        "serviceCategory": "Photographers",
        "description": "Capture special moments",
        "fullDescription": "Our professional photographers specialize in weddings, corporate events, and personal shoots, ensuring high-quality captured memories.",
        "priceRange": "8000-20000 INR",
        "icon": "https://cdn-icons-png.flaticon.com/512/2317/2317988.png"
      },
      {
        "serviceCategory": "Videographers",
        "description": "High-quality event videography",
        "fullDescription": "Our experienced videographers create cinematic event coverage, including weddings, parties, and corporate events.",
        "priceRange": "10000-25000 INR",
        "icon": "https://cdn-icons-png.flaticon.com/512/14797/14797394.png"
      },
      {
        "serviceCategory": "DJs",
        "description": "Music entertainment for parties",
        "fullDescription": "Our professional DJs provide top-tier music entertainment for all types of events with customized playlists.",
        "priceRange": "5000-15000 INR",
        "icon": "https://cdn-icons-png.flaticon.com/512/2564/2564946.png"
      },
      {
        "serviceCategory": "Music Bands",
        "description": "Live performances for events",
        "fullDescription": "We provide professional music bands for weddings, parties, and corporate events, ensuring unforgettable live performances.",
        "priceRange": "10000-25000 INR",
        "icon": "https://cdn-icons-png.flaticon.com/512/4472/4472592.png"
      },
      {
        "serviceCategory": "Event Hosts",
        "description": "Professional anchors for events",
        "fullDescription": "Experienced event hosts and emcees to guide your event smoothly, engage with guests, and ensure everything runs on time.",
        "priceRange": "4000-10000 INR",
        "icon": "https://cdn-icons-png.flaticon.com/512/5396/5396739.png"
      },
      {
        "serviceCategory": "Party Venues & Halls",
        "description": "Book locations for parties",
        "fullDescription": "Choose from a range of beautiful party venues and halls for any occasion, with customizable setups to meet your event’s needs.",
        "priceRange": "5000-20000 INR",
        "icon": "https://cdn-icons-png.flaticon.com/512/11881/11881141.png"
      },
      {
        "serviceCategory": "Makeup Artists",
        "description": "Makeup services for weddings and events",
        "fullDescription": "Our skilled makeup artists offer professional makeup services for weddings, parties, and special occasions, ensuring you look your best.",
        "priceRange": "3000-8000 INR",
        "icon": "https://cdn-icons-png.flaticon.com/512/15654/15654277.png"
      },
      {
        "serviceCategory": "Transportation Services",
        "description": "Vehicles for transport (cars, buses, etc.)",
        "fullDescription": "Reliable and comfortable transportation services for events, including cars, buses, and limousines to take you to and from your destination.",
        "priceRange": "5000-20000 INR",
        "icon": "https://cdn-icons-png.flaticon.com/512/6837/6837238.png"
      },
      {
        "serviceCategory": "Security Services",
        "description": "Providing security for events",
        "fullDescription": "Our security services provide professional event security personnel to ensure your event is safe and secure at all times.",
        "priceRange": "5000-15000 INR",
        "icon": "https://cdn-icons-png.flaticon.com/512/1982/1982116.png"
      },
      {
        "serviceCategory": "Event Planners",
        "description": "Complete event management services",
        "fullDescription": "Our expert event planners can organize every detail of your event, from venue selection to coordination, ensuring a flawless experience.",
        "priceRange": "10000-50000 INR",
        "icon": "https://cdn-icons-png.flaticon.com/512/5775/5775370.png"
      },
      {
        "serviceCategory": "Lighting & Audio",
        "description": "Professional lighting and audio setups",
        "fullDescription": "Our lighting and audio services ensure your event is perfectly lit and the sound system is top-notch for every occasion.",
        "priceRange": "7000-20000 INR",
        "icon": "https://cdn-icons-png.flaticon.com/512/3174/3174373.png"
      },
      {
        "serviceCategory": "Clean-Up Services",
        "description": "Post-event cleaning services",
        "fullDescription": "Our clean-up services ensure that your venue is spotless after your event, including trash removal, cleaning floors, and more.",
        "priceRange": "3000-8000 INR",
        "icon": "https://cdn-icons-png.flaticon.com/512/9137/9137869.png"
      },
      {
        "serviceCategory": "Live Performers",
        "description": "Musicians, dancers, comedians for events",
        "fullDescription": "Hire live performers including musicians, dancers, and comedians to add fun and energy to your event.",
        "priceRange": "5000-20000 INR",
        "icon": "https://cdn-icons-png.flaticon.com/512/6452/6452060.png"
      },
      {
        "serviceCategory": "Invitation Designers",
        "description": "Personalized event invitation designs",
        "fullDescription": "Our designers create beautiful, customized event invitations that match your event’s theme and style.",
        "priceRange": "2000-8000 INR",
        "icon": "https://cdn-icons-png.flaticon.com/512/2276/2276411.png"
      },
      {
        "serviceCategory": "Photo Booths",
        "description": "For event photography entertainment",
        "fullDescription": "Rent a photo booth for your event, allowing guests to capture fun moments with personalized prints and digital photos.",
        "priceRange": "4000-12000 INR",
        "icon": "https://cdn-icons-png.flaticon.com/512/1921/1921838.png"
      },
      {
        "serviceCategory": "Rentals",
        "description": "Chairs, tables, tents, and other equipment rentals",
        "fullDescription": "Rent furniture and equipment for your event, including tables, chairs, tents, and more.",
        "priceRange": "1000-10000 INR",
        "icon": "https://cdn-icons-png.flaticon.com/512/4001/4001021.png"
      },
      {
        "serviceCategory": "Bartenders & Mixologists",
        "description": "Professional bartenders for events",
        "fullDescription": "Our experienced bartenders and mixologists can serve craft cocktails and manage the bar for your event.",
        "priceRange": "3000-10000 INR",
        "icon": "https://cdn-icons-png.flaticon.com/512/2405/2405478.png"
      },
      {
        "serviceCategory": "Wedding Planners",
        "description": "Full-service wedding event planning",
        "fullDescription": "Our wedding planners handle every detail of your big day, from planning to execution, ensuring your wedding is flawless.",
        "priceRange": "15000-50000 INR",
        "icon": "https://cdn-icons-png.flaticon.com/512/3074/3074322.png"
      },
      {
        "serviceCategory": "Party Favors",
        "description": "Personalized party gifts and favors",
        "fullDescription": "We offer a wide range of customized party favors, from small gifts to personalized keepsakes for your guests.",
        "priceRange": "500-3000 INR",
        "icon": "https://cdn-icons-png.flaticon.com/512/9592/9592247.png"
      },
      {
        "serviceCategory": "Childcare Services",
        "description": "Babysitting or entertainment for children at events",
        "fullDescription": "We provide childcare services to entertain children during events, including babysitting and fun activities.",
        "priceRange": "2000-8000 INR",
        "icon": "https://cdn-icons-png.freepik.com/512/2566/2566231.png"
      }*/
    ];

    try {
      for (var service in services) {
        await FirebaseFirestore.instance.collection("services").add(service);
      }
      print("Services added successfully!");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Services added successfully!")));
    } catch (e) {
      print("Error adding services: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to add services.")));
    }
  }


  final List<IconData> iconList = [
    Icons.local_florist,
    Icons.eco,
    Icons.ac_unit,
    Icons.local_florist_sharp,
  ];

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(title: Text("Service Provider Home", style: TextStyle(color: Colors.white)),
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
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Stack(
              children: [
                ...generateIcons(screenWidth, screenHeight),
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Edit Your Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 10),

                        // Name Field
                        TextField(controller: nameController, decoration: InputDecoration(labelText: "Name", labelStyle: TextStyle(color: Colors.white)),style: TextStyle(color: Colors.white),),
                        SizedBox(height: 10),

                        // Email Field
                        TextField(controller: emailController, decoration: InputDecoration(labelText: "Email", labelStyle: TextStyle(color: Colors.white)),style: TextStyle(color: Colors.white),),
                        SizedBox(height: 10),

                        // Phone Field
                        TextField(controller: phoneController, decoration: InputDecoration(labelText: "Phone", labelStyle: TextStyle(color: Colors.white)),style: TextStyle(color: Colors.white),),
                        SizedBox(height: 10),

                        // Services Offered Field
                        TextField(controller: servicesController, decoration: InputDecoration(labelText: "Services Offered (comma separated)", labelStyle: TextStyle(color: Colors.white)),style: TextStyle(color: Colors.white),),
                        SizedBox(height: 10),

                        // Location
                        Text("Location: ($latitude, $longitude)", style: TextStyle(fontSize: 16, color: Colors.white)),

                        SizedBox(height: 20),

                        // Save Button
                        ElevatedButton(
                          onPressed: updateServiceProviderDetails,
                          child: Text("Save Changes"),
                        ),
                        ElevatedButton(
                          onPressed: addServiceDetails,
                          child: Icon(Icons.add),
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
