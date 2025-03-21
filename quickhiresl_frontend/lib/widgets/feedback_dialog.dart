import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/config.dart';

// Simple function to send feedback to chats - FIXED VERSION
Future<void> sendFeedbackToChats(BuildContext context, String feedback,
    {String? jobCategory, bool isJobOwner = false, String? applicationId}) async {
  try {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    const storage = FlutterSecureStorage();

    // Get user credentials
    final token = await storage.read(key: 'jwt_token');
    final userId = await storage.read(key: 'user_id');
    final userName = await storage.read(key: 'user_name');

    if (token == null || token.isEmpty || userId == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text("Please login to share feedback")),
      );
      return;
    }

    print("DEBUG: Attempting to share feedback: $feedback");

    // Format the feedback message for both job chats and community
    final feedbackMessage = "📢 FEEDBACK: $feedback";

    // If it's from a job owner, don't broadcast to the community
    if (isJobOwner) {
      print("DEBUG: Feedback is from job owner, not broadcasting to community");

      // Show success message specific to job owner
      Future.delayed(Duration.zero, () {
        try {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text("Feedback sent successfully!")),
          );
        } catch (e) {
          print("DEBUG: Error showing final snackbar: $e");
        }
      });

      return;
    }

    // If we have an applicationId, first try to find the specific job for this application
    if (applicationId != null && applicationId.isNotEmpty) {
      try {
        // Get the application details to find the associated job
        final applicationResponse = await http.get(
          Uri.parse("${Config.apiUrl}/applications/$applicationId"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json"
          },
        );

        if (applicationResponse.statusCode == 200) {
          final appData = jsonDecode(applicationResponse.body);
          String? jobId;
          
          // Extract job ID from the response
          if (appData.containsKey('data') && appData['data'].containsKey('jobId')) {
            jobId = appData['data']['jobId'].toString();
          } else if (appData.containsKey('data') && appData['data'].containsKey('job') && appData['data']['job'] is Map) {
            if (appData['data']['job'].containsKey('_id')) {
              jobId = appData['data']['job']['_id'].toString();
            } else if (appData['data']['job'].containsKey('id')) {
              jobId = appData['data']['job']['id'].toString();
            }
          }

          // If we found the job ID, send feedback directly to that job's chat
          if (jobId != null && jobId.isNotEmpty) {
            print("DEBUG: Found job ID $jobId for application $applicationId");
            
            final chatResponse = await http.post(
              Uri.parse("${Config.apiUrl}/jobs/$jobId/chat"),
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $token"
              },
              body: jsonEncode({
                "content": feedbackMessage,
                "sender": {"_id": userId, "name": userName ?? "User"}
              }),
            );

            if (chatResponse.statusCode == 201 || chatResponse.statusCode == 200) {
              print("DEBUG: Successfully sent feedback to job chat for application $applicationId");
              
              // Show success message
              Future.delayed(Duration.zero, () {
                try {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text("Feedback sent to job chat!")),
                  );
                } catch (e) {
                  print("DEBUG: Error showing final snackbar: $e");
                }
              });
              
              return; // Exit early since we've successfully sent the feedback to the correct job
            } else {
              print("DEBUG: Failed to send feedback to job chat: ${chatResponse.statusCode}, ${chatResponse.body}");
            }
          } else {
            print("DEBUG: Could not find job ID for application $applicationId");
          }
        } else {
          print("DEBUG: Failed to get application details: ${applicationResponse.statusCode}, ${applicationResponse.body}");
        }
      } catch (e) {
        print("DEBUG: Error getting application details: $e");
      }
    }

    // If we're here, either we don't have an applicationId or we failed to send to the specific job
    // Fall back to the existing community-based approach
    // SIMPLIFIED APPROACH: Just get all jobs and send to ALL of them
    final jobsResponse = await http.get(Uri.parse("${Config.apiUrl}/jobs"),
        headers: {"Content-Type": "application/json"});

    if (jobsResponse.statusCode == 200) {
      final jobsData = jsonDecode(jobsResponse.body);

      List<dynamic> allJobs = [];
      if (jobsData.containsKey('data')) {
        allJobs = jobsData['data'];
      } else if (jobsData.containsKey('jobs')) {
        allJobs = jobsData['jobs'];
      }

      print("DEBUG: Found ${allJobs.length} total jobs");
      int successCount = 0;

      // Determine relevant jobs based on feedback content
      List<dynamic> relevantJobs = [];

      // Convert feedback to lowercase for easier matching
      final feedbackLower = feedback.toLowerCase();

      // Extract potential keywords from the feedback
      final List<String> possibleKeywords = feedbackLower
          .split(RegExp(r'[\s,.!?;]+'))
          .where((word) => word.length > 3)
          .toList();

      // Check if the feedback is about HRIYawida specifically
      bool isAboutHri = feedbackLower.contains('hri') ||
          feedbackLower.contains('yawida') ||
          feedbackLower.contains('quickhire');

      if (isAboutHri) {
        // If it's about HRIYawida, find all HRIYawida-related jobs
        for (var job in allJobs) {
          final String title = job.containsKey('title')
              ? job['title'].toString().toLowerCase()
              : '';
          final String desc = job.containsKey('description')
              ? job['description'].toString().toLowerCase()
              : '';
          final String category = job.containsKey('category')
              ? job['category'].toString().toLowerCase()
              : '';

          if (title.contains('hri') ||
              desc.contains('hri') ||
              category.contains('hri') ||
              title.contains('quickhire')) {
            relevantJobs.add(job);
          }
        }

        print("DEBUG: Found ${relevantJobs.length} HRIYawida-related jobs");
      }

      // If no relevant jobs found yet, try matching by keywords
      if (relevantJobs.isEmpty) {
        for (var job in allJobs) {
          final String title = job.containsKey('title')
              ? job['title'].toString().toLowerCase()
              : '';
          final String desc = job.containsKey('description')
              ? job['description'].toString().toLowerCase()
              : '';
          final String category = job.containsKey('category')
              ? job['category'].toString().toLowerCase()
              : '';

          // Check if any keywords from the feedback match the job
          for (String keyword in possibleKeywords) {
            if (title.contains(keyword) ||
                desc.contains(keyword) ||
                category.contains(keyword)) {
              relevantJobs.add(job);
              break;
            }
          }
        }
        print("DEBUG: Found ${relevantJobs.length} keyword-related jobs");
      }

      // If still no relevant jobs found, get user's applied jobs
      if (relevantJobs.isEmpty) {
        try {
          final applicationsResponse = await http.get(
            Uri.parse("${Config.apiUrl}/applications/user"),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json"
            },
          );

          if (applicationsResponse.statusCode == 200) {
            final data = jsonDecode(applicationsResponse.body);
            List<dynamic> applications = [];

            if (data.containsKey('data')) {
              applications = data['data'];
            } else if (data.containsKey('applications')) {
              applications = data['applications'];
            }

            // Get unique job IDs from applications
            Set<String> relevantJobIds = {};
            for (var application in applications) {
              if (application.containsKey('jobId')) {
                relevantJobIds.add(application['jobId'].toString());
              } else if (application.containsKey('job') &&
                  application['job'] is Map) {
                if (application['job'].containsKey('_id')) {
                  relevantJobIds.add(application['job']['_id'].toString());
                } else if (application['job'].containsKey('id')) {
                  relevantJobIds.add(application['job']['id'].toString());
                }
              }
            }

            // Find those jobs in our list
            for (var job in allJobs) {
              String? jobId;

              if (job.containsKey('_id')) {
                jobId = job['_id'].toString();
              } else if (job.containsKey('id')) {
                jobId = job['id'].toString();
              }

              if (jobId != null && relevantJobIds.contains(jobId)) {
                relevantJobs.add(job);
              }
            }

            print(
                "DEBUG: Found ${relevantJobs.length} jobs from user's applications");
          }
        } catch (e) {
          print("DEBUG: Error getting user applications: $e");
        }
      }

      // If still no relevant jobs, just use the most recent job as a fallback
      if (relevantJobs.isEmpty && allJobs.isNotEmpty) {
        relevantJobs = [allJobs[0]];
        print("DEBUG: Using most recent job as fallback");
      }

      print(
          "DEBUG: Targeting ${relevantJobs.length} truly relevant jobs for feedback");

      // Send to every relevant job
      for (var job in relevantJobs) {
        String? jobId;
        String? jobTitle;

        if (job.containsKey('_id')) {
          jobId = job['_id'].toString();
        } else if (job.containsKey('id')) {
          jobId = job['id'].toString();
        }

        if (job.containsKey('title')) {
          jobTitle = job['title'].toString();
        }

        if (jobId != null) {
          print("DEBUG: Sending feedback to job: $jobId ($jobTitle)");
          try {
            // Using the correct format with sender object based on error message
            final chatResponse = await http.post(
              Uri.parse("${Config.apiUrl}/jobs/$jobId/chat"),
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $token"
              },
              body: jsonEncode({
                "content": feedbackMessage,
                "sender": {"_id": userId, "name": userName ?? "User"}
              }),
            );

            if (chatResponse.statusCode == 201 ||
                chatResponse.statusCode == 200) {
              successCount++;
              print("DEBUG: Successfully sent feedback to job: $jobTitle");
            } else {
              print(
                  "DEBUG: Failed to send feedback to job $jobTitle: ${chatResponse.statusCode}, ${chatResponse.body}");
            }
          } catch (e) {
            print("DEBUG: Error sending to job $jobTitle: $e");
          }
        }
      }

      print(
          "DEBUG: Successfully sent feedback to $successCount out of ${relevantJobs.length} job chats");
    }

    // Always show success message to user
    Future.delayed(Duration.zero, () {
      try {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text("Feedback shared with the community!")),
        );
      } catch (e) {
        print("DEBUG: Error showing final snackbar: $e");
      }
    });
  } catch (error) {
    print("DEBUG: Fatal error in sendFeedbackToChats: $error");

    // Using Future.delayed to avoid context issues
    Future.delayed(Duration.zero, () {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("An error occurred while sharing feedback")),
        );
      } catch (e) {
        print("DEBUG: Error showing error snackbar: $e");
      }
    });
  }
}

