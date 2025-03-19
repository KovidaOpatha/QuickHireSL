import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import '../services/job_service.dart';
import '../services/auth_service.dart';
import '../models/job.dart';

class PreviousJobsScreen extends StatefulWidget {
  const PreviousJobsScreen({Key? key}) : super(key: key);

  @override
  _PreviousJobsScreenState createState() => _PreviousJobsScreenState();
}

class _PreviousJobsScreenState extends State<PreviousJobsScreen> {
  final _authService = AuthService();
  List<Job> _previousJobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreviousJobs();
  }

  Future<void> _loadPreviousJobs() async {
    try {
      setState(() {
        _isLoading = true;
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

      final jobService = provider.Provider.of<JobService>(context, listen: false);
      // Use the existing getPreviousJobs method from JobService
      final previousJobs = await jobService.getPreviousJobs(token!);

      setState(() {
        _previousJobs = previousJobs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load previous jobs: $e')),
        );
      }
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'ACTIVE';
      case 'filled':
        return 'FILLED';
      case 'completed':
        return 'COMPLETED';
      case 'closed':
        return 'CLOSED';
      default:
        return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'filled':
        return Colors.blue;
      case 'completed':
        return Colors.purple;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF98C9C5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Previous Jobs',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPreviousJobs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _previousJobs.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'No jobs found. Jobs you post will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _previousJobs.length,
                  itemBuilder: (context, index) {
                    final job = _previousJobs[index];
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
                              job.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Category: ${job.category}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Location: ${job.location}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Budget: ₹${job.salary}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(job.status),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getStatusText(job.status),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
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
