import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/application.dart';
import '../services/job_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApplicantDetailsScreen extends StatefulWidget {
  final Application application;

  const ApplicantDetailsScreen({Key? key, required this.application})
      : super(key: key);

  @override
  _ApplicantDetailsScreenState createState() => _ApplicantDetailsScreenState();
}

class _ApplicantDetailsScreenState extends State<ApplicantDetailsScreen> {
  final _storage = const FlutterSecureStorage();

  Future<void> _updateStatus(String status) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login again')),
          );
          return;
        }
      }

      final jobService = Provider.of<JobService>(context, listen: false);
      await jobService.updateApplicationStatus(widget.application.id, status, token!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application ${status.toUpperCase()} successfully'),
            backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate status was updated
      }
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
        title: const Text('Applicant Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Job Details',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Divider(),
                    Text(
                      widget.application.job.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(widget.application.job.description),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Applicant Information',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(widget.application.applicant.name),
                      subtitle: Text(widget.application.applicant.email),
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Applied On'),
                      subtitle: Text(
                        widget.application.appliedAt.toString().split(' ')[0],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Cover Letter',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(widget.application.coverLetter),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.application.status != 'accepted' && widget.application.status != 'declined')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus('accepted'),
                    icon: const Icon(Icons.check),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus('declined'),
                    icon: const Icon(Icons.close),
                    label: const Text('Decline'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
