import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/application.dart';
import '../services/job_service.dart';
import '../services/auth_service.dart';

class ApplicantDetailsScreen extends StatefulWidget {
  final Application application;

  const ApplicantDetailsScreen({Key? key, required this.application})
      : super(key: key);

  @override
  _ApplicantDetailsScreenState createState() => _ApplicantDetailsScreenState();
}

class _ApplicantDetailsScreenState extends State<ApplicantDetailsScreen> {
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _updateStatus(String status) async {
    setState(() {
      _isLoading = true;
    });
    
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

      final jobService = Provider.of<JobService>(context, listen: false);
      await jobService.updateApplicationStatus(widget.application.id, status, token!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application ${status.toUpperCase()} successfully'),
            backgroundColor: status == 'accepted' ? const Color(0xFF8BC34A) : const Color(0xFFF44336),
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    IconData iconData;
    
    switch (status.toLowerCase()) {
      case 'pending':
        badgeColor = Colors.orange;
        iconData = Icons.hourglass_empty;
        break;
      case 'accepted':
        badgeColor = const Color(0xFF8BC34A);
        iconData = Icons.check_circle;
        break;
      case 'declined':
        badgeColor = const Color(0xFFF44336);
        iconData = Icons.cancel;
        break;
      case 'completed':
        badgeColor = const Color(0xFF8BC34A);
        iconData = Icons.task_alt;
        break;
      default:
        badgeColor = Colors.grey;
        iconData = Icons.help_outline;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 16, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final applicant = widget.application.applicant;
    final job = widget.application.job;
    
    // Use the app's primary color for the app bar
    final Color appBlueColor = const Color(0xFF98C9C5);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(applicant.name.isNotEmpty ? applicant.name : 'Applicant Details'),
        backgroundColor: appBlueColor, // Use the app's primary color
        foregroundColor: Colors.black, // Change text color to black
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5), // Light background color
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Job Details Section
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Job Details',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              _buildStatusBadge(widget.application.status),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            job.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (job.category != null && job.category!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(job.category!),
                            ),
                          const SizedBox(height: 8),
                          if (job.salary != null)
                            Row(
                              children: [
                                Icon(Icons.attach_money, size: 18, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  'Salary: ${job.salary}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          const SizedBox(height: 8),
                          if (job.location != null)
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  job.location!,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Applicant Information Section
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Applicant Information',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          
                          // Applicant profile section - simplified to match screenshot
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile image
                              CircleAvatar(
                                radius: 35,
                                backgroundColor: theme.primaryColor.withOpacity(0.2),
                                backgroundImage: applicant.profileImage != null && applicant.profileImage!.isNotEmpty
                                    ? NetworkImage(applicant.profileImage!)
                                    : null,
                                child: applicant.profileImage == null || applicant.profileImage!.isEmpty
                                    ? Text(
                                        applicant.name.isNotEmpty ? applicant.name[0].toUpperCase() : '?',
                                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              
                              // Applicant details in a column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Display applicant name
                                    if (applicant.name.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: Text(
                                          applicant.name,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    Row(
                                      children: [
                                        Icon(Icons.email, size: 18, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Text(
                                          applicant.email,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (applicant.completedJobs != null && applicant.completedJobs! > 0)
                                      Row(
                                        children: [
                                          Icon(Icons.work, color: const Color(0xFF00BCD4), size: 18),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Completed ${applicant.completedJobs} jobs',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 12),
                                    if (applicant.rating != null && applicant.rating! > 0)
                                      Row(
                                        children: [
                                          Icon(Icons.star, color: Colors.amber, size: 18),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Rating: ${applicant.rating}/5',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Applied on: ${_formatDate(widget.application.appliedAt)}',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Application Note Section
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Application Note',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.withOpacity(0.3)),
                            ),
                            child: Text(
                              widget.application.coverLetter.isNotEmpty
                                  ? widget.application.coverLetter
                                  : 'No additional notes provided',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Action Buttons - Only show if status is pending
                  if (widget.application.status.toLowerCase() == 'pending')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _updateStatus('accepted'),
                            icon: const Icon(Icons.check_circle, color: Colors.black), // Black icon
                            label: const Text(
                              'Accept Application',
                              style: TextStyle(color: Colors.black), // Black text
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: appBlueColor, // Use the app's primary blue color
                              foregroundColor: Colors.black, // Black text and icon
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _updateStatus('declined'),
                            icon: const Icon(Icons.cancel),
                            label: const Text('Decline Application'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black, // Use black color
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
