import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/config.dart';

class JobMatchingService {
  final String baseUrl = Config.apiUrl;
  final storage = const FlutterSecureStorage();

  // Get token from storage
  Future<String?> _getToken() async {
    return await storage.read(key: 'jwt_token');
  }

  // Get matching jobs for a user
  Future<Map<String, dynamic>> getMatchingJobs(
    String userId, {
    int limit = 10,
    int minScore = 30,
    bool includeDetails = false,
    String sortBy = 'score', // 'score', 'date', 'salary'
    String sortOrder = 'desc', // 'asc', 'desc'
    String? location,
    String? category,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Authentication token not found',
        };
      }

      // Build query parameters
      final queryParams = {
        'limit': limit.toString(),
        'minScore': minScore.toString(),
        'includeDetails': includeDetails.toString(),
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      // Add optional parameters if provided
      if (location != null) queryParams['location'] = location;
      if (category != null) queryParams['category'] = category;

      // Build URL with query parameters
      final uri = Uri.parse('$baseUrl/matching/users/$userId/matching-jobs')
          .replace(queryParameters: queryParams);

      print('[JobMatchingService] Getting matching jobs for user: $userId');
      print('[JobMatchingService] Request URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[JobMatchingService] Response status: ${response.statusCode}');
      print('[JobMatchingService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'count': responseData['count'],
          'jobs': responseData['data'],
        };
      }

      final responseData = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      return {
        'success': false,
        'error': responseData['message'] ?? 'Failed to get matching jobs',
      };
    } catch (e) {
      print('[ERROR] Get matching jobs error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Calculate match score for a specific job
  Future<Map<String, dynamic>> calculateJobMatch(String userId, String jobId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Authentication token not found',
        };
      }

      print('[JobMatchingService] Calculating match for user: $userId and job: $jobId');

      final response = await http.get(
        Uri.parse('$baseUrl/matching/users/$userId/jobs/$jobId/match'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[JobMatchingService] Response status: ${response.statusCode}');
      print('[JobMatchingService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'jobId': responseData['jobId'],
          'title': responseData['title'],
          'company': responseData['company'],
          'matchScore': responseData['matchScore'],
          'matchReasons': responseData['matchReasons'],
          'matchDetails': responseData['matchDetails'],
        };
      }

      final responseData = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      return {
        'success': false,
        'error': responseData['message'] ?? 'Failed to calculate job match',
      };
    } catch (e) {
      print('[ERROR] Calculate job match error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
