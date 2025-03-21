import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/config.dart';
import '../utils/profile_image_util.dart';

class CommunityScreen extends StatefulWidget {
  final Function(int) onNavigateToTab;

  const CommunityScreen({Key? key, required this.onNavigateToTab})
      : super(key: key);

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _postController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> posts = [];
  bool isLoading = true;
  Map<String, dynamic>? currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserAndChats();
  }

  Future<void> _loadUserAndChats() async {
    try {
      setState(() => isLoading = true);
      await _loadCurrentUser();
      await fetchChats();
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('${Config.apiUrl}/users/current'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() => currentUser = json.decode(response.body));
      } else {
        print('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  Future<void> fetchChats() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('${Config.apiUrl}/chats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() => posts = List<Map<String, dynamic>>.from(data));
      } else {
        print('Failed to load chats: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching chats: $e');
    }
  }

  Future<void> saveChat(Map<String, dynamic> chat) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('No token found');

      final response = await http.post(
        Uri.parse('${Config.apiUrl}/chats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(chat),
      );

      if (response.statusCode == 201) {
        await fetchChats(); // Refresh chats after saving
      } else {
        print('Failed to save chat: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving chat: $e');
    }
  }

  void addPost(String text) {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to post')),
      );
      return;
    }

    final newChat = {
      'userId': currentUser!['_id'],
      'user': currentUser!['name'],
      'profileImage': currentUser!['profileImage'],
      'message': text,
      'time': DateTime.now().toIso8601String(),
    };

    saveChat(newChat);
    _postController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF98C9C5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Community',
          style: TextStyle(color: Colors.black, fontSize: 24),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.black),
          onPressed: () => widget.onNavigateToTab(1),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadUserAndChats,
                      child: posts.isEmpty
                          ? const Center(
                              child: Text(
                                'No posts yet\nBe the first to post!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: posts.length,
                              itemBuilder: (context, index) {
                                return _buildPost(posts[index]);
                              },
                            ),
                    ),
            ),
            _buildPostInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildPost(Map<String, dynamic> post) {
    final DateTime timestamp = DateTime.parse(post['time']);
    final String timeAgo = _getTimeAgo(timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileImageUtil.buildProfileImage(
                imageUrl: post['profileImage'],
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['user'] ?? 'Anonymous',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post['message'] ?? '',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPostInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _postController,
              decoration: InputDecoration(
                hintText: 'Share your thoughts...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF98C9C5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () {
                if (_postController.text.trim().isNotEmpty) {
                  addPost(_postController.text.trim());
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
