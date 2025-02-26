import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile_page.dart';
import 'shared_footer.dart';
import 'package:online_service_booking/theme.dart';
import 'package:online_service_booking/login_signup.dart';

class ProfilePage extends StatelessWidget {
  final String customerId;

  ProfilePage({required this.customerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTheme.gradientAppBar('Profile'),
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: AppTheme.gradientBackground,
          ),

          // Floating Icons
          ...AppTheme.floatingIcons(context),
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection("users").doc(customerId).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(child: Text("Customer data not found.", style: TextStyle(color: Colors.white) ));
              }

              var customerData = snapshot.data!.data() as Map<String, dynamic>;

              return Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          double avatarSize = constraints.maxWidth * 0.2;
                          return CircleAvatar(
                            radius: avatarSize,
                            backgroundImage: customerData['avatarUrl'] != null
                                ? NetworkImage(customerData['avatarUrl'])
                                : AssetImage("assets/default_avatar.png") as ImageProvider,
                          );
                        },
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    Text("Name: ${customerData['name']}", style: TextStyle(fontSize: 18.0, color: Colors.white)),
                    SizedBox(height: 10),
                    Text("Email: ${customerData['email']}", style: TextStyle(fontSize: 18.0, color: Colors.white)),
                    SizedBox(height: 10),
                    Text("Phone: ${customerData['phone']}", style: TextStyle(fontSize: 18.0, color: Colors.white)),
                    SizedBox(height: 10),
                    Text("Address: ${customerData['address']}", style: TextStyle(fontSize: 18.0, color: Colors.white)),
                    SizedBox(height: 10),
                    Text("DOB: ${customerData['dob']}", style: TextStyle(fontSize: 18.0, color: Colors.white)),
                    // Buttons Row (Edit & Logout)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Edit Profile Button
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfilePage(customerId: customerId),
                              ),
                            );
                          },
                          icon: Icon(Icons.edit, color: Colors.white),
                          label: Text("Edit Profile", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),

                        // Logout Button
                        ElevatedButton.icon(
                          onPressed: () async {
                            //await FirebaseAuth.instance.signOut();
                            //Navigator.pushReplacementNamed(context, '/Login');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginSignupPage(),
                              ),
                            );
                          },
                          icon: Icon(Icons.logout, color: Colors.white),
                          label: Text("Logout", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: SharedFooter(customerId: customerId, currentIndex: 1),
    );
  }
}
