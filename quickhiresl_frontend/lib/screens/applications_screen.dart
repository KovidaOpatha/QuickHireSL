import 'package:flutter/material.dart';
import '../services/job_service.dart';
import '../models/application.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/feedback_dialog.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({Key? key}) : super(key: key);

  @override
  _ApplicationsScreenState createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  final JobService _jobService = JobService();
  final _storage = const FlutterSecureStorage();
  List<Application> _applications = [];
  bool _isLoading = true;
  String? _error;
  String? _userId;
  String _selectedFilter = 'all';
  Set<String> _feedbackProvidedApplications = {};

  @override
  void initState() {
    super.initState();
    _loadUserIdAndApplications();
  }

  Future<void> _loadUserIdAndApplications() async {
    final userId = await _storage.read(key: 'user_id');
    setState(() {
      _userId = userId;
    });
    await _loadFeedbackStatus();
    _loadApplications();
  }

  // Load feedback status from secure storage
  Future<void> _loadFeedbackStatus() async {
    try {
      // Get the stored feedback status
      final feedbackStatusJson = await _storage.read(key: 'feedback_status');
      if (feedbackStatusJson != null) {
        final List<dynamic> feedbackStatus = List<dynamic>.from(
            feedbackStatusJson.split(',').where((id) => id.isNotEmpty));

        setState(() {
          _feedbackProvidedApplications =
              Set<String>.from(feedbackStatus.map((id) => id.toString()));
        });
      }
    } catch (e) {
      print('Error loading feedback status: $e');
    }
  }

  // Save feedback status to secure storage
  Future<void> _saveFeedbackStatus() async {
    try {
      await _storage.write(
        key: 'feedback_status',
        value: _feedbackProvidedApplications.join(','),
      );
    } catch (e) {
      print('Error saving feedback status: $e');
    }
  }

  Future<void> _loadApplications() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        setState(() {
          _error = 'Please login to view applications';
          _isLoading = false;
        });
        return;
      }

      final applications = await _jobService.getMyApplications(token);
      setState(() {
        _applications = applications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load applications: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  List<Application> get _filteredApplications {
    if (_selectedFilter == 'all') return _applications;
    return _applications.where((app) => app.status == _selectedFilter).toList();
  }

  Future<void> _showCompletionDialog(Application application) async {
    if (application.status != 'accepted') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Job must be accepted before requesting completion')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request Job Completion'),
        content: Text(_userId == application.applicant.id
            ? 'Are you sure you want to mark this job as completed? This will send a completion request to the employer.'
            : 'Are you sure you want to mark this job as completed? This will send a completion request to the student.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              try {
                final token = await _storage.read(key: 'jwt_token');
                if (token == null) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please login first')),
                  );
                  return;
                }

                await _jobService.requestCompletion(
                  application.id,
                  _userId == application.applicant.id
                      ? 'applicant'
                      : 'jobOwner',
                  token,
                );

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Completion request sent successfully')),
                );
                _loadApplications();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // Handle feedback submission for the given application
  void _handleFeedbackSubmission(String applicationId) async {
    print("DEBUG: Handling feedback submission for application $applicationId");

    // Get the current user's ID for the feedback
    final storage = const FlutterSecureStorage();
    final currentUserId = await storage.read(key: 'user_id');

    if (currentUserId == null) {
      print("DEBUG: Current user ID is null, cannot submit feedback");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unable to identify current user for feedback')),
      );
      return;
    }

    // Find the application in our list
    Application? application;
    try {
      application = _applications.firstWhere(
        (app) => app.id == applicationId,
      );
    } catch (e) {
      print("DEBUG: Could not find application with ID $applicationId: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to find application data')),
      );
      return;
    }

    // After the try-catch block, we know application is not null
    // Define application variables
    String targetUserId;
    bool isJobOwner = false;

    if (currentUserId == application.applicant.id) {
      // Current user is the applicant, target is the job owner
      targetUserId = application.jobOwner.id;
      isJobOwner = false;
      print(
          "DEBUG: Current user is applicant, target is employer: $targetUserId");
    } else {
      // Current user is the job owner, target is the applicant
      targetUserId = application.applicant.id;
      isJobOwner = true;
      print(
          "DEBUG: Current user is employer, target is applicant: $targetUserId");
    }

    if (targetUserId.isEmpty) {
      print("DEBUG: Target user ID is empty");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unable to identify recipient for feedback')),
      );
      return;
    }

    // Show the feedback dialog
    print(
        "DEBUG: Showing feedback dialog for application $applicationId and target $targetUserId");
    showFeedbackDialog(
      context,
      applicationId: applicationId,
      targetUserId: targetUserId,
      isJobOwner: isJobOwner,
      onFeedbackSubmitted: () {
        print(
            "DEBUG: Feedback submitted successfully for application $applicationId");
        setState(() {
          _feedbackProvidedApplications.add(applicationId);
        });
        _saveFeedbackStatus();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF98C9C5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Applications',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedFilter == 'all',
                    onSelected: (bool selected) {
                      setState(() => _selectedFilter = 'all');
                    },
                    backgroundColor: Colors.white,
                    selectedColor: Colors.black.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Colors.black, width: 1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Pending'),
                    selected: _selectedFilter == 'pending',
                    onSelected: (bool selected) {
                      setState(() => _selectedFilter = 'pending');
                    },
                    backgroundColor: Colors.white,
                    selectedColor: Colors.black.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Colors.black, width: 1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Accepted'),
                    selected: _selectedFilter == 'accepted',
                    onSelected: (bool selected) {
                      setState(() => _selectedFilter = 'accepted');
                    },
                    backgroundColor: Colors.white,
                    selectedColor: Colors.black.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Colors.black, width: 1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Rejected'),
                    selected: _selectedFilter == 'rejected',
                    onSelected: (bool selected) {
                      setState(() => _selectedFilter = 'rejected');
                    },
                    backgroundColor: Colors.white,
                    selectedColor: Colors.black.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Colors.black, width: 1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('In Progress'),
                    selected: _selectedFilter == 'completion_requested',
                    onSelected: (bool selected) {
                      setState(() => _selectedFilter = 'completion_requested');
                    },
                    backgroundColor: Colors.white,
                    selectedColor: Colors.black.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Colors.black, width: 1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Completed'),
                    selected: _selectedFilter == 'completed',
                    onSelected: (bool selected) {
                      setState(() => _selectedFilter = 'completed');
                    },
                    backgroundColor: Colors.white,
                    selectedColor: Colors.black.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Colors.black, width: 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadApplications,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _filteredApplications.length,
                      itemBuilder: (context, index) {
                        final application = _filteredApplications[index];
                        final feedbackProvided = _feedbackProvidedApplications
                            .contains(application.id);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.black, width: 1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  application.job.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  application.job.company,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.grey[300]!),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Job Owner",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              application.jobOwner.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.grey[300]!),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Applicant",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              application.applicant.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(application.status),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    application.status.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (application.status == 'accepted')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                _showCompletionDialog(
                                                    application),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.black,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: Text(
                                              _userId ==
                                                      application.applicant.id
                                                  ? 'Request Job Completion'
                                                  : 'Request Student Completion',
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (application.status ==
                                    'completion_requested')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: Colors.black, width: 1),
                                          ),
                                          child: Text(
                                            _userId == application.jobOwner.id
                                                ? 'Student has requested completion confirmation'
                                                : 'Employer has requested completion confirmation',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        if ((_userId ==
                                                    application.jobOwner.id &&
                                                application.completionDetails
                                                        ?.requestedBy ==
                                                    'applicant') ||
                                            (_userId ==
                                                    application.applicant.id &&
                                                application.completionDetails
                                                        ?.requestedBy ==
                                                    'jobOwner'))
                                          ElevatedButton(
                                            onPressed: () =>
                                                _showCompletionDialog(
                                                    application),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.black,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: const Text(
                                              'Confirm Completion',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                if (application.status == 'completed')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16.0),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: Colors.green, width: 1),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.check_circle,
                                                  color: Colors.green),
                                              SizedBox(width: 8),
                                              Text(
                                                'Job Successfully Completed',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (application.completionDetails
                                                  ?.confirmedAt !=
                                              null)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Text(
                                                'Completed on ${_formatDate(application.completionDetails!.confirmedAt!)}',
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 10),
                                          if (!feedbackProvided)
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Row(
                                                children: [
                                                  InkWell(
                                                    onTap: () =>
                                                        _handleFeedbackSubmission(
                                                            application.id),
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16,
                                                          vertical: 10),
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            const LinearGradient(
                                                          colors: [
                                                            Color(0xFF0C8E45),
                                                            Color(0xFF076D32),
                                                          ],
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.3),
                                                            spreadRadius: 1,
                                                            blurRadius: 5,
                                                            offset:
                                                                const Offset(
                                                                    0, 3),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.star,
                                                            color: Colors.white,
                                                            size: 20,
                                                          ),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            'Enter Feedback',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                              letterSpacing:
                                                                  0.5,
                                                              shadows: [
                                                                Shadow(
                                                                  blurRadius:
                                                                      3.0,
                                                                  color: Color(
                                                                      0x4D000000),
                                                                  offset:
                                                                      Offset(
                                                                          0, 1),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          else
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 16,
                                                        vertical: 10),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[200],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      border: Border.all(
                                                          color: Colors
                                                              .grey.shade400,
                                                          width: 1),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(0.1),
                                                          spreadRadius: 1,
                                                          blurRadius: 3,
                                                          offset: const Offset(
                                                              0, 1),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.check_circle,
                                                          color: Colors.grey,
                                                          size: 20,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          'Feedback Submitted',
                                                          style: TextStyle(
                                                            color: Colors.grey,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
