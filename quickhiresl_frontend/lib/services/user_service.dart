import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserService {
  final String baseUrl = 'http://localhost:3000/api';
  final storage = const FlutterSecureStorage();

  String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    // Remove any leading slashes and add the correct base URL
    final cleanPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    return 'http://localhost:3000/$cleanPath';
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await storage.read(key: 'jwt_token');
      final userId = await storage.read(key: 'user_id');

      if (token == null || userId == null) {
        throw Exception('Authentication required');
      }

      print('[UserService] Fetching profile for user: $userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[UserService] Response status: ${response.statusCode}');
      print('[UserService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['profileImage'] != null) {
          data['profileImage'] = getFullImageUrl(data['profileImage']);
        }
        return {
          'success': true,
          'data': data,
        };
      } else {
        print('[ERROR] Failed to fetch user profile: ${response.body}');
        return {
          'success': false,
          'error': 'Failed to fetch user profile',
        };
      }
    } catch (e) {
      print('[ERROR] User profile error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
