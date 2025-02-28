import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void showFeedbackDialog(BuildContext context, {bool returnToHome = false}) {
  TextEditingController feedbackController = TextEditingController();
  int rating = 5;

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
              final response = await http.post(
                Uri.parse("http://localhost:5001/feedback"),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode(
                    {"rating": rating, "feedback": feedbackController.text}),
              );

              if (response.statusCode == 201) {
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Feedback submitted successfully!")),
                );

                Navigator.of(context).pop(); // Close feedback dialog
                showShareFeedbackDialog(
                    context, feedbackController.text); // Show share dialog
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
                    content: Text(
                        "Failed to submit feedback. Check your connection.")),
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
                Text("We need your feedback",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 10),
                Text("How would you rate your experience with the job today?"),
                SizedBox(height: 10),
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
                  decoration: InputDecoration(
                    hintText: "Write your feedback",
                    filled: true,
                    fillColor: Colors.grey[300],
                    border: InputBorder.none,
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSubmitting
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Submit", style: TextStyle(color: Colors.white)),
                ),
                SizedBox(height: 5),
                Text("Need to share your thoughts"),
              ],
            ),
          );
        },
      );
    },
  );
}

//New Function to Show the Share Feedback Dialog
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
            Text("Do you want to share your feedback with the community?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close this dialog
                    shareFeedbackWithCommunity(feedback);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text("Yes", style: TextStyle(color: Colors.white)),
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
                  child: Text("No", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

//Function to Handle Sharing Feedback with Community
void shareFeedbackWithCommunity(String feedback) {
  print("Feedback shared with the community: $feedback");
}
