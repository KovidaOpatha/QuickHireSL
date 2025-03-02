import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CommunityScreen extends StatefulWidget {
  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _postController = TextEditingController();
  List<Map<String, dynamic>> posts = [];

  final String apiUrl = 'http://localhost:5001/community/posts';

  @override
  void initState() {
    super.initState();
    fetchChats();
  }

  Future<void> fetchChats() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          posts = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      }
    } catch (e) {
      print("Error fetching chats: $e");
    }
  }

  Future<void> saveChat(Map<String, dynamic> chat) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(chat),
      );
      if (response.statusCode == 201) {
        print("Chat saved successfully: ${response.body}");
        fetchChats(); // Refresh chats after saving
      } else {
        print("Failed to save chat: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error saving chat: $e");
    }
  }

  void addPost(String text) {
    final String currentTime =
        DateTime.now().toIso8601String(); // Save in ISO format
    final newChat = {
      "user": "You",
      "avatar": "assets/avatar.png",
      "message": text,
      "time": currentTime,
      "replies": [],
      "reactions": {"likes": 0, "likedBy": []},
    };

    saveChat(newChat); // Save chat to the database
    _postController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2C2F38),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Color(0xFF2C2F38),
          elevation: 0,
          title: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              "Community",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 32,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return _buildPost(posts[index]);
              },
            ),
          ),
          _buildPostInput(),
        ],
      ),
    );
  }

  Widget _buildPost(Map<String, dynamic> post) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.teal[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: AssetImage(post['avatar']),
            radius: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post['user'],
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(post['message']),
                Text(
                  post['time'], // Display the time
                  style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostInput() {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _postController,
              decoration: InputDecoration(
                hintText: "What would you like to share today?",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          IconButton(
            icon: Icon(Icons.send, color: Colors.white),
            onPressed: () {
              if (_postController.text.trim().isNotEmpty) {
                addPost(_postController.text.trim());
              }
            },
          ),
        ],
      ),
    );
  }
}