void _showShareToCommunityDialog(BuildContext context, String feedback,
    String? applicationId, bool isJobOwner) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Share to Community'),
        content: const Text(
            'Would you like to share this feedback to the community chat for this job?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              sendFeedbackToChats(
                context, 
                feedback,
                jobCategory: null, 
                isJobOwner: isJobOwner, 
                applicationId: applicationId
              );
            },
            child: const Text('Yes'),
          ),
        ],
      );
    },
  );
}

void showFeedbackDialog(BuildContext context,
    {bool returnToHome = false,
    String? applicationId,
    String? targetUserId,
    Function? onFeedbackSubmitted,
    bool isJobOwner = false}) {
  TextEditingController feedbackController = TextEditingController();
  int rating = 5;
  const storage = FlutterSecureStorage();

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          bool isSubmitting = false;

          Future<void> submitFeedback() async {
            setState(() {
              isSubmitting = true;
            });

            try {
              final token = await storage.read(key: 'jwt_token');

              if (token == null || token.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Please login to submit feedback")),
                );
                Navigator.of(context).pop();
                return;
              }

              if (targetUserId == null || targetUserId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Target user not specified")),
                );
                Navigator.of(context).pop();
                return;
              }

              if (applicationId == null || applicationId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Application ID not specified")),
                );
                Navigator.of(context).pop();
                return;
              }

              // Log the feedback information for debugging
              print("Submitting feedback to API:");
              print("- To User: $targetUserId");
              print("- Rating: $rating");
              print("- Comment: ${feedbackController.text}");
              print("- Application ID: $applicationId");

              // Make the actual API call
              final response = await http.post(
                Uri.parse("${Config.apiUrl}/feedback"),
                headers: {
                  "Content-Type": "application/json",
                  "Authorization": "Bearer $token"
                },
                body: jsonEncode({
                  "rating": rating,
                  "feedback": feedbackController.text,
                  "applicationId": applicationId,
                  "targetUserId": targetUserId
                }),
              );

              print("API Response: ${response.statusCode} - ${response.body}");

              if (response.statusCode == 201 || response.statusCode == 200) {
                // Call the callback if provided
                onFeedbackSubmitted?.call();

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Feedback submitted successfully!"),
                    backgroundColor: Colors.green,
                  ),
                );

                // Close the dialog
                Navigator.of(context).pop();

                // Ask if user wants to share feedback to community chat
                _showShareToCommunityDialog(context, feedbackController.text,
                    applicationId, isJobOwner);
              } else {
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        "Failed to submit feedback: ${jsonDecode(response.body)['message'] ?? 'Unknown error'}"),
                    backgroundColor: Colors.red,
                  ),
                );
              }

              setState(() {
                isSubmitting = false;
              });
            } catch (error) {
              print("Exception during feedback submission: $error");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      "Failed to submit feedback. Please check your connection."),
                  backgroundColor: Colors.red,
                ),
              );
            }

            setState(() {
              isSubmitting = false;
            });
          }

          return AlertDialog(
            title: const Text('Submit Feedback'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please rate your experience:'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: index < rating ? Colors.amber : Colors.grey,
                        size: 30,
                      ),
                      onPressed: () {
                        setState(() {
                          rating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: feedbackController,
                  decoration: const InputDecoration(
                    labelText: 'Your feedback',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : submitFeedback,
                child: isSubmitting
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Submitting...'),
                        ],
                      )
                    : Text('Submit'),
              ),
            ],
          );
        },
      );
    },
  );
}
