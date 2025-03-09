import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/messaging_service.dart';
import '../models/conversation.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatScreen({
    Key? key,
    required this.conversation,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MessagingService>(context, listen: false)
          .markMessagesAsRead(widget.conversation.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.conversation.jobTitle),
            Text(
              'Job ID: ${widget.conversation.jobId}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<MessagingService>(
              builder: (context, messagingService, child) {
                return StreamBuilder<List<Message>>(
                  stream: messagingService.getMessages(widget.conversation.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data!;

                    return ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return MessageBubble(message: message);
                      },
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                contentPadding: const EdgeInsets.all(10.0),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messagingService = Provider.of<MessagingService>(context, listen: false);
    final receiverId = widget.conversation.participants
        .firstWhere((id) => id != messagingService.currentUserId);

    await messagingService.sendMessage(
      receiverId: receiverId,
      content: _messageController.text,
      jobId: widget.conversation.jobId,
      jobTitle: widget.conversation.jobTitle,
    );

    _messageController.clear();
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMe = message.senderId == 
        Provider.of<MessagingService>(context, listen: false).currentUserId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            '${message.senderName} (${message.senderRole})',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 4.0),
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 