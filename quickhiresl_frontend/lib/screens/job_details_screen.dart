import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/job.dart';
import '../services/job_service.dart';
import 'job_application_screen.dart';

class JobDetailsScreen extends StatefulWidget {
  final Job job;

  const JobDetailsScreen({Key? key, required this.job}) : super(key: key);

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final JobService _jobService = JobService();
  final _storage = const FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Job Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF98C9C5), Color(0xFF98C9C5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildJobHeader(),
                const SizedBox(height: 30),
                _buildSectionTitle('Description'),
                Text(widget.job.description, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 20),
                _buildSectionTitle('Requirements'),
                _buildRequirementsList(),
                const SizedBox(height: 20),
                _buildSectionTitle('Job Details'),
                _buildJobDetails(),
                const SizedBox(height: 30),
                _buildApplyButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset('assets/google.png',
            width: double.infinity, height: 150, fit: BoxFit.cover),
        const SizedBox(height: 8),
        Text(
          widget.job.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.job.company,
          style: const TextStyle(fontSize: 18, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on, size: 16, color: Colors.black),
            const SizedBox(width: 4),
            Text(
              widget.job.location,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildRequirementsList() {
    return Column(
      children: widget.job.requirements
          .map(
            (req) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(req, style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildJobDetails() {
    return Column(
      children: [
        _buildDetailRow(Icons.work, 'Employment Type', widget.job.employmentType),
        _buildDetailRow(
            Icons.trending_up, 'Experience Level', widget.job.experienceLevel),
        _buildDetailRow(Icons.attach_money, 'Salary Range',
            '${widget.job.salary['currency']} ${widget.job.salary['min']} - ${widget.job.salary['max']}'),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          try {
            final token = await _storage.read(key: 'jwt_token');
            final email = await _storage.read(key: 'email');
            
            if (token == null || email == null) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please login to apply')),
                );
              }
              return;
            }

            if (context.mounted) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JobApplicationScreen(
                    jobTitle: widget.job.title,
                    salary: '${widget.job.salary['currency']} ${widget.job.salary['min']} - ${widget.job.salary['max']}',
                    email: email,
                  ),
                ),
              );

              if (result != null) {
                await _jobService.applyForJob(widget.job.id!, result, token); 
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Application submitted successfully!')),
                  );
                  Navigator.pop(context); // Go back to jobs list
                }
              }
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to apply: $e')),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text(
          'Apply Now',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
