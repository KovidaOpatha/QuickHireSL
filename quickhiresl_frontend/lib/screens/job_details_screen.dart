import 'package:flutter/material.dart';
import 'package:quickhiresl_frontend/screens/job_application_screen.dart';

class JobDetailsScreen extends StatelessWidget {
  final String jobTitle;
  final String userEmail;

  const JobDetailsScreen({
    Key? key,
    required this.jobTitle,
    required this.userEmail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFAED9E0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jobTitle,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text("Hourly Rate: \$10", style: TextStyle(fontSize: 16)),
                const Text("Work Hours: 8 hours per day",
                    style: TextStyle(fontSize: 16)),
                const Text("Shift Timing: 9:00 AM - 5:00 PM",
                    style: TextStyle(fontSize: 16)),
                const SizedBox(height: 12),
                const Text(
                  "As a cashier at Keells Super, you'll be responsible for managing transactions, handling customer payments, and ensuring a smooth checkout process.",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                // Using a local image from the assets folder
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/jobmatching.png', // Path to your local image
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to JobApplicationScreen with job title and email
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobApplicationScreen(
                            jobTitle: jobTitle,
                            email: userEmail,
                            salary: '',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text("Apply",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
