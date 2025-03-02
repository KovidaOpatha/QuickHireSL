import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CommunityScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  CommunityScreen({this.onNavigateToTab});

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _postController = TextEditingController();
  List<Map<String, dynamic>> posts = [];

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    final response =
        await http.get(Uri.parse("http://localhost:5000/api/chats"));
    if (response.statusCode == 200) {
      setState(() {
        posts = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      });
    } else {
      print("Error fetching posts: ${response.statusCode}");
    }
  }

  Future<void> addPost(String text) async {
    final String currentTime = DateFormat('h:mm a').format(DateTime.now());

    final newPost = {
      "user": "You",
      "avatar": "assets/avatar.png",
      "message": text,
      "time": currentTime,
      "replies": [],
      "reactions": {"likes": 0, "likedBy": []},
    };

    final response = await http.post(
      Uri.parse("http://localhost:5000/api/chats"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(newPost),
    );

    if (response.statusCode == 201) {
      setState(() {
        posts.insert(0, jsonDecode(response.body));
      });
    } else {
      print("Error posting message");
    }

    _postController.clear();
  }

  Future<void> toggleReaction(Map<String, dynamic> post) async {
    // Create a copy of the post to update reactions
    Map<String, dynamic> updatedPost = Map.from(post);

    // Toggle the reaction locally first
    if (updatedPost['reactions']['likedBy'].contains("You")) {
      updatedPost['reactions']['likes']--;
      updatedPost['reactions']['likedBy'].remove("You");
    } else {
      updatedPost['reactions']['likes']++;
      updatedPost['reactions']['likedBy'].add("You");
    }

    // Update the UI immediately
    setState(() {
      final index = posts.indexWhere((p) => p['_id'] == post['_id']);
      if (index != -1) {
        posts[index] = updatedPost;
      }
    });

    // Send update to server
    try {
      final response = await http.put(
        Uri.parse("http://localhost:5000/api/chats/${post['_id']}/react"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user": "You",
          "liked": !post['reactions']['likedBy'].contains("You"),
        }),
      );

      if (response.statusCode != 200) {
        // If server update fails, revert the local change
        print("Error updating reaction: ${response.statusCode}");
        await fetchPosts(); // Refresh from server
      }
    } catch (e) {
      print("Error updating reaction: $e");
      await fetchPosts(); // Refresh from server on error
    }
  }

  Future<void> addReply(
      String postId, List<dynamic> replyList, String replyText) async {
    final String currentTime = DateFormat('h:mm a').format(DateTime.now());

    final newReply = {
      "user": "You",
      "avatar": "assets/avatar.png",
      "message": replyText,
      "time": currentTime,
      "reactions": {"likes": 0, "likedBy": []},
    };

    setState(() {
      replyList.add(newReply);
    });

    // Send update to server
    try {
      final response = await http.post(
        Uri.parse("http://localhost:5000/api/chats/${postId}/reply"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(newReply),
      );

      if (response.statusCode != 201) {
        // If server update fails, refresh from server
        print("Error adding reply: ${response.statusCode}");
        await fetchPosts();
      }
    } catch (e) {
      print("Error adding reply: $e");
      await fetchPosts(); // Refresh from server on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1C1F26),
      appBar: AppBar(
        backgroundColor: Color(0xFF1C1F26),
        elevation: 0,
        title: Text(
          "Community",
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (widget.onNavigateToTab != null) {
              widget.onNavigateToTab!(1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: posts.isEmpty
                ? Center(child: CircularProgressIndicator(color: Colors.white))
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      return _buildPost(posts[index], posts[index]["replies"]);
                    },
                  ),
          ),
          _buildPostInput(),
        ],
      ),
    );
  }

  Widget _buildPost(Map<String, dynamic> post, List<dynamic> replies) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF98C9C5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage(post['avatar']),
                radius: 20,
              ),
              SizedBox(width: 10),
              Text(post['user'],
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Spacer(),
              Text(post['time'],
                  style: TextStyle(fontSize: 12, color: Colors.grey[800])),
            ],
          ),
          SizedBox(height: 8),
          Text(post['message'], style: TextStyle(fontSize: 14)),
          SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.favorite,
                  color: post['reactions']['likedBy'].contains("You")
                      ? Colors.red
                      : Colors.grey,
                ),
                onPressed: () => toggleReaction(post),
              ),
              Text("${post['reactions']['likes']}"),
              Spacer(),
              TextButton(
                onPressed: () {
                  _showReplyDialog(post['_id'], replies);
                },
                child: Text("Reply", style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
          ...replies
              .map<Widget>((reply) =>
                  _buildReply(post['_id'], reply, reply["replies"] ?? []))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildReply(
      String postId, Map<String, dynamic> reply, List<dynamic> replyList) {
    return Padding(
      padding: EdgeInsets.only(left: 30, top: 5),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundImage: AssetImage(reply['avatar']),
                radius: 15,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reply['user'],
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(reply['message']),
                    Row(
                      children: [
                        Text(reply['time'],
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[800])),
                        Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.favorite,
                            color: reply['reactions']['likedBy'].contains("You")
                                ? Colors.red
                                : Colors.grey,
                          ),
                          onPressed: () => toggleReaction(reply),
                        ),
                        Text("${reply['reactions']['likes']}"),
                        SizedBox(width: 10),
                        TextButton(
                          onPressed: () {
                            _showReplyDialog(postId, replyList);
                          },
                          child: Text("Reply",
                              style: TextStyle(color: Colors.blue)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          ...replyList
              .map<Widget>((nestedReply) => _buildReply(
                  postId, nestedReply, nestedReply["replies"] ?? []))
              .toList(),
        ],
      ),
    );
  }

  void _showReplyDialog(String postId, List<dynamic> replyList) {
    TextEditingController replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Reply"),
          content: TextField(
            controller: replyController,
            decoration: InputDecoration(hintText: "Enter your reply"),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text("Cancel")),
            TextButton(
              onPressed: () {
                if (replyController.text.trim().isNotEmpty) {
                  addReply(postId, replyList, replyController.text.trim());
                  Navigator.pop(context);
                }
              },
              child: Text("Send"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPostInput() {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15), topRight: Radius.circular(15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _postController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "What would you like to share today?",
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white10,
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
