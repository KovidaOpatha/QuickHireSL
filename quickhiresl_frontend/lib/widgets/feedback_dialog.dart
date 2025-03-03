import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
                Uri.parse("http://localhost:3000/api/feedback"),
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

// Function to Show the Share Feedback Dialog
void showShareFeedbackDialog(BuildContext context, String feedback) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Do you want to share your feedback with the community?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close this dialog
                    shareFeedbackWithCommunity(context, feedback);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child:
                      const Text("Yes", style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child:
                      const Text("No", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

// Function to Handle Sharing Feedback with Community
void shareFeedbackWithCommunity(BuildContext context, String feedback) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
        content: Text("Feedback shared with the community successfully!")),
  );
}