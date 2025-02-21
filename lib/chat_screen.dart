import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

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
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// **1️⃣ Send Message**
  void _sendMessage({String? imageUrl, String? videoUrl}) async {
    if (_messageController.text.trim().isEmpty && imageUrl == null && videoUrl == null) return;

    String chatId = widget.providerId + "_" + widget.customerId;
    await _firestore.collection("chats").doc(chatId).collection("messages").add({
      "senderId": widget.providerId,
      "receiverId": widget.customerId,
      "message": _messageController.text.trim(),
      "imageUrl": imageUrl ?? "",
      "videoUrl": videoUrl ?? "",
      "timestamp": FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  /// **📌 Pick Image and Upload**
  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File file = File(image.path);
      String imageUrl = await _uploadFile(file, "images");
      _sendMessage(imageUrl: imageUrl);
    }
  }

  /// **📌 Pick Video and Upload**
  Future<void> _pickAndUploadVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      File file = File(video.path);
      String videoUrl = await _uploadFile(file, "videos");
      _sendMessage(videoUrl: videoUrl);
    }
  }

  /// **📌 Upload File to Firebase Storage**
  Future<String> _uploadFile(File file, String folder) async {
    String fileName = "${widget.providerId}_${DateTime.now().millisecondsSinceEpoch}";
    TaskSnapshot snapshot = await _storage.ref("$folder/$fileName").putFile(file);
    return await snapshot.ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    String chatId = widget.providerId + "_" + widget.customerId;

    return Scaffold(
      appBar: AppBar(title: Text("Chat with Customer")),
      body: Column(
        children: [
          /// **2️⃣ Message List**
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection("chats")
                  .doc(chatId)
                  .collection("messages")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                return ListView(
                  reverse: true,
                  children: snapshot.data!.docs.map((message) {
                    bool isMe = message["senderId"] == widget.providerId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // If it's an image message, show the image
                            if (message["imageUrl"] != "")
                              Image.network(message["imageUrl"], height: 200, fit: BoxFit.cover),

                            // If it's a video message, show a video placeholder
                            if (message["videoUrl"] != "")
                              Icon(Icons.video_collection, color: Colors.white, size: 50),

                            // Otherwise, show the text message
                            if (message["message"] != "")
                              Text(message["message"], style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          /// **3️⃣ Message Input Field**
          /// **📌 Message Input Field with Image/Video Upload**
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.image),
                  onPressed: _pickAndUploadImage,
                ),
                IconButton(
                  icon: Icon(Icons.video_library),
                  onPressed: _pickAndUploadVideo,
                ),
                Expanded(child: TextField(controller: _messageController)),
                IconButton(icon: Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
