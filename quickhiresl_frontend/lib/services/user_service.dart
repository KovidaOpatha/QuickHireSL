import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/config.dart';
import '../utils/profile_image_util.dart';

class UserService {
  final String baseUrl = Config.apiUrl;
  final storage = const FlutterSecureStorage();

  String getFullImageUrl(String? imagePath) {
    return ProfileImageUtil.getFullImageUrl(imagePath);
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

  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> userData, {File? profileImage}) async {
    try {
      final token = await storage.read(key: 'jwt_token');
      final userId = await storage.read(key: 'user_id');

      if (token == null || userId == null) {
        throw Exception('Authentication required');
      }

      print('[UserService] Updating profile for user: $userId');
      print('[UserService] Update data: $userData');
      
      if (profileImage != null) {
        // Handle file upload with multipart request
        var request = http.MultipartRequest(
          'PUT',
          Uri.parse('$baseUrl/users/$userId'),
        );
        
        // Add headers
        request.headers.addAll({
          'Authorization': 'Bearer $token',
        });
        
        // Add file
        var fileStream = http.ByteStream(profileImage.openRead());
        var fileLength = await profileImage.length();
        
        var multipartFile = http.MultipartFile(
          'profileImage', 
          fileStream, 
          fileLength,
          filename: 'profile_image.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        
        request.files.add(multipartFile);
        
        // Add other fields
        request.fields['userData'] = json.encode(userData);
        
        // Send the request
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200) {
          print('[UserService] Profile updated successfully');
          return {
            'success': true,
            'data': json.decode(response.body)
          };
        } else {
          print('[UserService] Response status: ${response.statusCode}');
          print('[UserService] Response body: ${response.body}');
          throw Exception('Failed to update user profile: ${response.body}');
        }
      } else {
        // Regular JSON request without file
        final response = await http.put(
          Uri.parse('$baseUrl/users/$userId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(userData),
        );

        print('[UserService] Response status: ${response.statusCode}');
        print('[UserService] Response body: ${response.body}');

        if (response.statusCode == 200) {
          print('[UserService] Profile updated successfully');
          final data = json.decode(response.body);
          print('[UserService] Decoded data: $data');
          return {
            'success': true,
            'data': data
          };
        } else {
          print('[UserService] Response status: ${response.statusCode}');
          print('[UserService] Response body: ${response.body}');
          throw Exception('Failed to update user profile: ${response.body}');
        }
      }
    } catch (e) {
      print('[ERROR] User profile update error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> updateJobPreferences(Map<String, dynamic> jobPreferences) async {
    try {
      final token = await storage.read(key: 'jwt_token');
      final userId = await storage.read(key: 'user_id');

      if (token == null || userId == null) {
        throw Exception('Authentication required');
      }

      print('[UserService] Updating job preferences for user: $userId');
      print('[UserService] Preferences data: $jobPreferences');
      
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/job-preferences'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(jobPreferences),
      );

      print('[UserService] Response status: ${response.statusCode}');
      print('[UserService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('[UserService] Job preferences updated successfully');
        return {
          'success': true,
          'data': json.decode(response.body)
        };
      } else {
        print('[UserService] Failed to update job preferences: ${response.body}');
        return {
          'success': false,
          'error': 'Failed to update job preferences',
        };
      }
    } catch (e) {
      print('[ERROR] Job preferences update error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
