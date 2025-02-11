import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import '../models/job.dart';

class JobService {
  final String baseUrl = '${Config.apiUrl}/jobs';

  Future<Job> createJob(Map<String, dynamic> jobData, String token) async {
    try {
      print('Making request to: $baseUrl');
      print('Request data: ${json.encode(jobData)}');
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(jobData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return Job.fromJson(responseData['data']);
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to create job: ${response.body}');
      }
    } catch (e) {
      print('Error in createJob: $e');
      rethrow;
    }
  }

  Future<List<Job>> getJobs({
    String? location,
    String? employmentType,
    String? experienceLevel,
    int? salaryMin,
    int? salaryMax,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (location != null) queryParams['location'] = location;
      if (employmentType != null) queryParams['employmentType'] = employmentType;
      if (experienceLevel != null) queryParams['experienceLevel'] = experienceLevel;
      if (salaryMin != null) queryParams['salaryMin'] = salaryMin.toString();
      if (salaryMax != null) queryParams['salaryMax'] = salaryMax.toString();
      if (search != null) queryParams['search'] = search;

      final response = await http.get(
        Uri.parse(baseUrl).replace(queryParameters: queryParams),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> jobsJson = responseData['data'];
          return jobsJson.map((job) => Job.fromJson(job)).toList();
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load jobs: ${response.body}');
      }
    } catch (e) {
      print('Error in getJobs: $e');
      rethrow;
    }
  }

  Future<Job> getJob(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$id'));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return Job.fromJson(responseData['data']);
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load job: ${response.body}');
      }
    } catch (e) {
      print('Error in getJob: $e');
      rethrow;
    }
  }

  Future<Job> updateJob(String id, Map<String, dynamic> jobData, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(jobData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return Job.fromJson(responseData['data']);
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to update job: ${response.body}');
      }
    } catch (e) {
      print('Error in updateJob: $e');
      rethrow;
    }
  }

  Future<void> deleteJob(String id, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete job: ${response.body}');
      }
    } catch (e) {
      print('Error in deleteJob: $e');
      rethrow;
    }
  }
}
