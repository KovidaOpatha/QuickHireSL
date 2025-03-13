import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/config.dart';
import '../models/job.dart';
import '../services/user_service.dart';
import 'community_screen.dart';

class ChatScreen extends StatefulWidget {
  final List<Job> jobs;
  final Map<String, dynamic>? job;

  ChatScreen(this.jobs, {this.job});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final _storage = FlutterSecureStorage();
  final UserService _userService = UserService();
  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  String? userId;
  String? userName;
  String? userAvatar;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _fetchMessages();
  }

  Future<void> _loadUserInfo() async {
    userId = await _storage.read(key: 'user_id');
    userName = await _storage.read(key: 'user_name');

    // Try to load user profile to get avatar
    try {
      final userProfileResult = await _userService.getUserProfile();
      if (userProfileResult['success'] && userProfileResult['data'] != null) {
        userAvatar = userProfileResult['data']['profileImage'];
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _fetchMessages() async {
    if (widget.job == null || widget.job!['id'] == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final Uri uri =
          Uri.parse('${Config.apiUrl}/jobs/${widget.job!['id']}/chat');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          messages = List<Map<String, dynamic>>.from(data['messages']);
          isLoading = false;
        });
      } else {
        print("Error fetching messages: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching messages: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty ||
        widget.job == null ||
        widget.job!['id'] == null) return;

    final String currentTime =
        DateFormat('yyyy-MM-ddTHH:mm:ss').format(DateTime.now());

    try {
      // Create a temporary message to show immediately in the UI
      final Map<String, dynamic> tempMessage = {
        "content": content,
        "sender": {
          "_id": userId ?? "temp_user_id",
          "name": userName ?? "You",
          "avatar": userAvatar ?? "assets/avatar.png",
        },
        "jobId": widget.job!['id'],
        "timestamp": currentTime,
      };

      // Add temporary message to UI
      setState(() {
        messages.add(tempMessage);
      });

      // Clear input field immediately for better UX
      _messageController.clear();

      final Uri uri =
          Uri.parse('${Config.apiUrl}/jobs/${widget.job!['id']}/chat');

      final Map<String, dynamic> messageData = {
        "content": content,
        "sender": {
          "_id": userId ?? "temp_user_id",
          "name": userName ?? "You",
          "avatar": userAvatar ?? "assets/avatar.png",
        },
        "jobId": widget.job!['id'],
        "timestamp": currentTime,
      };

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(messageData),
      );

      if (response.statusCode == 201) {
        final newMessage = jsonDecode(response.body);
        // Replace the temporary message with the server response
        setState(() {
          messages.removeLast();
          messages.add(newMessage);
        });
      } else {
        // Remove the temporary message if there was an error
        setState(() {
          messages.removeLast();
        });

        print("Error posting message: ${response.statusCode}");
        print("Response body: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Remove the temporary message if there was an error
      setState(() {
        if (messages.isNotEmpty) {
          messages.removeLast();
        }
      });

      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CommunityScreen()),
            );
          },
        ),
        title: Row(
          children: [
            // Profile image
            widget.job != null &&
                    widget.job!['profilePicture'] != null &&
                    widget.job!['profilePicture'].toString().isNotEmpty
                ? CircleAvatar(
                    backgroundImage:
                        NetworkImage(widget.job!['profilePicture']),
                    radius: 16,
                    backgroundColor: Colors.grey[200],
                    onBackgroundImageError: (_, __) {
                      // Fallback if image fails to load
                    },
                  )
                : CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    radius: 16,
                    child: Text(
                      widget.job != null && widget.job!['company'] != null
                          ? widget.job!['company'][0].toUpperCase()
                          : '?',
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                  ),
            SizedBox(width: 8),
            // Job title and company
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.job != null ? widget.job!['title'] : 'Job Chat',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.job != null ? widget.job!['company'] : '',
                    style: TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Start the conversation!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final bool isMe =
                                message['sender']['_id'] == userId;
                            final DateTime timestamp =
                                DateTime.parse(message['timestamp']).toLocal();
                            final String formattedTime =
                                DateFormat('h:mm a').format(timestamp);
                            final String avatarUrl =
                                message['sender']['avatar'] ?? '';
                            final bool hasAvatar = avatarUrl.isNotEmpty &&
                                !avatarUrl.startsWith('assets/');

                            return Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: Row(
                                mainAxisAlignment: isMe
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMe) ...[
                                    hasAvatar
                                        ? CircleAvatar(
                                            backgroundImage:
                                                NetworkImage(avatarUrl),
                                            radius: 16,
                                            backgroundColor: Colors.grey[300],
                                            onBackgroundImageError: (_, __) {
                                              // Fallback if image fails to load
                                            },
                                          )
                                        : CircleAvatar(
                                            radius: 16,
                                            backgroundColor: Colors.grey[300],
                                            child: Text(
                                              message['sender']['name'][0]
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                  color: Colors.grey[800]),
                                            ),
                                          ),
                                    SizedBox(width: 8),
                                  ],
                                  Container(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.7,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (!isMe)
                                          Text(
                                            message['sender']['name'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[800],
                                              fontSize: 12,
                                            ),
                                          ),
                                        Text(
                                          message['content'],
                                          style: TextStyle(
                                            color: isMe
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          formattedTime,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isMe
                                                ? Colors.white.withOpacity(0.7)
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isMe) SizedBox(width: 8),
                                  if (isMe)
                                    hasAvatar
                                        ? CircleAvatar(
                                            backgroundImage:
                                                NetworkImage(avatarUrl),
                                            radius: 16,
                                            backgroundColor: Colors.grey[300],
                                            onBackgroundImageError: (_, __) {
                                              // Fallback if image fails to load
                                            },
                                          )
                                        : CircleAvatar(
                                            radius: 16,
                                            backgroundColor: Colors.grey[300],
                                            child: Text(
                                              message['sender']['name'][0]
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                  color: Colors.grey[800]),
                                            ),
                                          ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: IconButton(
                          icon: Icon(Icons.send, color: Colors.white),
                          onPressed: () {
                            if (_messageController.text.trim().isNotEmpty) {
                              sendMessage(_messageController.text);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
