import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/job.dart';
import '../services/job_service.dart';
import '../services/user_service.dart';
import '../widgets/rating_display.dart';
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
  bool _isDeleting = false;
  Map<String, dynamic> jobOwnerData = {};
  bool isJobOwnerLoading = true;
  int _ownerRating = 0;
  int _completedJobs = 0;
  String _currentUserId = '';
  bool _isJobOwner = false;

  @override
  void initState() {
    super.initState();
    _fetchJobOwnerData();
    _checkIfJobOwner();
  }

  Future<void> _checkIfJobOwner() async {
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId != null) {
        setState(() {
          _currentUserId = userId;
          _isJobOwner = widget.job.postedBy == userId;
        });
      }
    } catch (e) {
      print('Error checking job owner: $e');
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTimeSlot(TimeSlot slot) {
    return '${slot.startTime} - ${slot.endTime}';
  }

  Widget _buildAvailableDateItem(AvailableDate date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF98C9C5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Color(0xFF98C9C5),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(date.date),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                date.isFullDay
                    ? const Text(
                        'Full Day',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: date.timeSlots
                            .map((slot) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2.0),
                                  child: Text(
                                    _formatTimeSlot(slot),
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                ))
                            .toList(),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
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

      print(
          'Fetching job owner data for ID: ${widget.job.postedBy} (Job ID: ${widget.job.id})');

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

        if (data['profileImage'] != null &&
            data['profileImage'].toString().isNotEmpty) {
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
          _ownerRating = data['rating'] ?? 0;
          _completedJobs = data['completedJobs'] ?? 0;
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? Colors.blue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor ?? Colors.blue,
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
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
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
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
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

  // Helper method to safely parse rating values
  double _parseRating(dynamic rating) {
    if (rating == null) return 0.0;
    if (rating is int) return rating.toDouble();
    if (rating is double) return rating;
    try {
      return double.parse(rating.toString());
    } catch (e) {
      print('Error parsing rating: $e');
      return 0.0;
    }
  }

  Future<void> _deleteJob() async {
    if (!_isJobOwner) return;
    
    // Check if job ID is null
    if (widget.job.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot delete job: Job ID is missing'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isDeleting = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Job'),
          content: const Text('Are you sure you want to delete this job? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Use non-null assertion operator since we've already checked it's not null
        final success = await _jobService.deleteJob(widget.job.id!);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate job was deleted
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete job: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          // Custom app bar with company banner
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF98C9C5),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
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
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: const [0.4, 1.0],
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
                            fontSize: 24,
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
                        Text(
                          widget.job.company,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Job details content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Key details section with icons
                  Container(
                    padding: const EdgeInsets.all(20),
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
                      children: [
                        // Salary, Type, Level row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildDetailItem(
                              icon: Icons.attach_money,
                              title: 'Salary',
                              value: 'LKR ${widget.job.salary.value}',
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

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 10),

                        // Location and Category
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoItem(
                                icon: Icons.location_on,
                                title: 'Location',
                                value: widget.job.location,
                                iconColor: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildInfoItem(
                                icon: Icons.category,
                                title: 'Category',
                                value: widget.job.category.isNotEmpty
                                    ? widget.job.category
                                    : 'Not specified',
                                iconColor: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Job Owner Information
                  Container(
                    padding: const EdgeInsets.all(20),
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
                        Text(
                          'Job Owner',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Star rating display
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < _ownerRating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 20,
                                );
                              }),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _ownerRating > 0
                                  ? '$_ownerRating.0'
                                  : 'No ratings',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (isJobOwnerLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (jobOwnerData.isNotEmpty)
                          Row(
                            children: [
                              // Job Owner Avatar
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.grey[300],
                                backgroundImage:
                                    jobOwnerData['profilePicture'] != null &&
                                            jobOwnerData['profilePicture']
                                                .toString()
                                                .isNotEmpty
                                        ? NetworkImage(
                                            jobOwnerData['profilePicture'])
                                        : null,
                                child: jobOwnerData['profilePicture'] == null ||
                                        jobOwnerData['profilePicture']
                                            .toString()
                                            .isEmpty
                                    ? const Icon(Icons.person,
                                        size: 30, color: Colors.grey)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              // Job Owner Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${jobOwnerData['firstName'] ?? ''} ${jobOwnerData['lastName'] ?? ''}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Rating display
                                    RatingDisplay(
                                      rating:
                                          _parseRating(jobOwnerData['rating']),
                                      size: 20,
                                      showText: false,
                                      compact: true,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Completed ${_completedJobs} jobs",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          const Text("Job owner information not available"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Job description
                  Container(
                    padding: const EdgeInsets.all(20),
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
                        const Text(
                          'Job Description',
                          style: TextStyle(
                            fontSize: 18,
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
                      ],
                    ),
                  ),

                  // Requirements
                  if (widget.job.requirements.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
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
                          const Text(
                            'Requirements',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...widget.job.requirements
                              .map((req) => _buildRequirementItem(req))
                              .toList(),
                        ],
                      ),
                    ),
                  ],

                  // Available Dates
                  if (widget.job.availableDates.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
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
                          const Text(
                            'Available Dates',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...widget.job.availableDates
                              .map((date) => _buildAvailableDateItem(date))
                              .toList(),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isApplying ? null : _applyForJob,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF98C9C5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isApplying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Apply Now',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Delete button (only visible for job owner)
                  if (_isJobOwner) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isDeleting ? null : _deleteJob,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isDeleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.delete, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete Job',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ],
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
      final token = await _storage.read(key: 'jwt_token');
      final email = await _storage.read(key: 'email');

      if (token != null && email != null && mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobApplicationScreen(
              jobTitle: widget.job.title,
              salary: 'LKR ${widget.job.salary.value}',
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
              content: Text(
                  'Please login to apply for jobs. Go to Profile tab to login.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
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

  void _navigateToChat() {
    // Convert Job object to Map for the chat screen
    final Map<String, dynamic> jobMap = {
      'id': widget.job.id,
      'title': widget.job.title,
      'company': widget.job.company,
      'salary': 'LKR ${widget.job.salary.value}',
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
