import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/messaging_service.dart';
import '../models/conversation.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: Consumer<MessagingService>(
        builder: (context, messagingService, child) {
          return StreamBuilder<List<Conversation>>(
            stream: messagingService.getConversations(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final conversations = snapshot.data!;

              if (conversations.isEmpty) {
                return const Center(child: Text('No conversations yet'));
              }

              return ListView.builder(
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  return ConversationTile(conversation: conversation);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ConversationTile extends StatelessWidget {
  final Conversation conversation;

  const ConversationTile({
    Key? key,
    required this.conversation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(conversation.jobTitle[0].toUpperCase()),
      ),
      title: Text(conversation.jobTitle),
      subtitle: Text(conversation.lastMessage),
      trailing: conversation.unreadCount > 0
          ? CircleAvatar(
              radius: 12,
              backgroundColor: Colors.blue,
              child: Text(
                conversation.unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            )
          : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(conversation: conversation),
          ),
        );
      },
    );
  }
} 