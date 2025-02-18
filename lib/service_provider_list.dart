import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme.dart';

class ServiceProviderList extends StatefulWidget {
  final String serviceCategoryDocId;
  final String iconUrl;

  const ServiceProviderList({
    Key? key,
    required this.serviceCategoryDocId,
    required this.iconUrl,
  }) : super(key: key);

  @override
  _ServiceProviderListState createState() => _ServiceProviderListState();
}

class _ServiceProviderListState extends State<ServiceProviderList> {
  String? selectedProviderId;

  void selectProvider(String providerId) {
    setState(() {
      selectedProviderId = selectedProviderId == providerId ? null : providerId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      //appBar: AppBar(
        //title: Text("Service Providers", style: theme.textTheme.titleLarge),
        //backgroundColor: AppTheme.gradientAppBar('Service Providers'),
      //),
      appBar: AppTheme.gradientAppBar('Servie Providers'),// Call the gradientAppBar function
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: AppTheme.gradientBackground,
          ),

          // Floating Icons
          ...AppTheme.floatingIcons(context),

          //list of service providers
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("service_providers")
                .where("serviceCategory", isEqualTo: widget.serviceCategoryDocId)
                .where("availability", isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}", style: theme.textTheme.bodyMedium));
              }
              if (snapshot.data!.docs.isEmpty) {
                return Center(child: Text("No service providers found for this category.", style: theme.textTheme.bodyMedium));
              }
              return ListView(
                padding: EdgeInsets.all(16),
                children: snapshot.data!.docs.map((doc) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  String providerId = doc.id;
                  bool isSelected = selectedProviderId == providerId;

                  return GestureDetector(
                    onTap: () => selectProvider(providerId),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        //color: isSelected ? theme.primaryColorLight : theme.cardColor,
                        color: Colors.grey.shade300.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected ? theme.primaryColor : Colors.grey.shade500,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(widget.iconUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Name: ${data['name'] ?? ''}",
                                  //style: theme.textTheme.titleLarge?.copyWith(fontSize: 18)),
                                  style: AppTheme.cardTitleTextStyle()),
                                SizedBox(height: 8),
                                Text("Experience: ${data['experience'] ?? ''}",
                                  //style: theme.textTheme.bodyMedium),
                                  style: AppTheme.fullDescriptionTextStyle()),
                                SizedBox(height: 8),
                                Text("Email: ${data['email'] ?? ''}", /*style: theme.textTheme.bodyMedium,*/ style: AppTheme.fullDescriptionTextStyle(),),
                                SizedBox(height: 8),
                                Text("Phone: ${data['phone'] ?? ''}", /*style: theme.textTheme.bodyMedium*/style: AppTheme.priceRangeTextStyle(),),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          // Confirm button (hidden initially, slides in when a provider is selected)
          AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: selectedProviderId != null ? 10 : -60,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                // Future functionality for confirm booking
              },
              child: Text("Confirm", style: theme.textTheme.titleLarge?.copyWith(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF8CB20),
                padding: EdgeInsets.symmetric(vertical: 15),
                textStyle: theme.textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
