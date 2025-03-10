import 'package:flutter/material.dart';
import '../../models/message_model.dart';
import '../../services/messaging_service.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({Key? key}) : super(key: key);

  @override
  _ConversationsScreenState createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  late MessagingService _messagingService;
  List<Conversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // In a real app, you would get the token from your auth service
    _messagingService = MessagingService(token: 'dummy-token');
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final conversations = await _messagingService.getConversations();
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load conversations')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Search functionality would go here
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? _buildEmptyState()
              : _buildConversationsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Start new conversation functionality would go here
        },
        child: Icon(Icons.message),
        tooltip: 'New Message',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.message_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start messaging with employers or job seekers',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Start new conversation
            },
            icon: Icon(Icons.add),
            label: Text('New Message'),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.separated(
        itemCount: _conversations.length,
        separatorBuilder: (context, index) => Divider(height: 1),
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return _buildConversationTile(conversation);
        },
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    final lastMessage = conversation.lastMessage;
    final formattedTime = _formatTime(lastMessage.timestamp);

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: conversation.imageUrl != null
            ? NetworkImage(conversation.imageUrl!)
            : null,
        child: conversation.imageUrl == null
            ? Text(conversation.name?[0] ?? '?')
            : null,
      ),
      title: Text(
        conversation.name ?? 'Unknown',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        lastMessage.content,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          if (!lastMessage.isRead && lastMessage.receiverId == 'user1') // Current user
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversation.id,
              recipientName: conversation.name ?? 'Unknown',
              recipientId: conversation.participants.firstWhere(
                (id) => id != 'user1', // Not current user
                orElse: () => '',
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        switch (time.weekday) {
          case 1:
            return 'Mon';
          case 2:
            return 'Tue';
          case 3:
            return 'Wed';
          case 4:
            return 'Thu';
          case 5:
            return 'Fri';
          case 6:
            return 'Sat';
          case 7:
            return 'Sun';
          default:
            return '';
        }
      } else {
        return '${time.day}/${time.month}/${time.year}';
      }
    } else if (difference.inHours > 0) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
