import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/direct_message.dart';
import '../config/config.dart';

class DirectMessageService {
  final String baseUrl = Config.apiUrl;
  final _storage = const FlutterSecureStorage();

  Future<List<DirectMessage>> getMessages(String otherUserId) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('$baseUrl/messages/$otherUserId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => DirectMessage.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        // No messages found or conversation doesn't exist yet
        print('No messages found for user $otherUserId - returning empty list');
        return [];
      } else {
        print('Error fetching messages: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception getting messages: $e');
      // If the error is related to a 404, return an empty list
      if (e.toString().contains('404')) {
        return [];
      }
      throw Exception('Error getting messages: $e');
    }
  }

  Future<DirectMessage> sendMessage({
    required String receiverId,
    required String content,
    String? jobId,
  }) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception('No token found');

      final response = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'receiverId': receiverId,
          'content': content,
          'jobId': jobId,
        }),
      );

      if (response.statusCode == 201) {
        return DirectMessage.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('$baseUrl/messages/conversations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load conversations');
      }
    } catch (e) {
      throw Exception('Error getting conversations: $e');
    }
  }

  Future<void> markAsRead(String messageId) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception('No token found');

      final response = await http.patch(
        Uri.parse('$baseUrl/messages/$messageId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark message as read');
      }
    } catch (e) {
      throw Exception('Error marking message as read: $e');
    }
  }
} 