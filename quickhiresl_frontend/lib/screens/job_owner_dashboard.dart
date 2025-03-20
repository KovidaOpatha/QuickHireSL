import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import '../services/job_service.dart';
import '../services/auth_service.dart';
import '../models/application.dart';
import 'applicant_details_screen.dart';
import '../widgets/feedback_dialog.dart';
import 'previous_jobs_screen.dart'; // Import the PreviousJobsScreen

class JobOwnerDashboard extends StatefulWidget {
  const JobOwnerDashboard({Key? key}) : super(key: key);

  @override
  _JobOwnerDashboardState createState() => _JobOwnerDashboardState();
}

class _JobOwnerDashboardState extends State<JobOwnerDashboard> {
  List<Application> _applications = [];
  bool _isLoading = true;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    try {
      setState(() {
        _isLoading = true;
        _applications = [];
      });

      final token = await _authService.getToken();
      if (token == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to continue')),
          );
          return;
        }
      }

      final jobService =
          provider.Provider.of<JobService>(context, listen: false);
      final applications = await jobService.getJobOwnerApplications(token!);

      setState(() {
        _applications = applications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _applications = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load applications: $e')),
        );
      }
    }
  }

  Future<void> _updateApplicationStatus(
      String applicationId, String status) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to continue')),
          );
          return;
        }
      }

      final jobService =
          provider.Provider.of<JobService>(context, listen: false);
      await jobService.updateApplicationStatus(applicationId, status, token!);
      await _loadApplications(); // Reload the list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  Future<void> _confirmCompletion(
      String applicationId, Application application) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to continue')),
          );
          return;
        }
      }

      final jobService =
          provider.Provider.of<JobService>(context, listen: false);
      await jobService.confirmCompletion(applicationId, token!);
      await _loadApplications(); // Reload the list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Job completion confirmed successfully')),
        );
      }

      // Show the feedback dialog after confirming the completion
      if (mounted) {
        showFeedbackDialog(
          context,
          isJobOwner: true,
          applicationId: applicationId,
          targetUserId: application.applicant.id,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to confirm completion: $e')),
        );
      }
    }
  }

  Future<void> _showConfirmationDialog(Application application) async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Job Completion'),
        content: const Text(
            'Are you sure you want to confirm this job as completed? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _confirmCompletion(application.id, application);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
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
          'Job Owner Dashboard',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Previous Jobs',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PreviousJobsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _applications.isEmpty
              ? const Center(child: Text('No applications yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _applications.length,
                  itemBuilder: (context, index) {
                    final application = _applications[index];

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
                              'Job: ${application.job.title}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Applicant: ${application.applicant.name}',
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
                            if (application.status == 'completion_requested')
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.blue),
                                  ),
                                  child: const Text(
                                    'Student has requested job completion',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ApplicantDetailsScreen(
                                            application: application,
                                          ),
                                        ),
                                      ).then((result) {
                                        if (result == true) {
                                          _loadApplications();
                                        }
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      'View Details',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                                if (application.status ==
                                    'completion_requested') ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _showConfirmationDialog(application),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text(
                                        'Confirm Completion',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
