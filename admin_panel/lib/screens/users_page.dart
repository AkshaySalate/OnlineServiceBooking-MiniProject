import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UsersPage extends StatefulWidget {
  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  List<DocumentSnapshot> users = [];
  bool isLoading = false;
  bool hasMore = true;
  DocumentSnapshot? lastDocument;
  final int perPage = 10;

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

  void _editUser(String userId, String name, String email, String role) {
    TextEditingController nameController = TextEditingController(text: name);
    TextEditingController emailController = TextEditingController(text: email);
    String selectedRole = role;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit User"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
            TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
            DropdownButtonFormField(
              value: selectedRole,
              onChanged: (value) {
                setState(() {
                  selectedRole = value.toString();
                });
              },
              items: ["User", "Admin", "Service Provider"].map((role) {
                return DropdownMenuItem(value: role, child: Text(role));
              }).toList(),
              decoration: InputDecoration(labelText: "Role"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('users').doc(userId).update({
                'name': nameController.text,
                'email': emailController.text,
                'role': selectedRole,
              });
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete User"),
        content: Text("Are you sure you want to delete this user?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('users').doc(userId).delete();
              setState(() {
                users.removeWhere((user) => user.id == userId);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Users"),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
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
        ),
      ),
      body: ListView.builder(
        itemCount: users.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == users.length) {
            _fetchUsers(); // Load more users when reaching the end
            return Center(child: CircularProgressIndicator());
          }

          var user = users[index];
          var name = user['name'] ?? 'No Name';
          var email = user['email'] ?? 'No Email';

          if (!name.toLowerCase().contains(searchQuery) && !email.toLowerCase().contains(searchQuery)) {
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
                  IconButton(icon: Icon(Icons.edit), onPressed: () => _editUser(user.id, name, email, user['role'] ?? 'User')),
                  IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(user.id)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
