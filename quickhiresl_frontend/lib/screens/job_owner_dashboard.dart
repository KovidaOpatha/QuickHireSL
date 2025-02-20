import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/job_service.dart';
import '../models/application.dart';

class JobOwnerDashboard extends StatefulWidget {
  const JobOwnerDashboard({Key? key}) : super(key: key);

  @override
  _JobOwnerDashboardState createState() => _JobOwnerDashboardState();
}

class _JobOwnerDashboardState extends State<JobOwnerDashboard> {
  List<Application> _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    try {
      final jobService = Provider.of<JobService>(context, listen: false);
      final applications = await jobService.getJobOwnerApplications();
      setState(() {
        _applications = applications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load applications: $e')),
      );
    }
  }

  Future<void> _updateApplicationStatus(String applicationId, String status) async {
    try {
      final jobService = Provider.of<JobService>(context, listen: false);
      await jobService.updateApplicationStatus(applicationId, status);
      await _loadApplications(); // Reload the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
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
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Job: ${application.job.title}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Applicant: ${application.applicant.name}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Applied on: ${application.appliedAt.toString().split(' ')[0]}',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Cover Letter:',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(application.coverLetter),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                ElevatedButton(
                                  onPressed: application.status == 'pending'
                                      ? () => _updateApplicationStatus(
                                          application.id, 'accepted')
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  child: const Text('Accept'),
                                ),
                                ElevatedButton(
                                  onPressed: application.status == 'pending'
                                      ? () => _updateApplicationStatus(
                                          application.id, 'rejected')
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Reject'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'Status: ${application.status.toUpperCase()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: application.status == 'accepted'
                                      ? Colors.green
                                      : application.status == 'rejected'
                                          ? Colors.red
                                          : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
