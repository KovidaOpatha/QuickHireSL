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
    _loadApplications();
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

                // Show the feedback dialog after confirming job completion
                showFeedbackDialog(context);
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

  Future<void> _showConfirmationDialog(Application application) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Job Completion'),
        content: const Text(
            'Are you sure you want to confirm this job as completed? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close the confirmation dialog
              setState(() => _isLoading = true);

              try {
                final token = await _storage.read(key: 'jwt_token');
                if (token == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please login first')),
                    );
                  }
                  return;
                }

                await _jobService.confirmCompletion(application.id, token);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Job completion confirmed successfully')),
                  );
                  _loadApplications();
                }

                // Show the feedback dialog after confirming job completion
                showFeedbackDialog(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
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
                    selectedColor: const Color(0xFF98C9C5).withOpacity(0.5),
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
                    selectedColor: const Color(0xFF98C9C5).withOpacity(0.5),
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
                    selectedColor: const Color(0xFF98C9C5).withOpacity(0.5),
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
                    selectedColor: const Color(0xFF98C9C5).withOpacity(0.5),
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
                    selectedColor: const Color(0xFF98C9C5).withOpacity(0.5),
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
                    selectedColor: const Color(0xFF98C9C5).withOpacity(0.5),
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
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.black, width: 1),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16.0),
                            title: Text(
                              application.job.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  application.job.company,
                                  style: const TextStyle(fontSize: 16),
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
                                            color: const Color(0xFF98C9C5)
                                                .withOpacity(0.2),
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
                                                _showConfirmationDialog(
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
                                          const Row(
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
      case 'completion_requested':
        return Colors.blue;
      case 'completed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
