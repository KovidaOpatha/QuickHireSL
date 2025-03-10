import 'package:flutter/material.dart';
import '../../models/message_model.dart';
import '../../services/messaging_service.dart';
import 'chat_screen.dart';

class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({Key? key}) : super(key: key);

  @override
  _NewMessageScreenState createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  final TextEditingController _searchController = TextEditingController();
  late MessagingService _messagingService;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _messagingService = MessagingService(token: 'dummy-token');
    _loadUsers();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    
    // This is dummy data - in a real app, this would be fetched from an API
    await Future.delayed(Duration(milliseconds: 800));
    
    setState(() {
      _users = [
        {
          'id': 'user2',
          'name': 'John Doe',
          'email': 'john.doe@example.com',
          'profileImage': 'https://example.com/profile1.jpg',
          'role': 'Employer',
        },
        {
          'id': 'user3',
          'name': 'Jane Smith',
          'email': 'jane.smith@example.com',
          'profileImage': 'https://example.com/profile2.jpg',
          'role': 'Job Seeker',
        },
        {
          'id': 'user4',
          'name': 'Robert Johnson',
          'email': 'robert.johnson@example.com',
          'profileImage': 'https://example.com/profile3.jpg',
          'role': 'Employer',
        },
        {
          'id': 'user5',
          'name': 'Emily Davis',
          'email': 'emily.davis@example.com',
          'profileImage': 'https://example.com/profile4.jpg',
          'role': 'Job Seeker',
        },
      ];
      _isLoading = false;
    });
  }
  
  void _filterUsers(String query) {
    // In a real app, this would make an API call with the search query
    // For this dummy implementation, we'll just filter the local list
    setState(() {
      _isLoading = true;
    });
    
    Future.delayed(Duration(milliseconds: 300), () {
      setState(() {
        if (query.isEmpty) {
          _loadUsers();
        } else {
          _users = _users.where((user) {
            final name = user['name'].toString().toLowerCase();
            final email = user['email'].toString().toLowerCase();
            final searchLower = query.toLowerCase();
            return name.contains(searchLower) || email.contains(searchLower);
          }).toList();
        }
        _isLoading = false;
      });
    });
  }
  
  Future<void> _startConversation(String userId, String userName) async {
    // Create a new conversation or get existing one
    final conversation = await _messagingService.createConversation(userId);
    
    if (conversation != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversationId: conversation.id,
            recipientName: userName,
            recipientId: userId,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start conversation')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Message'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: _filterUsers,
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? Center(child: Text('No users found'))
                    : ListView.separated(
                        itemCount: _users.length,
                        separatorBuilder: (context, index) => Divider(height: 1),
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user['profileImage'] != null
                                  ? NetworkImage(user['profileImage'])
                                  : null,
                              child: user['profileImage'] == null
                                  ? Text(user['name'][0])
                                  : null,
                            ),
                            title: Text(user['name']),
                            subtitle: Text(user['role']),
                            onTap: () => _startConversation(
                              user['id'],
                              user['name'],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
