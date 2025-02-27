import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderReviewsPage extends StatelessWidget {
  final String providerId;

  ProviderReviewsPage({required this.providerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Reviews")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("reviews")
            .where("providerID", isEqualTo: providerId)
            .snapshots(),
        builder: (context, snapshot) {
          // 🔹 Handle Errors in Firestore Stream
          if (snapshot.hasError) {
            return Center(child: Text("Error loading reviews."));
          }

          // 🔹 Show Loading Indicator
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // 🔹 If No Reviews Found
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No reviews yet."));
          }

          // 🔹 Sort reviews manually by timestamp (Descending)
          List<QueryDocumentSnapshot> sortedReviews = snapshot.data!.docs;
          sortedReviews.sort((a, b) {
            var aTime = (a["timestamp"] as Timestamp?)?.toDate() ?? DateTime(2000);
            var bTime = (b["timestamp"] as Timestamp?)?.toDate() ?? DateTime(2000);
            return bTime.compareTo(aTime); // Newest first
          });

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;

              // ✅ Check if timestamp exists
              String reviewDate = "Unknown Date";
              if (data.containsKey("timestamp") && data["timestamp"] != null) {
                try {
                  reviewDate = (data["timestamp"] as Timestamp).toDate().toString().split(" ")[0];
                } catch (e) {
                  print("⚠️ Error converting timestamp: $e");
                }
              }

              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  leading: Icon(Icons.star, color: Colors.orange),
                  title: Text("⭐ ${data["rating"]}"),
                  subtitle: Text(data["comment"]),
                  trailing: Text(
                    reviewDate,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
