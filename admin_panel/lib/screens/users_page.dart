import 'dart:convert';
import 'dart:io' show File;
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

class UsersPage extends StatefulWidget {
  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  List<DocumentSnapshot> users = [];
  List<String> selectedUsers = [];
  bool isLoading = false;
  bool hasMore = true;
  DocumentSnapshot? lastDocument;
  final int perPage = 10;
  String selectedRoleFilter = "All";

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    if (!hasMore || isLoading) return;
    setState(() => isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('users')
        .orderBy('name')
        .limit(perPage);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument!);
    }

    QuerySnapshot querySnapshot = await query.get();
    if (querySnapshot.docs.isNotEmpty) {
      lastDocument = querySnapshot.docs.last;
      users.addAll(querySnapshot.docs);
    } else {
      hasMore = false;
    }

    setState(() => isLoading = false);
  }

  void _exportUsers() async {
    List<List<String>> csvData = [
      ["Name", "Email", "Role"]
    ];

    for (var user in users) {
      csvData.add([user['name'], user['email'], user['role'] ?? 'User']);
    }

    String csv = const ListToCsvConverter().convert(csvData);

    if (kIsWeb) {
      // Flutter Web: Use `html` package to download file
      final bytes = utf8.encode(csv);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "users.csv")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Mobile/Desktop: Use `path_provider`
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/users.csv');
      await file.writeAsString(csv);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Exported to ${file.path}")),
      );
    }
  }

  void _bulkDelete() {
    for (String userId in selectedUsers) {
      FirebaseFirestore.instance.collection('users').doc(userId).delete();
    }
    setState(() {
      users.removeWhere((user) => selectedUsers.contains(user.id));
      selectedUsers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Users"),
        actions: [
          IconButton(icon: Icon(Icons.download), onPressed: _exportUsers),
          if (selectedUsers.isNotEmpty)
            IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: _bulkDelete),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search by name or email...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                SizedBox(width: 10),
                DropdownButton(
                  value: selectedRoleFilter,
                  items: ["All", "User", "Admin", "Service Provider"].map((role) {
                    return DropdownMenuItem(value: role, child: Text(role));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRoleFilter = value.toString();
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: users.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == users.length) {
            _fetchUsers();
            return Center(child: CircularProgressIndicator());
          }

          var user = users[index];
          var name = user['name'] ?? 'No Name';
          var email = user['email'] ?? 'No Email';
          var role = user['role'] ?? 'User';

          if (!name.toLowerCase().contains(searchQuery) && !email.toLowerCase().contains(searchQuery)) {
            return SizedBox.shrink();
          }
          if (selectedRoleFilter != "All" && role != selectedRoleFilter) {
            return SizedBox.shrink();
          }

          return Card(
            elevation: 2,
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(name[0].toUpperCase()),
                backgroundColor: Colors.blueAccent,
              ),
              title: Text(name),
              subtitle: Text(email),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: selectedUsers.contains(user.id),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          selectedUsers.add(user.id);
                        } else {
                          selectedUsers.remove(user.id);
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
