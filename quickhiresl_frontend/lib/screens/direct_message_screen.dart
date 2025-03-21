import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/config.dart';
import '../services/user_service.dart';
import '../utils/profile_image_util.dart';

class DirectMessageScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? receiverAvatar;
  final String? jobId;
  final String jobTitle;

  const DirectMessageScreen({
    Key? key,
    required this.receiverId,
    required this.receiverName,
    this.receiverAvatar,
    this.jobId,
    required this.jobTitle,
  }) : super(key: key);

  @override
  _DirectMessageScreenState createState() => _DirectMessageScreenState();
}

class _DirectMessageScreenState extends State<DirectMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _storage = FlutterSecureStorage();
  final UserService _userService = UserService();
  
  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  Timer? _messageTimer;
  String? userId;
  String? userName;
  String? userAvatar;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _fetchMessages();
    // Poll for new messages every 5 seconds
    _messageTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) _fetchMessages();
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        setState(() => isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('${Config.apiUrl}/messages/${widget.receiverId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Fetching messages for user ${widget.receiverId}, status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            messages = List<Map<String, dynamic>>.from(data);
            isLoading = false;
          });
          
          // Scroll to bottom after messages are loaded
          if (messages.isNotEmpty) {
            _scrollToBottom();
          }
        }
      } else if (response.statusCode == 404) {
        // No messages yet, just show empty conversation
        print('No existing messages found - starting new conversation');
        if (mounted) {
          setState(() => isLoading = false);
        }
      } else {
        print('Error fetching messages: ${response.statusCode} - ${response.body}');
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      print('Exception fetching messages: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final String currentTime = DateFormat('yyyy-MM-ddTHH:mm:ss').format(DateTime.now());

    try {
      // Create a temporary message to show immediately in the UI
      final Map<String, dynamic> tempMessage = {
        "content": content,
        "senderId": userId ?? "temp_user_id",
        "receiverId": widget.receiverId,
        "timestamp": currentTime,
        "isRead": false,
        "jobId": widget.jobId,
      };

      // Add temporary message to UI
      setState(() {
        messages.add(tempMessage);
      });

      // Clear input field immediately for better UX
      _messageController.clear();
      
      // Make sure to scroll to the new message
      _scrollToBottom();

      final token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception('No token found');

      final response = await http.post(
        Uri.parse('${Config.apiUrl}/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'receiverId': widget.receiverId,
          'content': content,
          'jobId': widget.jobId,
        }),
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
          content: Text('Error sending message. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.receiverAvatar != null)
              CircleAvatar(
                backgroundImage: ProfileImageUtil.getProfileImageProvider(widget.receiverAvatar!),
                radius: 20,
                backgroundColor: Colors.grey[200],
                onBackgroundImageError: (_, __) {
                  // Fallback if image fails to load
                },
              )
            else
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[200],
                child: Text(widget.receiverName[0].toUpperCase()),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.jobTitle,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
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
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final bool isMe = message['senderId'] == userId;
                          final DateTime timestamp = DateTime.parse(message['timestamp']).toLocal();
                          final String formattedTime = DateFormat('h:mm a').format(timestamp);
                          final String avatarUrl = isMe ? (userAvatar ?? '') : (widget.receiverAvatar ?? '');
                          final bool hasAvatar = avatarUrl.isNotEmpty && !avatarUrl.startsWith('assets/');

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              mainAxisAlignment: isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe) ...[
                                  hasAvatar
                                      ? CircleAvatar(
                                          backgroundImage: ProfileImageUtil.getProfileImageProvider(avatarUrl),
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
                                            widget.receiverName[0].toUpperCase(),
                                            style: TextStyle(color: Colors.grey[800]),
                                          ),
                                        ),
                                  SizedBox(width: 8),
                                ],
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message['content'],
                                        style: TextStyle(
                                          color: isMe ? Colors.white : Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
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
                                if (isMe) ...[
                                  SizedBox(width: 8),
                                  hasAvatar
                                      ? CircleAvatar(
                                          backgroundImage: ProfileImageUtil.getProfileImageProvider(
                                              userAvatar != null ? _userService.getFullImageUrl(userAvatar!) : ''),
                                          radius: 16,
                                          backgroundColor: Colors.grey[300],
                                          onBackgroundImageError: (_, __) {
                                            // Fallback if image fails to load
                                          },
                                        )
                                      : CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.grey[300],
                                          child: Icon(Icons.person, size: 16, color: Colors.grey[800]),
                                        ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
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
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
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