import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import '../models/job.dart';
import '../models/application.dart';

class JobService extends ChangeNotifier {
  final String _baseUrl = '${Config.apiUrl}/jobs';

  Future<Job> createJob(Map<String, dynamic> jobData, String token) async {
    try {
      print('Making request to: $_baseUrl');
      print('Request data: ${json.encode(jobData)}');

      final response = await http.post(
        Uri.parse(_baseUrl),
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
      if (employmentType != null)
        queryParams['employmentType'] = employmentType;
      if (experienceLevel != null)
        queryParams['experienceLevel'] = experienceLevel;
      if (salaryMin != null) queryParams['salaryMin'] = salaryMin.toString();
      if (salaryMax != null) queryParams['salaryMax'] = salaryMax.toString();
      if (search != null) queryParams['search'] = search;

      final response = await http.get(
        Uri.parse(_baseUrl).replace(queryParameters: queryParams),
      );

      print('Jobs response: ${response.statusCode}');
      print('Response body: ${response.body}');

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
      final response = await http.get(Uri.parse('$_baseUrl/$id'));

      print('Job response: ${response.statusCode}');
      print('Response body: ${response.body}');

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

  Future<Job> updateJob(
      String id, Map<String, dynamic> jobData, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(jobData),
      );

      print('Update job response: ${response.statusCode}');
      print('Response body: ${response.body}');

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
        Uri.parse('$_baseUrl/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Delete job response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete job: ${response.body}');
      }
    } catch (e) {
      print('Error in deleteJob: $e');
      rethrow;
    }
  }

  // Application related methods
  Future<void> applyForJob(
      String jobId, String coverLetter, String token) async {
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

      print('Apply response: ${response.statusCode}');
      print('Response body: ${response.body}');

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
        Uri.parse('${Config.apiUrl}/applications/owner'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Job owner applications response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Check if the response has a data field that contains the applications
        if (responseData.containsKey('data')) {
          final List<dynamic> applicationsJson = responseData['data'];
          print('Parsed applications: $applicationsJson');
          return applicationsJson
              .map((json) => Application.fromJson(json))
              .toList();
        } else {
          print('Response data structure: $responseData');
          throw Exception('Invalid response format: missing data field');
        }
      } else {
        throw Exception('Failed to load applications: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getJobOwnerApplications: $e');
      rethrow;
    }
  }

  // Get completed jobs for a job owner
  Future<List<Application>> getCompletedJobs(String token) async {
    try {
      // Use the existing endpoint and filter completed applications client-side
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/applications/owner'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Job owner applications response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData.containsKey('data')) {
          final List<dynamic> applicationsJson = responseData['data'];

          // Filter only completed applications
          final List<Application> allApplications = applicationsJson
              .map((json) => Application.fromJson(json))
              .toList();

          return allApplications
              .where((app) => app.status == 'completed')
              .toList();
        } else {
          throw Exception('Invalid response format: missing data field');
        }
      } else {
        throw Exception(
            'Failed to load completed jobs: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getCompletedJobs: $e');
      rethrow;
    }
  }

  // Get all previous jobs for a job owner (both active and completed)
  Future<List<Job>> getPreviousJobs(String token) async {
    try {
      // Get all jobs posted by the current user
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/jobs?postedBy=me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Previous jobs response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> jobsJson = responseData['data'];
          return jobsJson.map((json) => Job.fromJson(json)).toList();
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load previous jobs: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getPreviousJobs: $e');
      rethrow;
    }
  }

  Future<void> updateApplicationStatus(
      String applicationId, String status, String token) async {
    try {
      print(
          '[DEBUG] Updating application status: ID=$applicationId, status=$status');
      final response = await http.patch(
        Uri.parse('${Config.apiUrl}/applications/$applicationId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );

      print('[DEBUG] Update status response: ${response.statusCode}');
      print('[DEBUG] Response body: ${response.body}');

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Failed to update application status');
      }
    } catch (e) {
      print('[ERROR] Failed to update application status: $e');
      rethrow;
    }
  }

  // Submit rating for a job
  Future<void> submitJobRating(String applicationId, int rating,
      String feedback, String targetUserId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/feedback'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'rating': rating,
          'feedback': feedback,
          'applicationId': applicationId,
          'targetUserId': targetUserId,
        }),
      );

      print('Rating submission response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 201 && response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to submit rating');
      }
    } catch (e) {
      print('Error in submitJobRating: $e');
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

      print('My applications response: ${response.statusCode}');
      print('Response body: ${response.body}');

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

  Future<void> requestCompletion(
      String applicationId, String requestedBy, String token) async {
    try {
      print(
          '[DEBUG] Requesting completion: ID=$applicationId, requestedBy=$requestedBy');
      final response = await http.post(
        Uri.parse(
            '${Config.apiUrl}/applications/$applicationId/request-completion'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'requestedBy': requestedBy}),
      );

      print('[DEBUG] Request completion response: ${response.statusCode}');
      print('[DEBUG] Response body: ${response.body}');

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to request completion');
      }
    } catch (e) {
      print('[ERROR] Failed to request completion: $e');
      rethrow;
    }
  }

  Future<void> confirmCompletion(String applicationId, String token) async {
    try {
      print('[DEBUG] Confirming completion: ID=$applicationId');
      final response = await http.post(
        Uri.parse(
            '${Config.apiUrl}/applications/$applicationId/confirm-completion'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[DEBUG] Confirm completion response: ${response.statusCode}');
      print('[DEBUG] Response body: ${response.body}');

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to confirm completion');
      }
    } catch (e) {
      print('[ERROR] Failed to confirm completion: $e');
      rethrow;
    }
  }
}
