import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/messaging_service.dart';

class MessagingProvider extends ChangeNotifier {
  final MessagingService _messagingService;
  
  List<Conversation> _conversations = [];
  Map<String, List<Message>> _messagesByConversation = {};
  bool _isLoading = false;
  String? _error;

  MessagingProvider({required String token})
      : _messagingService = MessagingService(token: token);

  // Getters
  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get messages for a specific conversation
  List<Message> getMessagesForConversation(String conversationId) {
    return _messagesByConversation[conversationId] ?? [];
  }

  // Load all conversations
  Future<void> loadConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final conversations = await _messagingService.getConversations();
      _conversations = conversations;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load conversations: $e';
      notifyListeners();
    }
  }

  // Load messages for a specific conversation
  Future<void> loadMessages(String conversationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final messages = await _messagingService.getMessages(conversationId);
      _messagesByConversation[conversationId] = messages;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load messages: $e';
      notifyListeners();
    }
  }

  // Send a message
  Future<bool> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    String messageType = 'text',
    String? attachmentUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final message = await _messagingService.sendMessage(
        conversationId: conversationId,
        receiverId: receiverId,
        content: content,
        messageType: messageType,
        attachmentUrl: attachmentUrl,
      );

      if (message != null) {
        // Add message to local cache
        if (_messagesByConversation.containsKey(conversationId)) {
          _messagesByConversation[conversationId]!.add(message);
        } else {
          _messagesByConversation[conversationId] = [message];
        }

        // Update conversation's last message
        final conversationIndex = _conversations.indexWhere(
          (c) => c.id == conversationId,
        );
        if (conversationIndex != -1) {
          final updatedConversation = Conversation(
            id: _conversations[conversationIndex].id,
            participants: _conversations[conversationIndex].participants,
            lastMessage: message,
            updatedAt: DateTime.now(),
            name: _conversations[conversationIndex].name,
            imageUrl: _conversations[conversationIndex].imageUrl,
          );
          
          _conversations[conversationIndex] = updatedConversation;
          
          // Sort conversations by most recent
          _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        _error = 'Failed to send message';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Error sending message: $e';
      notifyListeners();
      return false;
    }
  }

  // Create a new conversation
  Future<Conversation?> createConversation(String receiverId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final conversation = await _messagingService.createConversation(receiverId);
      
      if (conversation != null) {
        _conversations.insert(0, conversation);
        _isLoading = false;
        notifyListeners();
      }
      
      return conversation;
    } catch (e) {
      _isLoading = false;
      _error = 'Error creating conversation: $e';
      notifyListeners();
      return null;
    }
  }

  // Mark messages as read
  Future<bool> markMessagesAsRead(String conversationId) async {
    try {
      final success = await _messagingService.markAsRead(conversationId);
      
      if (success) {
        // Update local message read status
        if (_messagesByConversation.containsKey(conversationId)) {
          final messages = _messagesByConversation[conversationId]!;
          for (var i = 0; i < messages.length; i++) {
            if (messages[i].receiverId == 'user1' && !messages[i].isRead) {
              final updatedMessage = Message(
                id: messages[i].id,
                senderId: messages[i].senderId,
                receiverId: messages[i].receiverId,
                content: messages[i].content,
                timestamp: messages[i].timestamp,
                isRead: true,
                attachmentUrl: messages[i].attachmentUrl,
                messageType: messages[i].messageType,
              );
              messages[i] = updatedMessage;
            }
          }
          notifyListeners();
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      _error = 'Error marking messages as read: $e';
      notifyListeners();
      return false;
    }
  }
}
