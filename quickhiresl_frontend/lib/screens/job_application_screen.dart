import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/config.dart';

class JobApplicationScreen extends StatefulWidget {
  final String jobTitle;
  final String salary;
  final String email;
  final String jobOwnerEmail;

  const JobApplicationScreen({
    Key? key,
    required this.jobTitle,
    required this.salary,
    required this.email,
    required this.jobOwnerEmail,
  }) : super(key: key);

  @override
  _JobApplicationScreenState createState() => _JobApplicationScreenState();
}

class _JobApplicationScreenState extends State<JobApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController nicController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  bool isLoading = false;
  Map<String, dynamic> jobOwnerData = {};
  bool isJobOwnerLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchJobOwnerData();
  }

  Future<void> _fetchJobOwnerData() async {
    setState(() => isJobOwnerLoading = true);

    if (widget.jobOwnerEmail.isEmpty) {
      setState(() {
        isJobOwnerLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/getUser/${widget.jobOwnerEmail}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            jobOwnerData = data['data'];
            isJobOwnerLoading = false;
          });
        } else {
          setState(() => isJobOwnerLoading = false);
        }
      } else {
        setState(() => isJobOwnerLoading = false);
      }
    } catch (e) {
      print('Error fetching job owner data: $e');
      setState(() => isJobOwnerLoading = false);
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final storage = FlutterSecureStorage();
      final email = await storage.read(key: 'email');
      
      if (email != null) {
        fullNameController.text = email.split('@')[0]; // Default name from email
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isLoading = true);

    try {
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to apply. Go to Profile tab to login.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
        setState(() => isLoading = false);
        return;
      }

      final response = await http.post(
        Uri.parse('${Config.apiUrl}/apply'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'fullName': fullNameController.text,
          'address': addressController.text,
          'id': idController.text,
          'nic': nicController.text,
          'message': messageController.text,
          'jobTitle': widget.jobTitle,
          'email': widget.email,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Application submitted successfully')),
          );
          Navigator.pop(context, true); // Return success
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorData['message'] ?? 'Failed to submit application')),
            );
          }
        } catch (e) {
          print('Error parsing error response: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to submit application. Status code: ${response.statusCode}')),
            );
          }
        }
      }
    } catch (e) {
      print('Error submitting application: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  InputDecoration _getInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black87),
      prefixIcon: Icon(icon, color: const Color(0xFF98C9C5)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF98C9C5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Apply for Job',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // White container for the form
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apply for ${widget.jobTitle}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Salary: ${widget.salary}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: fullNameController,
                      decoration:
                          _getInputDecoration('Full Name', Icons.person),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: addressController,
                      decoration:
                          _getInputDecoration('Address', Icons.location_on),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: idController,
                      decoration: _getInputDecoration(
                          'Student ID', Icons.badge),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your student ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nicController,
                      decoration: _getInputDecoration(
                          'NIC Number', Icons.credit_card),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your NIC number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: messageController,
                      decoration: _getInputDecoration(
                          'Why should we hire you?', Icons.message),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a message';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: SizedBox(
                        height: 50,
                        width: 200,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submitApplication,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF98C9C5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Submit Application',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Job owner information section
              if (!isJobOwnerLoading && jobOwnerData.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Job Posted By',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: const Color(0xFF98C9C5),
                            backgroundImage: jobOwnerData['profileImage'] != null
                                ? NetworkImage(jobOwnerData['profileImage'])
                                : null,
                            child: jobOwnerData['profileImage'] == null
                                ? const Icon(Icons.person, size: 30, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  jobOwnerData['name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  jobOwnerData['email'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    addressController.dispose();
    idController.dispose();
    nicController.dispose();
    messageController.dispose();
    super.dispose();
  }
}
