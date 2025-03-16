import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/config.dart';

class AvailabilityService {
  final String baseUrl = Config.apiUrl;
  final storage = const FlutterSecureStorage();

  // Get token from storage
  Future<String?> _getToken() async {
    return await storage.read(key: 'jwt_token');
  }

  // Get all availability dates for a user
  Future<Map<String, dynamic>> getUserAvailability(String userId) async {
    try {
      final token = await _getToken();
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

      print('[GetUserAvailability] Response status: ${response.statusCode}');
      print('[GetUserAvailability] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final availability = responseData['studentDetails']?['availability'] ?? [];
        
        return {
          'success': true,
          'availability': availability,
        };
      }

      final responseData = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      return {
        'success': false,
        'error': responseData['message'] ?? 'Failed to fetch availability',
      };
    } catch (e) {
      print('[ERROR] Get availability error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Add a new availability date
  Future<Map<String, dynamic>> addAvailabilityDate(String userId, Map<String, dynamic> availabilityData) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Authentication token not found',
        };
      }

      print('[AddAvailability] Adding availability for user: $userId');
      print('[AddAvailability] Availability data: $availabilityData');

      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/availability'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(availabilityData),
      );

      print('[AddAvailability] Response status: ${response.statusCode}');
      print('[AddAvailability] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Availability added successfully',
          'availability': responseData['availability'],
        };
      }

      final responseData = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      return {
        'success': false,
        'error': responseData['message'] ?? 'Failed to add availability',
      };
    } catch (e) {
      print('[ERROR] Add availability error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Remove an availability date
  Future<Map<String, dynamic>> removeAvailabilityDate(String userId, String dateId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Authentication token not found',
        };
      }

      print('[RemoveAvailability] Removing availability for user: $userId');
      print('[RemoveAvailability] Date ID: $dateId');

      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId/availability/$dateId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[RemoveAvailability] Response status: ${response.statusCode}');
      print('[RemoveAvailability] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Availability removed successfully',
          'availability': responseData['availability'],
        };
      }

      final responseData = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      return {
        'success': false,
        'error': responseData['message'] ?? 'Failed to remove availability',
      };
    } catch (e) {
      print('[ERROR] Remove availability error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Update all availability dates
  Future<Map<String, dynamic>> updateAvailability(String userId, List<Map<String, dynamic>> availabilityList) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Authentication token not found',
        };
      }

      print('[UpdateAvailability] Updating availability for user: $userId');
      print('[UpdateAvailability] Availability data: $availabilityList');

      final response = await http.patch(
        Uri.parse('$baseUrl/users/$userId/availability'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'availability': availabilityList,
        }),
      );

      print('[UpdateAvailability] Response status: ${response.statusCode}');
      print('[UpdateAvailability] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Availability updated successfully',
          'availability': responseData['availability'],
        };
      }

      final responseData = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      return {
        'success': false,
        'error': responseData['message'] ?? 'Failed to update availability',
      };
    } catch (e) {
      print('[ERROR] Update availability error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
