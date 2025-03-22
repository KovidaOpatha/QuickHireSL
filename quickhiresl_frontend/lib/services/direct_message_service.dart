import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/direct_message.dart';
import '../config/config.dart';

class DirectMessageService {
  final String baseUrl = Config.apiUrl;
  final _storage = const FlutterSecureStorage();

  // Cache for successful endpoints to avoid repeated failures
  static final Map<String, String> _cachedEndpoints = {};

  Future<List<DirectMessage>> getMessages(String otherUserId, {String? jobId}) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception('No token found');

      // If jobId is provided, try job-specific endpoint first
      if (jobId != null) {
        final jobCacheKey = 'get_messages_job_${jobId}_$otherUserId';
        
        // Check if we have a cached job-specific endpoint
        if (_cachedEndpoints.containsKey(jobCacheKey)) {
          try {
            final cachedEndpoint = _cachedEndpoints[jobCacheKey]!;
            final response = await http.get(
              Uri.parse(cachedEndpoint),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            );
            
            print('Service - Using cached job endpoint: $cachedEndpoint, status: ${response.statusCode}');
            
            if (response.statusCode == 200) {
              return _parseMessageResponse(response);
            } else {
              // If cached endpoint fails, remove it
              _cachedEndpoints.remove(jobCacheKey);
            }
          } catch (e) {
            print('Service - Error with cached job endpoint: $e');
            _cachedEndpoints.remove(jobCacheKey);
          }
        }
        
        // Try job-specific endpoint for direct messages
        try {
          final jobSpecificEndpoint = '$baseUrl/messages/job/$jobId/$otherUserId';
          final response = await http.get(
            Uri.parse(jobSpecificEndpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
          
          print('Service - Trying job specific endpoint: $jobSpecificEndpoint, status: ${response.statusCode}');
          
          if (response.statusCode == 200) {
            _cachedEndpoints[jobCacheKey] = jobSpecificEndpoint; 
            return _parseMessageResponse(response);
          }
        } catch (e) {
          print('Service - Error with job specific endpoint: $e');
        }
      }

      // Check if we have a cached endpoint for this user
      final cacheKey = 'get_messages_$otherUserId';
      if (_cachedEndpoints.containsKey(cacheKey)) {
        try {
          final cachedEndpoint = _cachedEndpoints[cacheKey]!;
          final response = await http.get(
            Uri.parse(cachedEndpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
          
          print('Service - Using cached endpoint: $cachedEndpoint, status: ${response.statusCode}');
          
          if (response.statusCode == 200) {
            List<DirectMessage> allMessages = _parseMessageResponse(response);
            
            // Filter by jobId if provided
            if (jobId != null) {
              allMessages = allMessages.where((message) => message.jobId == jobId).toList();
            }
            
            return allMessages;
          } else {
            // If cached endpoint fails, remove it and try others
            _cachedEndpoints.remove(cacheKey);
          }
        } catch (e) {
          print('Service - Error with cached endpoint: $e');
          _cachedEndpoints.remove(cacheKey);
        }
      }

      // Try multiple direct message endpoints
      final List<String> possibleEndpoints = [
        '$baseUrl/messages/$otherUserId',
        '$baseUrl/messages/direct/$otherUserId',
        '$baseUrl/messages/conversation/$otherUserId'
      ];
      
      http.Response? successfulResponse;
      String usedEndpoint = '';
      
      // Try each endpoint until we get a success
      for (String endpoint in possibleEndpoints) {
        try {
          final response = await http.get(
            Uri.parse(endpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
          
          print('Service - Trying endpoint: $endpoint, status: ${response.statusCode}');
          
          if (response.statusCode == 200) {
            successfulResponse = response;
            usedEndpoint = endpoint;
            // Cache the successful endpoint for future use
            _cachedEndpoints[cacheKey] = endpoint;
            break;
          }
        } catch (innerError) {
          print('Service - Error with endpoint $endpoint: $innerError');
          // Continue to next endpoint
        }
      }
      
      if (successfulResponse != null) {
        print('Service - Successfully fetched messages using endpoint: $usedEndpoint');
        List<DirectMessage> allMessages = _parseMessageResponse(successfulResponse);
        
        // Filter by jobId if provided
        if (jobId != null) {
          allMessages = allMessages.where((message) => message.jobId == jobId).toList();
        }
        
        return allMessages;
      } else {
        print('Service - No messages found for user $otherUserId after trying multiple endpoints');
        return [];
      }
    } catch (e) {
      print('Service - Exception getting messages: $e');
      // If the error is related to a 404, return an empty list
      if (e.toString().contains('404')) {
        return [];
      }
      throw Exception('Error getting messages: $e');
    }
  }

  // Helper method to parse different message response formats
  List<DirectMessage> _parseMessageResponse(http.Response response) {
    final data = json.decode(response.body);
    
    List<dynamic> messagesData = [];
    
    // Handle different response formats
    if (data is List) {
      // Direct list of messages
      messagesData = data;
    } else if (data is Map) {
      if (data.containsKey('messages') && data['messages'] != null) {
        messagesData = data['messages'];
      } else if (data.containsKey('result')) {
        var result = data['result'];
        if (result is List) {
          messagesData = result;
        } else if (result is Map && result.containsKey('messages')) {
          messagesData = result['messages'] ?? [];
        }
      }
    }
    
    return messagesData.map((json) => DirectMessage.fromJson(json)).toList();
  }

  Future<DirectMessage> sendMessage({
    required String receiverId,
    required String content,
    String? jobId,
    String? jobTitle,
  }) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception('No token found');

      final Map<String, dynamic> messageData = {
        'receiverId': receiverId,
        'content': content,
        'jobId': jobId,
        'jobTitle': jobTitle,
        'messageType': 'direct'  // Explicitly set message type to direct
      };

      // Determine the best endpoint to use - default to main messages endpoint
      String endpointToUse = '$baseUrl/messages';
      
      // If we have a cached endpoint for sending messages, use it first
      final sendMessageKey = 'send_message';
      if (_cachedEndpoints.containsKey(sendMessageKey)) {
        endpointToUse = _cachedEndpoints[sendMessageKey]!;
        print('Service - Using cached send endpoint: $endpointToUse');
      }
      
      // Send the message to the chosen endpoint
      try {
        final response = await http.post(
          Uri.parse(endpointToUse),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(messageData),
        );
        
        print('Service - Sending message to $endpointToUse, status: ${response.statusCode}');
        
        if (response.statusCode == 201 || response.statusCode == 200) {
          return DirectMessage.fromJson(json.decode(response.body));
        } else {
          // If the cached/default endpoint fails, try one fallback endpoint
          _cachedEndpoints.remove(sendMessageKey);
          
          print('Service - Primary endpoint failed, trying fallback');
          
          final fallbackEndpoint = '$baseUrl/messages/direct';
          final fallbackResponse = await http.post(
            Uri.parse(fallbackEndpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(messageData),
          );
          
          print('Service - Fallback endpoint $fallbackEndpoint status: ${fallbackResponse.statusCode}');
          
          if (fallbackResponse.statusCode == 201 || fallbackResponse.statusCode == 200) {
            // Remember this endpoint for future use
            _cachedEndpoints[sendMessageKey] = fallbackEndpoint;
            return DirectMessage.fromJson(json.decode(fallbackResponse.body));
          }
          
          throw Exception('Failed to send message: ${response.statusCode}');
        }
      } catch (e) {
        print('Service - Error with endpoint $endpointToUse: $e');
        
        // Try a fallback only if the first attempt failed with an exception
        final fallbackEndpoint = '$baseUrl/messages/direct';
        
        final fallbackResponse = await http.post(
          Uri.parse(fallbackEndpoint),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(messageData),
        );
        
        print('Service - Exception recovery fallback response: ${fallbackResponse.statusCode}');
        
        if (fallbackResponse.statusCode == 201 || fallbackResponse.statusCode == 200) {
          // Cache this successful endpoint
          _cachedEndpoints[sendMessageKey] = fallbackEndpoint;
          return DirectMessage.fromJson(json.decode(fallbackResponse.body));
        }
        
        throw Exception('Failed to send message after trying fallback');
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