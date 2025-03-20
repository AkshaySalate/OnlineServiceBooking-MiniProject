import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:html' as html; // For Web CSV download
import 'dart:convert';

class ServicesPage extends StatefulWidget {
  @override
  _ServicesPageState createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  void _editService(DocumentSnapshot service) {
    TextEditingController descriptionController = TextEditingController(text: service["description"]);
    TextEditingController fullDescriptionController = TextEditingController(text: service["fullDescription"]);
    TextEditingController categoryController = TextEditingController(text: service["serviceCategory"]);
    TextEditingController priceController = TextEditingController(text: service["priceRange"].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Service"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: "Description"),
              ),
              TextField(
                controller: fullDescriptionController,
                decoration: InputDecoration(labelText: "Full Description"),
              ),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(labelText: "Category"),
              ),
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: "Price Range"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('services').doc(service.id).update({
                  "description": descriptionController.text,
                  "fullDescription": fullDescriptionController.text,
                  "serviceCategory": categoryController.text,
                  "priceRange": int.tryParse(priceController.text) ?? 0,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Service updated successfully")));
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _downloadCSV() async {
    List<List<dynamic>> rows = [];
    rows.add(["Service ID", "Description", "Full Description", "Category", "Price Range", "Icon URL"]);

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('services').get();
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        rows.add([
          doc.id,
          data["description"] ?? "N/A",
          data["fullDescription"] ?? "N/A",
          data["serviceCategory"] ?? "N/A",
          data["priceRange"]?.toString() ?? "N/A",
          data["icon"] ?? "N/A",
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);

      if (kIsWeb) {
        final bytes = utf8.encode(csvData);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "services.csv")
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        if (await Permission.storage.request().isGranted) {
          Directory? directory = await getApplicationDocumentsDirectory();
          String path = "${directory.path}/services.csv";
          File file = File(path);
          await file.writeAsString(csvData);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("CSV downloaded to $path")));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error generating CSV: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Services"),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _downloadCSV,
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('services').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No services available"));
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var service = snapshot.data!.docs[index];
              var data = service.data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: data["icon"] != null
                      ? Image.network(data["icon"], width: 50, height: 50, errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image))
                      : Icon(Icons.image_not_supported),
                  title: Text(data["description"] ?? "No Description", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data["fullDescription"] ?? "No details available"),
                      Text("Category: ${data["serviceCategory"] ?? "N/A"}"),
                      Text("Price: ₹${data["priceRange"]?.toString() ?? "N/A"}"),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 10,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editService(service),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => FirebaseFirestore.instance.collection('services').doc(service.id).delete(),
                      ),
                    ],
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
