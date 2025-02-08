// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final String baseUrl = 'http://localhost:3000/api';
  final storage = FlutterSecureStorage();

  // Register user (email and password only)
  Future<Map<String, dynamic>> register(String email, String password) async {
    try {
      print('[Register] Attempting registration for email: $email');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('[Register] Response status: ${response.statusCode}');
      print('[Register] Response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final userId = responseData['userId'];
        
        print('[Register] User ID from registration: $userId');
        
        // Store the user ID
        if (userId != null) {
          await storage.write(key: 'user_id', value: userId);
          print('[Register] Stored user ID in secure storage');
          
          // Automatically log in after successful registration
          print('[Register] Attempting automatic login after registration');
          final loginResponse = await login(email, password);
          print('[Register] Auto-login response: $loginResponse');
          
          if (loginResponse['success']) {
            print('[Register] Auto-login successful');
            return {
              'success': true,
              'userId': userId,
            };
          } else {
            print('[ERROR] Auto-login failed');
          }
        }
        
        return {
          'success': true,
          'userId': userId,
        };
      } else {
        print('[ERROR] Registration failed: ${response.body}');
        return {
          'success': false,
          'error': jsonDecode(response.body)['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      print('[ERROR] Registration error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Login user and save JWT token in secure storage
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('[Login] Attempting login for email: $email');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('[Login] Response status: ${response.statusCode}');
      print('[Login] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Extract data from response
        final token = responseData['token'];
        final userId = responseData['userId'];
        final role = responseData['role'];

        print('[Login] Token received: ${token != null}');
        print('[Login] User ID received: $userId');
        print('[Login] Role received: $role');

        if (token == null) {
          print('[ERROR] No token received from server');
          return {
            'success': false,
            'error': 'No token received from server'
          };
        }

        // Store all the data
        await Future.wait([
          storage.write(key: 'jwt_token', value: token),
          storage.write(key: 'user_id', value: userId),
          if (role != null) storage.write(key: 'user_role', value: role),
        ]);

        // Verify token was stored
        final storedToken = await storage.read(key: 'jwt_token');
        if (storedToken == null) {
          print('[ERROR] Failed to store token');
          return {
            'success': false,
            'error': 'Failed to store authentication token'
          };
        }

        print('[Login] Authentication successful - Token stored');
        return {
          'success': true,
          'userId': userId,
          'role': role,
        };
      } else {
        print('[ERROR] Login failed: ${response.body}');
        return {
          'success': false,
          'error': jsonDecode(response.body)['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      print('[ERROR] Login error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Retrieve the stored JWT token
  Future<String?> getToken() async {
    final token = await storage.read(key: 'jwt_token');
    print('[Auth] Retrieved token: ${token != null}');
    return token;
  }

  // Retrieve the stored user ID
  Future<String?> getUserId() async {
    final userId = await storage.read(key: 'user_id');
    print('[Auth] Retrieved user ID: $userId');
    return userId;
  }

  // Retrieve the stored user role
  Future<String?> getUserRole() async {
    final role = await storage.read(key: 'user_role');
    print('[Auth] Retrieved role: $role');
    return role;
  }

  // Logout user by deleting all stored data
  Future<void> logout() async {
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'user_id');
    await storage.delete(key: 'user_role');
    print('[Auth] Logged out and cleared all stored data');
  }

  // Update user role and details
  Future<bool> updateRole(String userId, String role, Map<String, dynamic> details) async {
    try {
      print('[UpdateRole] Attempting to update role for user: $userId');
      print('[UpdateRole] Role to set: $role');
      print('[UpdateRole] Details: $details');

      // Get the JWT token
      final token = await storage.read(key: 'jwt_token');
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
        await storage.write(key: 'user_role', value: role);
        print('[UpdateRole] Role update successful');
        return true;
      } else {
        print('[ERROR] Role update failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('[ERROR] Role update error: $e');
      return false;
    }
  }
}
