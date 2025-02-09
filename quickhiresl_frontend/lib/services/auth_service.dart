import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final String baseUrl = 'http://localhost:3000/api';
  final storage = FlutterSecureStorage();

  // Register user with optional profile image
  Future<Map<String, dynamic>> register(String email, String password, {String? base64Image}) async {
    try {
      print('[Register] Attempting registration for email: $email');
      
      final Map<String, dynamic> body = {
        'email': email,
        'password': password,
      };

      if (base64Image != null) {
        body['profileImage'] = base64Image;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('[Register] Response status: ${response.statusCode}');
      print('[Register] Response body: ${response.body}');

      return _handleRegisterResponse(response);
    } catch (e) {
      print('[ERROR] Registration error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Map<String, dynamic> _handleRegisterResponse(http.Response response) {
    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      final userId = responseData['userId'];
      final profileImage = responseData['profileImage'];

      _saveToStorage('user_id', userId);
      if (profileImage != null) {
        _saveToStorage('profile_image', profileImage);
      }

      return {
        'success': true,
        'userId': userId,
        'profileImage': profileImage,
      };
    }

    final error = jsonDecode(response.body)['message'] ?? 'Registration failed';
    return {
      'success': false,
      'error': error,
    };
  }

  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('[Login] Attempting login for email: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('[Login] Response status: ${response.statusCode}');
      print('[Login] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final token = responseData['token'];
        final userId = responseData['userId'];
        final role = responseData['role'];
        final profileImage = responseData['profileImage'] != null 
            ? getFullImageUrl(responseData['profileImage'])
            : null;

        await _saveToStorage('jwt_token', token);
        await _saveToStorage('user_id', userId);
        if (role != null) {
          await _saveToStorage('user_role', role);
        }
        if (profileImage != null) {
          await _saveToStorage('profile_image', profileImage);
        }

        return {
          'success': true,
          'token': token,
          'userId': userId,
          'role': role,
          'profileImage': profileImage,
        };
      }

      return {
        'success': false,
        'error': 'Invalid credentials',
      };
    } catch (e) {
      print('[ERROR] Login error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    // Remove any leading slashes and add the correct base URL
    final cleanPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    return 'http://localhost:3000/$cleanPath';
  }

  // Save data to storage
  Future<void> _saveToStorage(String key, String value) async {
    await storage.write(key: key, value: value);
    print('[Storage] Saved $key: ${key == 'jwt_token' ? 'token_saved' : value}');
  }

  // Get data from storage
  Future<String?> _getFromStorage(String key) async {
    final value = await storage.read(key: key);
    print('[Storage] Retrieved $key: ${key == 'jwt_token' ? 'token_exists: ${value != null}' : value}');
    return value;
  }

  // Get stored JWT token
  Future<String?> getToken() async {
    return await _getFromStorage('jwt_token');
  }

  // Get stored user ID
  Future<String?> getUserId() async {
    return await _getFromStorage('user_id');
  }

  // Get stored user role
  Future<String?> getUserRole() async {
    return await _getFromStorage('user_role');
  }

  // Get stored profile image
  Future<String?> getProfileImage() async {
    return await _getFromStorage('profile_image');
  }

  // Logout user by deleting all stored data
  Future<void> logout() async {
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'user_id');
    await storage.delete(key: 'user_role');
    await storage.delete(key: 'profile_image');
    print('[Auth] Logged out and cleared all stored data');
  }

  // Update user role and details
  Future<bool> updateRole(String userId, String role, Map<String, dynamic> details) async {
    try {
      print('[UpdateRole] Attempting to update role for user: $userId');
      print('[UpdateRole] Role to set: $role');
      print('[UpdateRole] Details: $details');

      final token = await getToken();
      print('[UpdateRole] Token retrieved from storage: ${token != null}');

      if (token == null) {
        print('[ERROR] No authentication token found');
        return false;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/auth/updateRole'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userId,
          'role': role,
          'studentDetails': role == 'student' ? details : null,
          'jobOwnerDetails': role == 'employer' ? details : null,
        }),
      );

      print('[UpdateRole] Response status: ${response.statusCode}');
      print('[UpdateRole] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        await _saveToStorage('user_role', role);

        if (responseData['token'] != null) {
          await _saveToStorage('jwt_token', responseData['token']);
        }

        print('[UpdateRole] Role update successful');
        return true;
      }

      print('[ERROR] Role update failed');
      return false;
    } catch (e) {
      print('[ERROR] Role update error: $e');
      return false;
    }
  }
}
