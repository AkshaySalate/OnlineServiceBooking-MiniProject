import 'package:flutter/material.dart';

class ProviderProfilePage extends StatelessWidget {
  final String providerName = "John Doe";
  final String serviceType = "Plumbing";
  final double rating = 4.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(providerName)),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(providerName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(serviceType, style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text("Rating: $rating ⭐"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to booking page
              },
              child: Text("Book Service"),
            ),
          ],
        ),
      ),
    );
  }
}
