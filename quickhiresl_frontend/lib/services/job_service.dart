import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import '../models/job.dart';
import '../models/application.dart';

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

      final responseData = json.decode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        return Job.fromJson(responseData['data']);
      } else {
        final message = responseData['message'] ?? 'Failed to create job';
        throw Exception(message);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to create job: $e');
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

  // Application related methods
  Future<void> applyForJob(String jobId, String coverLetter, String token) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/applications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'jobId': jobId,
          'coverLetter': coverLetter,
        }),
      );

      print('Apply response: ${response.statusCode} - ${response.body}');

      if (response.statusCode != 201) {
        throw Exception('Failed to apply for job: ${response.body}');
      }
    } catch (e) {
      print('Error applying for job: $e');
      rethrow;
    }
  }

  Future<List<Application>> getJobOwnerApplications(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/applications/owner'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Application.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load applications');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateApplicationStatus(String applicationId, String status, String token) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/applications/$applicationId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update application status');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Application>> getMyApplications(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/applications/my-applications'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Application.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load my applications');
      }
    } catch (e) {
      rethrow;
    }
  }
}
