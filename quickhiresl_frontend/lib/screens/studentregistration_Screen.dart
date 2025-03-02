import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'jobcategories_screen.dart';
import '../services/auth_service.dart';

class StudentRegistrationScreen extends StatefulWidget {
  final String email;
  final String password;

  const StudentRegistrationScreen({
    Key? key,
    required this.email,
    required this.password,
  }) : super(key: key);

  @override
  _StudentRegistrationScreenState createState() => _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController nicController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  DateTime? _selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final loginResult = await _authService.login(widget.email, widget.password);
        if (!loginResult['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loginResult['error'] ?? 'Login failed')),
          );
          return;
        }

        final userId = await _authService.getUserId();
        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User ID not found. Please try again.')),
          );
          return;
        }

        final studentDetails = {
          'studentDetails': {
            'fullName': fullNameController.text,
            'leavingAddress': addressController.text,
            'dateOfBirth': dobController.text,
            'mobileNumber': mobileController.text,
            'nicNumber': nicController.text,
          }
        };

        final response = await _authService.updateRole(userId, 'student', details: studentDetails);

        if (response['success']) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const JobCategoriesScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update role. Please try again.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            /// Header Section
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
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Student Registration',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Please fill in your details',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),

            /// Centering the Form Fields
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        buildRoundedTextField(fullNameController, 'Full Name'),
                        const SizedBox(height: 20),
                        buildRoundedTextField(addressController, 'Address'),
                        const SizedBox(height: 20),
                        buildRoundedTextField(dobController, 'Date of Birth', isDateField: true),
                        const SizedBox(height: 20),
                        buildRoundedTextField(mobileController, 'Mobile Number'),
                        const SizedBox(height: 20),
                        buildRoundedTextField(nicController, 'NIC Number'),
                        const SizedBox(height: 30),

                        /// Register Button
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
                                    'Register',
                                    style: TextStyle(fontSize: 18, color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Function to create rounded text fields
  Widget buildRoundedTextField(TextEditingController controller, String label, {bool isDateField = false}) {
    return TextFormField(
      controller: controller,
      readOnly: isDateField,
      onTap: isDateField ? () => _selectDate(context) : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        fillColor: Colors.white,
        filled: true,
        suffixIcon: isDateField ? const Icon(Icons.calendar_today) : null,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $label';
        }
        return null;
      },
    );
  }
}