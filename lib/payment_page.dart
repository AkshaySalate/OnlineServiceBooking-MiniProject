import 'package:flutter/material.dart';

class PaymentPage extends StatelessWidget {
  final double amount = 500;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Payment")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Total Amount: ₹$amount", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle payment logic
              },
              child: Text("Pay Now"),
            ),
          ],
        ),
      ),
    );
  }
}
