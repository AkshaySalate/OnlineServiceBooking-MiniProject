import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:online_service_booking/theme.dart';

class ChatScreen extends StatefulWidget {
  final String providerId;
  final String customerId;

  ChatScreen({required this.providerId, required this.customerId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String getChatRoomId() {
    List<String> ids = [widget.providerId, widget.customerId];
    ids.sort();
    return ids.join("_");
  }

  void sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      _firestore.collection("chats").doc(getChatRoomId()).collection("messages").add({
        "sender": _auth.currentUser!.uid,
        "message": _messageController.text.trim(),
        "timestamp": FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    }
  }

  void clearChat() async {
    QuerySnapshot messages = await _firestore.collection("chats").doc(getChatRoomId()).collection("messages").get();
    for (var doc in messages.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTheme.gradientAppBarWithIcon(
        "Chat",
        Icons.delete,
        Colors.white,
        clearChat,
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: Stack(
          children: [
            ...AppTheme.floatingIcons(context),
            Column(
              children: [
                Expanded(
                  child: StreamBuilder(
                    stream: _firestore
                        .collection("chats")
                        .doc(getChatRoomId())
                        .collection("messages")
                        .orderBy("timestamp", descending: true)
                        .snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }
                      return ListView.builder(
                        reverse: true,
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var message = snapshot.data!.docs[index];
                          bool isMe = message["sender"] == _auth.currentUser!.uid;
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.blue.shade700 : Colors.grey.shade700,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                message["message"],
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: "Type a message",
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                            border: AppTheme.lightTheme.inputDecorationTheme.enabledBorder,
                            focusedBorder: AppTheme.lightTheme.inputDecorationTheme.focusedBorder,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send, color: Colors.yellow),
                        onPressed: sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
