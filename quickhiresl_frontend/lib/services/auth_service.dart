// // lib/services/auth_service.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// class AuthService {
//   final String baseUrl = 'http://localhost:3000/api';
//   final storage = FlutterSecureStorage();

//   Future<bool> register(String email, String password, String role) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/auth/register'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({'email': email, 'password': password, 'role': role}),
//       );
//       return response.statusCode == 201;
//     } catch (e) {
//       print('Registration error: $e');
//       return false;
//     }
//   }

//   Future<bool> login(String email, String password) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/auth/login'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({'email': email, 'password': password}),
//       );

//       if (response.statusCode == 200) {
//         final token = jsonDecode(response.body)['token'];
//         await storage.write(key: 'jwt_token', value: token);
//         return true;
//       }
//       return false;
//     } catch (e) {
//       print('Login error: $e');
//       return false;
//     }
//   }
// }


// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final String baseUrl = 'http://localhost:3000/api'; // Adjust this URL as needed
  final storage = FlutterSecureStorage();

  // Register user with role
  Future<bool> register(String email, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'role': role, // Include role in registration data
        }),
      );

      if (response.statusCode == 201) {
        print('Registration successful');
        return true; // Return true if registration is successful
      } else {
        print('Registration failed: ${response.body}');
        return false; // Registration failed
      }
    } catch (e) {
      print('Registration error: $e');
      return false; // Handle exception and return false
    }
  }

  // Login user and save JWT token in secure storage
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final token = jsonDecode(response.body)['token'];
        await storage.write(key: 'jwt_token', value: token);
        print('Login successful');
        return true; // Return true if login is successful
      } else {
        print('Login failed: ${response.body}');
        return false; // Login failed
      }
    } catch (e) {
      print('Login error: $e');
      return false; // Handle exception and return false
    }
  }

  // Retrieve the stored JWT token
  Future<String?> getToken() async {
    return await storage.read(key: 'jwt_token'); // Get token from secure storage
  }

  // Logout user by deleting the JWT token from secure storage
  Future<void> logout() async {
    await storage.delete(key: 'jwt_token');
    print('Logged out');
  }
}
