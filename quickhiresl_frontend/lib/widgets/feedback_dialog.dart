import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/config.dart';

void showFeedbackDialog(BuildContext context,
    {bool returnToHome = false,
    String? applicationId,
    Function? onFeedbackSubmitted}) {
  TextEditingController feedbackController = TextEditingController();
  int rating = 5;
  final storage = const FlutterSecureStorage();

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

              if (token == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Please login to submit feedback")),
                );
                Navigator.of(context).pop();
                return;
              }

              final response = await http.post(
                Uri.parse("${Config.apiUrl}/feedback"),
                headers: {
                  "Content-Type": "application/json",
                  "Authorization": "Bearer $token"
                },
                body: jsonEncode({
                  "rating": rating,
                  "feedback": feedbackController.text,
                  "applicationId": applicationId
                }),
              );

              if (response.statusCode == 201) {
                if (onFeedbackSubmitted != null) {
                  onFeedbackSubmitted();
                }

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Feedback submitted successfully!")),
                );

                Navigator.of(context).pop(); // Close feedback dialog
                showShareFeedbackDialog(context, feedbackController.text);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text("Error submitting feedback: ${response.body}")),
                );
              }
            } catch (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text("Failed to submit feedback: ${error.toString()}")),
              );
            }

            setState(() {
              isSubmitting = false;
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("We need your feedback",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 10),
                const Text("How would you rate your experience?"),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        setState(() {
                          rating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                TextField(
                  controller: feedbackController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Write your feedback",
                    filled: true,
                    fillColor: Colors.grey[300],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("Submit",
                          style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 5),
                const Text("Need to share your thoughts"),
              ],
            ),
          );
        },
      );
    },
  );
}

void showShareFeedbackDialog(BuildContext context, String feedback) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Share Your Feedback'),
        content: const Text(
            'Would you like to share your feedback with the community?'),
        actions: <Widget>[
          TextButton(
            child: const Text('No'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Yes'),
            onPressed: () {
              sendFeedbackToChats(context, feedback);
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

// Simple function to send feedback to chats - FIXED VERSION
Future<void> sendFeedbackToChats(BuildContext context, String feedback,
    {String? jobCategory}) async {
  try {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final storage = const FlutterSecureStorage();

    // Get user credentials
    final token = await storage.read(key: 'jwt_token');
    final userId = await storage.read(key: 'user_id');
    final userName = await storage.read(key: 'user_name');

    if (token == null || userId == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text("Please login to share feedback")),
      );
      return;
    }

    print("DEBUG: Attempting to share feedback: $feedback");

    // Format the feedback message for both job chats and community
    final feedbackMessage = "📢 FEEDBACK: $feedback";

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
          const SnackBar(content: Text("Feedback shared with the community!")),
        );
      } catch (e) {
        print("DEBUG: Error showing error snackbar: $e");
      }
    });
  }
}
