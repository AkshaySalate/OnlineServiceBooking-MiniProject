import 'package:flutter/material.dart';

class ReviewsPage extends StatelessWidget {
  final List<Map<String, dynamic>> reviews = [
    {"user": "Alice", "rating": 5, "comment": "Great service!"},
    {"user": "Bob", "rating": 4, "comment": "Good but late"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reviews")),
      body: ListView.builder(
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text("${reviews[index]['user']} - ${reviews[index]['rating']} ⭐"),
            subtitle: Text(reviews[index]['comment']),
          );
        },
      ),
    );
  }
}
