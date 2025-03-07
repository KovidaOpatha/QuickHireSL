import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final String baseUrl = 'http://localhost:3000/api';
  final storage = const FlutterSecureStorage();

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
    try {
      final responseData = jsonDecode(response.body);
      print('[Register] Response data: $responseData');

      if (response.statusCode == 201) {
        final userId = responseData['userId'];
        final profileImage = responseData['profileImage'];

        // Store temporary registration data
        _saveToStorage('temp_user_id', userId);
        if (profileImage != null) {
          _saveToStorage('temp_profile_image', profileImage);
        }

        return {
          'success': true,
          'userId': userId,
          'profileImage': profileImage,
          'message': responseData['message'] ?? 'Registration successful',
        };
      }

      final error = responseData['message'] ?? responseData['error'] ?? 'Registration failed';
      print('[Register] Error: $error');
      return {
        'success': false,
        'error': error,
      };
    } catch (e) {
      print('[Register] Error parsing response: $e');
      return {
        'success': false,
        'error': 'Failed to process registration response',
      };
    }
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
        await _saveToStorage('email', email);
        await _saveToStorage('password', password); // Store password
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

  // Get stored email
  Future<String?> getEmail() async {
    return await _getFromStorage('email');
  }

  // Get stored password
  Future<String?> getPassword() async {
    return await _getFromStorage('password');
  }

  // Logout user by deleting all stored data
  Future<void> logout() async {
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'user_id');
    await storage.delete(key: 'user_role');
    await storage.delete(key: 'profile_image');
    await storage.delete(key: 'email');
    await storage.delete(key: 'password'); // Delete password
    print('[Auth] Logged out and cleared all stored data');
  }

  // Update user role and details
  Future<Map<String, dynamic>> updateRole(String userId, String role, {Map<String, dynamic>? details}) async {
    try {
      print('[UpdateRole] Attempting to update role for user: $userId');
      print('[UpdateRole] Role to set: $role');
      print('[UpdateRole] Details: $details');

      final response = await http.patch(
        Uri.parse('$baseUrl/auth/role/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'role': role,
          if (details != null) ...details,
        }),
      );

      print('[UpdateRole] Response status: ${response.statusCode}');
      print('[UpdateRole] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'role': responseData['role'],
          'message': responseData['message'] ?? 'Role updated successfully',
        };
      }

      final responseData = jsonDecode(response.body);
      return {
        'success': false,
        'error': responseData['message'] ?? 'Failed to update role',
      };
    } catch (e) {
      print('[ERROR] Update role error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      print('[GetUserProfile] Fetching profile for user: $userId');
      
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Authentication token not found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[GetUserProfile] Response status: ${response.statusCode}');
      print('[GetUserProfile] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      }

      final responseData = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      return {
        'success': false,
        'error': responseData['message'] ?? 'Failed to fetch user profile',
      };
    } catch (e) {
      print('[ERROR] Get user profile error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Verify user data was saved correctly
  Future<Map<String, dynamic>> verifyUserData(String userId) async {
    try {
      print('[VerifyUserData] Verifying data for user: $userId');
      
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Authentication token not found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/auth/verify/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[VerifyUserData] Response status: ${response.statusCode}');
      print('[VerifyUserData] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'verified': responseData['verified'],
          'role': responseData['role'],
          'missingFields': responseData['missingFields'],
          'message': responseData['message'],
        };
      }

      final responseData = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      return {
        'success': false,
        'error': responseData['message'] ?? 'Failed to verify user data',
      };
    } catch (e) {
      print('[ERROR] Verify user data error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
