import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import '../services/job_service.dart';
import '../services/auth_service.dart';
import '../models/application.dart';
import 'applicant_details_screen.dart';

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
      final token = await _authService.getToken();
      print('[DEBUG] Retrieved token: $token');
      if (token == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          // Navigate to login screen when token is not found
          Navigator.of(context).pushReplacementNamed('/login');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to continue')),
          );
          return;
        }
      }

      final jobService = provider.Provider.of<JobService>(context, listen: false);
      final applications = await jobService.getJobOwnerApplications(token!);
      setState(() {
        _applications = applications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load applications: $e')),
        );
      }
    }
  }

  Future<void> _updateApplicationStatus(String applicationId, String status) async {
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

      final jobService = provider.Provider.of<JobService>(context, listen: false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Applications'),
        actions: [
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
                  itemCount: _applications.length,
                  itemBuilder: (context, index) {
                    final application = _applications[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        title: Text(
                          'Job: ${application.job.title}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              'Applicant: ${application.applicant.name}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Applied on: ${application.appliedAt.toString().split(' ')[0]}',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Status: ${application.status.toUpperCase()}',
                              style: TextStyle(
                                color: application.status == 'accepted'
                                    ? Colors.green
                                    : application.status == 'declined'
                                        ? Colors.red
                                        : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ApplicantDetailsScreen(
                                  application: application,
                                ),
                              ),
                            ).then((result) {
                              if (result == true) {
                                _loadApplications();
                              }
                            });
                          },
                          child: const Text('View Details'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
