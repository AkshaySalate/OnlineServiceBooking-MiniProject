import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProvidersPage extends StatefulWidget {
  @override
  _ProvidersPageState createState() => _ProvidersPageState();
}

class _ProvidersPageState extends State<ProvidersPage> {
  void _editProvider(String providerId, String name, String phone) {
    TextEditingController nameController = TextEditingController(text: name);
    TextEditingController phoneController = TextEditingController(text: phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Provider"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
            TextField(controller: phoneController, decoration: InputDecoration(labelText: "Phone")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('service_providers').doc(providerId).update({
                'name': nameController.text,
                'phone': phoneController.text,
              });
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Service Providers")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('service_providers').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          var providers = snapshot.data!.docs;
          return ListView.builder(
            itemCount: providers.length,
            itemBuilder: (context, index) {
              var provider = providers[index];
              return ListTile(
                title: Text(provider['name'] ?? 'No Name'),
                subtitle: Text(provider['phone'] ?? 'No Phone'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: (provider.data() as Map<String, dynamic>).containsKey('approved')
                          ? provider['approved']
                          : false, // Default to false if field is missing
                      onChanged: (bool value) {
                        FirebaseFirestore.instance
                            .collection('service_providers')
                            .doc(provider.id)
                            .update({'approved': value});
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _editProvider(provider.id, provider['name'], provider['phone']),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => FirebaseFirestore.instance.collection('service_providers').doc(provider.id).delete(),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}