import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/job.dart';
import './job_chat_screen.dart';
import '../services/job_service.dart';
import '../services/user_service.dart';
import '../utils/profile_image_util.dart';
import './home_screen.dart';
import './notification_screen.dart';

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
        
        // Use ProfileImageUtil to properly format the profile image URL
        if (data['profileImage'] != null) {
          data['profilePicture'] = ProfileImageUtil.getFullImageUrl(data['profileImage']);
          print('Profile image URL for $userId: ${data['profilePicture']}');
        } else {
          print('No profile image found for user $userId');
          data['profilePicture'] = '';
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
      backgroundColor: const Color(0xFF98C9C5), // Light teal background color
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true, // Center the title
        title: const Text(
          'Community',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold, // Make title bold
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (widget.onNavigateToTab != null) {
              widget.onNavigateToTab!(0); // Navigate to home tab (index 0)
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            await fetchJobs();
          },
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : jobs.isEmpty
                  ? const Center(
                      child: Text(
                        'No jobs available in the community.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF757575), // Grey 600
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: jobs.length,
                      itemBuilder: (context, index) {
                        final job = jobs[index];
                        final hasProfileImage = job.postedBy != null &&
                            jobOwners[job.postedBy] != null &&
                            jobOwners[job.postedBy]!['profilePicture'] != null &&
                            jobOwners[job.postedBy]!['profilePicture']
                                .toString()
                                .isNotEmpty;

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () => navigateToJobChat(job),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Profile image with improved error handling
                                      hasProfileImage
                                          ? ProfileImageUtil.circularProfileImage(
                                              imageUrl: jobOwners[job.postedBy]!['profilePicture'],
                                              radius: 24,
                                              fallbackText: job.company,
                                              backgroundColor: Theme.of(context).primaryColor,
                                              textColor: Colors.white,
                                            )
                                          : CircleAvatar(
                                              backgroundColor: Theme.of(context).primaryColor,
                                              radius: 24,
                                              child: Text(
                                                job.company.isNotEmpty ? job.company[0].toUpperCase() : '?',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              job.title,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              job.company,
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.message_outlined, size: 20),
                                        onPressed: () => navigateToJobChat(job),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on,
                                          size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        job.location,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(Icons.work,
                                          size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        job.employmentType,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'LKR ${job.salary.value}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    job.description,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Posted ${_formatDate(job.createdAt)}',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                      const Text(
                                        'Tap to chat',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}
