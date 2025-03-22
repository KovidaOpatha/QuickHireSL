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
        
        // Try job-specific endpoint
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

      // Try multiple endpoints to match community chat approach
      final List<String> possibleEndpoints = [
        '$baseUrl/messages/$otherUserId',
        '$baseUrl/messages/chat/$otherUserId',
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
        // If regular endpoints fail and we have a jobId, try job-specific fallback
        if (jobId != null) {
          try {
            final jobSpecificEndpoint = '$baseUrl/jobs/$jobId/chat';
            final response = await http.get(
              Uri.parse(jobSpecificEndpoint),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            );
            
            print('Service - Trying job chat endpoint: $jobSpecificEndpoint, status: ${response.statusCode}');
            
            if (response.statusCode == 200) {
              return _parseMessageResponse(response);
            }
          } catch (e) {
            print('Service - Error with job chat endpoint: $e');
          }
        }
        
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
        'jobTitle': jobTitle
      };

      // Check if we have a cached endpoint for this user's messages
      final getMessagesKey = 'get_messages_$receiverId';
      final sendMessageKey = 'send_message';
      
      // If we have a successful send endpoint, try it first
      if (_cachedEndpoints.containsKey(sendMessageKey)) {
        try {
          final cachedEndpoint = _cachedEndpoints[sendMessageKey]!;
          final response = await http.post(
            Uri.parse(cachedEndpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(messageData),
          );
          
          print('Service - Using cached send endpoint: $cachedEndpoint, status: ${response.statusCode}');
          
          if (response.statusCode == 201 || response.statusCode == 200) {
            return DirectMessage.fromJson(json.decode(response.body));
          } else {
            // If cached endpoint fails, remove it and try others
            _cachedEndpoints.remove(sendMessageKey);
          }
        } catch (e) {
          print('Service - Error with cached send endpoint: $e');
          _cachedEndpoints.remove(sendMessageKey);
        }
      }
      
      // If we know what endpoint works for getting messages, derive the send endpoint
      if (_cachedEndpoints.containsKey(getMessagesKey)) {
        final getEndpoint = _cachedEndpoints[getMessagesKey]!;
        if (getEndpoint.contains('/messages/')) {
          final endpointParts = getEndpoint.split('/');
          if (endpointParts.length >= 3) {
            final sendEndpoint = '$baseUrl/${endpointParts[1]}'; // Use the messages part
            
            try {
              final response = await http.post(
                Uri.parse(sendEndpoint),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
                body: json.encode(messageData),
              );
              
              print('Service - Trying derived endpoint: $sendEndpoint, status: ${response.statusCode}');
              
              if (response.statusCode == 201 || response.statusCode == 200) {
                _cachedEndpoints[sendMessageKey] = sendEndpoint;
                return DirectMessage.fromJson(json.decode(response.body));
              }
            } catch (e) {
              print('Service - Error with derived endpoint: $e');
            }
          }
        }
      }

      // Try multiple endpoints to match the community chat approach
      final List<String> possibleEndpoints = [
        '$baseUrl/messages',
        '$baseUrl/messages/send',
        '$baseUrl/messages/create'
      ];
      
      http.Response? successfulResponse;
      String usedEndpoint = '';
      
      // Try each endpoint until we get a success
      for (String endpoint in possibleEndpoints) {
        try {
          final response = await http.post(
            Uri.parse(endpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(messageData),
          );
          
          print('Service - Trying to send message to endpoint: $endpoint, status: ${response.statusCode}');
          
          if (response.statusCode == 201 || response.statusCode == 200) {
            successfulResponse = response;
            usedEndpoint = endpoint;
            // Cache the successful endpoint for future use
            _cachedEndpoints[sendMessageKey] = endpoint;
            print('Service - Message sent successfully using endpoint: $endpoint');
            break;
          }
        } catch (innerError) {
          print('Service - Error sending to endpoint $endpoint: $innerError');
          // Continue to next endpoint
        }
      }
      
      if (successfulResponse != null) {
        return DirectMessage.fromJson(json.decode(successfulResponse.body));
      } else {
        // Try job-specific endpoint as a last resort
        if (jobId != null) {
          try {
            final jobChatEndpoint = '$baseUrl/jobs/$jobId/chat';
            final jobChatResponse = await http.post(
              Uri.parse(jobChatEndpoint),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: json.encode({
                'content': content,
                'receiverId': receiverId
              }),
            );
            
            if (jobChatResponse.statusCode == 201 || jobChatResponse.statusCode == 200) {
              print('Service - Message sent successfully using job chat endpoint');
              return DirectMessage.fromJson(json.decode(jobChatResponse.body));
            }
          } catch (jobChatError) {
            print('Service - Error sending via job chat: $jobChatError');
          }
        }
        
        throw Exception('Failed to send message after trying multiple endpoints');
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