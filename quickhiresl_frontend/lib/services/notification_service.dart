import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import '../services/auth_service.dart';

class NotificationService {
  final AuthService _authService = AuthService();
  final String baseUrl = Config.apiUrl;

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      throw Exception('Error getting notifications: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read');
      }
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/notifications/mark-all-read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark all notifications as read');
      }
    } catch (e) {
      throw Exception('Error marking all notifications as read: $e');
    }
  }
}
