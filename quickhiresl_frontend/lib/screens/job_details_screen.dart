import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/job.dart';
import '../services/job_service.dart';
import '../services/user_service.dart';
import 'job_application_screen.dart';
import 'job_chat_screen.dart';

class JobDetailsScreen extends StatefulWidget {
  final Job job;

  const JobDetailsScreen({Key? key, required this.job}) : super(key: key);

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final JobService _jobService = JobService();
  final UserService _userService = UserService();
  final _storage = const FlutterSecureStorage();
  bool _isApplying = false;
  Map<String, dynamic> jobOwnerData = {};
  bool isJobOwnerLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchJobOwnerData();
  }

  Future<void> _fetchJobOwnerData() async {
    setState(() => isJobOwnerLoading = true);

    if (widget.job.postedBy == null || widget.job.postedBy!.isEmpty) {
      print('No job owner ID available for job: ${widget.job.id}');
      setState(() {
        isJobOwnerLoading = false;
        jobOwnerData = {
          'fullName': widget.job.company,
          'profilePicture': null, // Explicitly set to null to avoid errors
        };
      });
      return;
    }

    try {
      final token = await _storage.read(key: 'jwt_token');

      print('Fetching job owner data for ID: ${widget.job.postedBy} (Job ID: ${widget.job.id})');

      final response = await http.get(
        Uri.parse('${_userService.baseUrl}/users/${widget.job.postedBy}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('API Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Job Owner Data: $data');

        if (data['profileImage'] != null && data['profileImage'].toString().isNotEmpty) {
          data['profilePicture'] =
              _userService.getFullImageUrl(data['profileImage']);
          print('Profile Picture URL: ${data['profilePicture']}');
        } else {
          print('No profile image found for user');
          data['profilePicture'] = null;
        }

        setState(() {
          jobOwnerData = data;
          isJobOwnerLoading = false;
        });
      } else {
        print(
            'Failed to fetch job owner data: ${response.statusCode} - ${response.body}');
        setState(() {
          isJobOwnerLoading = false;
          jobOwnerData = {
            'fullName': widget.job.company,
            'profilePicture': null,
          };
        });
      }
    } catch (e) {
      print('Error fetching job owner data: $e');
      setState(() {
        isJobOwnerLoading = false;
        jobOwnerData = {
          'fullName': widget.job.company,
          'profilePicture': null,
        };
      });
    }
  }

  Widget _buildInfoItem({
    required String title,
    required String value,
    required IconData icon,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? const Color(0xFF98C9C5)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor ?? const Color(0xFF98C9C5),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String requirement) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: const Color(0xFF98C9C5),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              requirement,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDefaultCompanyBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF98C9C5),
            const Color(0xFF98C9C5).withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business,
              size: 50,
              color: Colors.white.withOpacity(0.7),
            ),
            const SizedBox(height: 10),
            if (widget.job.company.isNotEmpty)
              Text(
                widget.job.company,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF98C9C5),
      body: CustomScrollView(
        slivers: [
          // Custom app bar with profile picture
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background with profile picture
                  !isJobOwnerLoading &&
                          jobOwnerData.isNotEmpty &&
                          jobOwnerData['profilePicture'] != null &&
                          jobOwnerData['profilePicture'].toString().isNotEmpty
                      ? Image.network(
                          jobOwnerData['profilePicture'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading profile image: $error');
                            return _buildDefaultCompanyBackground();
                          },
                        )
                      : _buildDefaultCompanyBackground(),

                  // Overlay gradient for better text visibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),

                  // Decorative wave pattern
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: ClipPath(
                      clipper: WaveClipper(),
                      child: Container(
                        height: 80,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),

                  // Job title and company info
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.job.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 3,
                                color: Colors.black45,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              widget.job.company,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (jobOwnerData.isNotEmpty &&
                                jobOwnerData['fullName'] != null) ...[
                              const Text(
                                ' • ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                jobOwnerData['fullName'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Job details content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Job details section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildDetailItem(
                                icon: Icons.attach_money,
                                title: 'Salary',
                                value:
                                    'LKR ${widget.job.salary.min} - ${widget.job.salary.max}',
                                iconColor: Colors.green,
                              ),
                              _buildDetailItem(
                                icon: Icons.work,
                                title: 'Type',
                                value: widget.job.employmentType,
                                iconColor: Colors.blue,
                              ),
                              _buildDetailItem(
                                icon: Icons.trending_up,
                                title: 'Level',
                                value: widget.job.experienceLevel,
                                iconColor: Colors.orange,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: const Color(0xFF98C9C5),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.job.location,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Job description
                    const Text(
                      'Job Description',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.job.description,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),

                    // Requirements
                    if (widget.job.requirements.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Requirements',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...widget.job.requirements
                          .map((req) => _buildRequirementItem(req))
                          .toList(),
                    ],

                    const SizedBox(height: 30),

                    // Apply button
                    Center(
                      child: Column(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: ElevatedButton(
                              onPressed: _isApplying ? null : _applyForJob,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 3,
                              ),
                              child: _isApplying
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Apply Now',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('Discuss Job'),
                              onPressed: () {
                                // Convert Job object to Map for the chat screen
                                final Map<String, dynamic> jobMap = {
                                  'id': widget.job.id,
                                  'title': widget.job.title,
                                  'company': widget.job.company,
                                  'salary':
                                      'LKR ${widget.job.salary.min} - ${widget.job.salary.max}',
                                  'location': widget.job.location,
                                  'type': widget.job.employmentType,
                                  'postedBy': widget.job.postedBy
                                };

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      [widget.job],
                                      job: jobMap,
                                    ),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                side:
                                    const BorderSide(color: Color(0xFF98C9C5)),
                                foregroundColor: const Color(0xFF98C9C5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyForJob() async {
    setState(() => _isApplying = true);
    try {
      final email = await _storage.read(key: 'email');
      if (email != null && mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobApplicationScreen(
              jobTitle: widget.job.title,
              salary: 'LKR ${widget.job.salary.min} - ${widget.job.salary.max}',
              email: email,
              jobOwnerEmail: widget.job.postedBy ?? '',
            ),
          ),
        );
        if (result == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to apply for jobs'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }
}

// Custom clipper for wave effect
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);

    final firstControlPoint = Offset(size.width * 0.75, size.height - 30);
    final firstEndPoint = Offset(size.width * 0.5, size.height - 15);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    final secondControlPoint = Offset(size.width * 0.25, size.height);
    final secondEndPoint = Offset(0, size.height - 20);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
