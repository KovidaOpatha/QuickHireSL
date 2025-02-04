import 'package:flutter/material.dart';
import 'jobcategories_screen.dart'; // Import the Job Categories Screen

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({Key? key}) : super(key: key);

  @override
  _StudentRegistrationScreenState createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController nicController = TextEditingController();

  // Create a global key for the form
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF98C9C5),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 10),
                    // Title
                    const Text(
                      'Student\nRegistration',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Registration Form
              Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(controller: fullNameController, hint: 'Full Name'),
                      const SizedBox(height: 15),
                      _buildTextField(controller: addressController, hint: 'Leaving Address'),
                      const SizedBox(height: 15),
                      _buildTextField(controller: dobController, hint: 'Date of Birth'),
                      const SizedBox(height: 15),
                      _buildTextField(controller: mobileController, hint: 'Mobile Number'),
                      const SizedBox(height: 15),
                      _buildTextField(controller: nicController, hint: 'NIC Number'),
                      const SizedBox(height: 30),

                      // Next Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            // Validate the form before navigation
                            if (_formKey.currentState!.validate()) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const JobCategoriesScreen(), // Navigate to Job Categories Screen
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Next',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to Build Text Fields
  Widget _buildTextField({required TextEditingController controller, required String hint}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
      // Validation for empty fields
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$hint is required';  // Display the error message
        }
        return null;
      },
    );
  }
}
