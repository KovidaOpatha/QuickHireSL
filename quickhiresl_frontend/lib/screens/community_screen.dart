import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/job.dart';
import './job_chat_screen.dart';
import '../services/job_service.dart';
import '../services/user_service.dart';
import './home_screen.dart';

class CommunityScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  CommunityScreen({this.onNavigateToTab});

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final JobService _jobService = JobService();
  final UserService _userService = UserService();
  List<Job> jobs = [];
  Map<String, Map<String, dynamic>> jobOwners = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchJobs();
  }

  Future<void> fetchJobs() async {
    setState(() => isLoading = true);
    try {
      final fetchedJobs = await _jobService.getJobs();
      setState(() {
        jobs = fetchedJobs;
        jobs.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
      });

      // Fetch job owner data for each job
      for (var job in jobs) {
        if (job.postedBy != null && job.postedBy!.isNotEmpty) {
          fetchJobOwnerData(job.postedBy!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching jobs: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> fetchJobOwnerData(String userId) async {
    try {
      // Get token from storage
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token');
      
      final response = await http.get(
        Uri.parse('${_userService.baseUrl}/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Add token for authentication
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['profileImage'] != null) {
          data['profilePicture'] =
              _userService.getFullImageUrl(data['profileImage']);
        }

        if (mounted) {
          setState(() {
            jobOwners[userId] = data;
          });
        }
      } else {
        print('Error fetching job owner data: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching job owner data: $e');
    }
  }

  void navigateToJobChat(Job job) {
    // Get job owner data if available
    Map<String, dynamic>? ownerData =
        job.postedBy != null ? jobOwners[job.postedBy] : null;

    // Convert Job object to Map for the chat screen
    final Map<String, dynamic> jobMap = {
      'id': job.id,
      'title': job.title,
      'company': job.company,
      'salary': 'LKR ${job.salary.value}',
      'location': job.location,
      'type': job.employmentType,
      'postedBy': job.postedBy,
      'profilePicture': ownerData?['profilePicture'] ?? ''
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          jobs,
          job: jobMap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          },
        ),
        title: Text('Community'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchJobs,
              child: jobs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.work_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No jobs available',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Pull to refresh',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(8),
                      itemCount: jobs.length,
                      itemBuilder: (context, index) {
                        final job = jobs[index];
                        final hasProfileImage = job.postedBy != null &&
                            jobOwners[job.postedBy] != null &&
                            jobOwners[job.postedBy]!['profilePicture'] !=
                                null &&
                            jobOwners[job.postedBy]!['profilePicture']
                                .toString()
                                .isNotEmpty;

                        return Card(
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: InkWell(
                            onTap: () => navigateToJobChat(job),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      hasProfileImage
                                          ? CircleAvatar(
                                              backgroundImage: NetworkImage(
                                                jobOwners[job.postedBy]![
                                                    'profilePicture'],
                                              ),
                                              backgroundColor: Theme.of(context)
                                                  .primaryColor,
                                              onBackgroundImageError: (_, __) {
                                                // Fallback if image fails to load
                                              },
                                            )
                                          : CircleAvatar(
                                              backgroundColor: Theme.of(context)
                                                  .primaryColor,
                                              child: Text(
                                                job.company[0].toUpperCase(),
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              job.title,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              job.company,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.chat_bubble_outline),
                                        onPressed: () => navigateToJobChat(job),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on,
                                          size: 16, color: Colors.grey[600]),
                                      SizedBox(width: 4),
                                      Text(
                                        job.location,
                                        style:
                                            TextStyle(color: Colors.grey[600]),
                                      ),
                                      SizedBox(width: 16),
                                      Icon(Icons.work,
                                          size: 16, color: Colors.grey[600]),
                                      SizedBox(width: 4),
                                      Text(
                                        job.employmentType,
                                        style:
                                            TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'LKR ${job.salary.value}',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
      // Removed floating action button
    );
  }
}
