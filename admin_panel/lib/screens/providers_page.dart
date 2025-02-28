import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'dart:html' as html;

class ProvidersPage extends StatefulWidget {
  @override
  _ProvidersPageState createState() => _ProvidersPageState();
}

class _ProvidersPageState extends State<ProvidersPage> {
  TextEditingController searchController = TextEditingController();
  List<DocumentSnapshot> providers = [];
  bool isLoading = false;
  bool allLoaded = false;
  int limit = 10;
  String searchQuery = "";
  bool showOnlyApproved = false;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
    fetchProviders();
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = searchController.text;
      providers.clear();
      allLoaded = false;
    });
    fetchProviders();
  }

  void fetchProviders() async {
    if (isLoading || allLoaded) return;
    setState(() => isLoading = true);

    Query query = FirebaseFirestore.instance.collection('service_providers')
        .orderBy('name')
        .limit(limit);

    if (searchQuery.isNotEmpty) {
      query = query.where('name', isGreaterThanOrEqualTo: searchQuery).where('name', isLessThan: searchQuery + 'z');
    }

    if (showOnlyApproved) {
      query = query.where('approved', isEqualTo: true);
    }

    QuerySnapshot querySnapshot = await query.get();
    if (querySnapshot.docs.length < limit) {
      allLoaded = true;
    }

    setState(() {
      providers.addAll(querySnapshot.docs);
      isLoading = false;
    });
  }

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

  void _exportToCsv() {
    List<List<dynamic>> rows = [
      ["Name", "Phone", "Approved"]
    ];

    for (var provider in providers) {
      rows.add([
        provider['name'],
        provider['phone'],
        provider['approved'] ? "Yes" : "No"
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)..setAttribute("download", "providers.csv")..click();
    html.Url.revokeObjectUrl(url);
  }

  void _loadAll() {
    setState(() {
      limit = 1000;
      allLoaded = false;
      providers.clear();
    });
    fetchProviders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Service Providers"),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _exportToCsv,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: "Search by name or phone",
              ),
            ),
          ),
          SwitchListTile(
            title: Text("Show only approved"),
            value: showOnlyApproved,
            onChanged: (value) {
              setState(() {
                showOnlyApproved = value;
                providers.clear();
                allLoaded = false;
              });
              fetchProviders();
            },
          ),
          Expanded(
            child: ListView.builder(
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
                        value: provider['approved'] ?? false,
                        onChanged: (bool value) {
                          FirebaseFirestore.instance.collection('service_providers').doc(provider.id).update({'approved': value});
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
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: fetchProviders,
                child: Text("Load More"),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: _loadAll,
                child: Text("Load All"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
