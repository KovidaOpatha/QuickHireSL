import 'package:flutter/material.dart';
import 'personalinformation_screen.dart';
import '../services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class JobOwnerRegistrationScreen extends StatefulWidget {
  const JobOwnerRegistrationScreen({Key? key}) : super(key: key);

  @override
  _JobOwnerRegistrationScreenState createState() =>
      _JobOwnerRegistrationScreenState();
}

class _JobOwnerRegistrationScreenState extends State<JobOwnerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>(); // Key for the form validation

  // Controllers for the text fields
  final TextEditingController shopNameController = TextEditingController();
  final TextEditingController shopLocationController = TextEditingController();
  final TextEditingController shopRegNoController = TextEditingController();
  final AuthService _authService = AuthService();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // First check if we have a token
        final token = await _authService.getToken();
        final userId = await _storage.read(key: 'user_id');
        
        if (token == null || userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expired. Please login again.')),
          );
          // TODO: Navigate to login screen
          return;
        }

        // Prepare job owner details
        final jobOwnerDetails = {
          'shopName': shopNameController.text,
          'shopLocation': shopLocationController.text,
          'shopRegisterNo': shopRegNoController.text,
        };

        print('Attempting to update role with userId: $userId');
        print('Token present: ${token != null}');
        print('Details: $jobOwnerDetails');

        // Update role and details
        final success = await _authService.updateRole(
          userId,
          'employer',
          jobOwnerDetails,
        );

        if (success) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const PersonalInformationScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update role. Please try again.')),
          );
        }
      } catch (e) {
        print('Error in _submitForm: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
                  Container(
                    margin: const EdgeInsets.only(bottom: 30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color.fromARGB(0, 0, 0, 0)),
                      color: const Color.fromARGB(0, 255, 255, 255),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Text(
                    'Job Owners\nRegistration',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // Input Fields Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(shopNameController, "Shop Name"),
                    const SizedBox(height: 15),
                    _buildTextField(shopLocationController, "Shop Location"),
                    const SizedBox(height: 15),
                    _buildTextField(shopRegNoController, "Shop Register No"),
                    const SizedBox(height: 30),

                    // Next Button to go to Personal Information
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Next',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
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
    );
  }

  // Reusable Text Field Widget with validation
  Widget _buildTextField(
      TextEditingController controller, String hintText) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
      // Validator to ensure the field is not empty
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$hintText is required';
        }
        return null;
      },
    );
  }
}
