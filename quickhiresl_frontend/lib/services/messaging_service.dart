import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';
import '../config/api_config.dart';

class MessagingService {
  final String baseUrl = ApiConfig.baseUrl;
  final String token;

  MessagingService({required this.token});

  // Get all conversations for the current user
  Future<List<Conversation>> getConversations() async {
    try {
      // This is dummy code - in a real app, this would make an API call
      await Future.delayed(Duration(milliseconds: 800)); // Simulate network delay
      
      // Dummy data
      return [
        Conversation(
          id: '1',
          participants: ['user1', 'user2'],
          lastMessage: Message(
            id: 'm1',
            senderId: 'user2',
            receiverId: 'user1',
            content: 'When can you start the job?',
            timestamp: DateTime.now().subtract(Duration(hours: 2)),
          ),
          updatedAt: DateTime.now().subtract(Duration(hours: 2)),
          name: 'John Doe',
          imageUrl: 'https://example.com/profile1.jpg',
        ),
        Conversation(
          id: '2',
          participants: ['user1', 'user3'],
          lastMessage: Message(
            id: 'm2',
            senderId: 'user1',
            receiverId: 'user3',
            content: 'I have reviewed your application',
            timestamp: DateTime.now().subtract(Duration(days: 1)),
          ),
          updatedAt: DateTime.now().subtract(Duration(days: 1)),
          name: 'Jane Smith',
          imageUrl: 'https://example.com/profile2.jpg',
        ),
      ];
    } catch (e) {
      print('Error fetching conversations: $e');
      return [];
    }
  }

  // Get messages for a specific conversation
  Future<List<Message>> getMessages(String conversationId) async {
    try {
      // This is dummy code - in a real app, this would make an API call
      await Future.delayed(Duration(milliseconds: 800)); // Simulate network delay
      
      // Dummy data
      return [
        Message(
          id: 'm1',
          senderId: 'user2',
          receiverId: 'user1',
          content: 'Hi, I saw your job posting',
          timestamp: DateTime.now().subtract(Duration(hours: 3)),
        ),
        Message(
          id: 'm2',
          senderId: 'user1',
          receiverId: 'user2',
          content: 'Yes, are you interested?',
          timestamp: DateTime.now().subtract(Duration(hours: 2, minutes: 45)),
        ),
        Message(
          id: 'm3',
          senderId: 'user2',
          receiverId: 'user1',
          content: 'Definitely! When can we discuss the details?',
          timestamp: DateTime.now().subtract(Duration(hours: 2, minutes: 30)),
        ),
        Message(
          id: 'm4',
          senderId: 'user1',
          receiverId: 'user2',
          content: 'How about tomorrow at 2 PM?',
          timestamp: DateTime.now().subtract(Duration(hours: 2)),
        ),
      ];
    } catch (e) {
      print('Error fetching messages: $e');
      return [];
    }
  }

  // Send a new message
  Future<Message?> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    String messageType = 'text',
    String? attachmentUrl,
  }) async {
    try {
      // This is dummy code - in a real app, this would make an API call
      await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
      
      // Dummy response
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'user1', // Current user
        receiverId: receiverId,
        content: content,
        timestamp: DateTime.now(),
        messageType: messageType,
        attachmentUrl: attachmentUrl,
      );
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }

  // Create a new conversation
  Future<Conversation?> createConversation(String receiverId) async {
    try {
      // This is dummy code - in a real app, this would make an API call
      await Future.delayed(Duration(milliseconds: 800)); // Simulate network delay
      
      // Dummy response
      return Conversation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        participants: ['user1', receiverId],
        lastMessage: Message(
          id: 'm1',
          senderId: 'user1',
          receiverId: receiverId,
          content: 'Hello!',
          timestamp: DateTime.now(),
        ),
        updatedAt: DateTime.now(),
        name: 'New Conversation',
        imageUrl: 'https://example.com/default.jpg',
      );
    } catch (e) {
      print('Error creating conversation: $e');
      return null;
    }
  }

  // Mark messages as read
  Future<bool> markAsRead(String conversationId) async {
    try {
      // This is dummy code - in a real app, this would make an API call
      await Future.delayed(Duration(milliseconds: 300)); // Simulate network delay
      return true;
    } catch (e) {
      print('Error marking messages as read: $e');
      return false;
    }
  }
}
