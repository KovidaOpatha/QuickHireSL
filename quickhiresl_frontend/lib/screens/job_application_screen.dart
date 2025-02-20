import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class JobApplicationScreen extends StatefulWidget {
  final String jobTitle;
  final String salary;
  final String email;

  const JobApplicationScreen({
    Key? key,
    required this.jobTitle,
    required this.salary,
    required this.email,
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

  Future<void> _fetchUserData() async {
    setState(() => isLoading = true);

    final url = Uri.parse("http://localhost:3000/api/getUser/${widget.email}");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          fullNameController.text = data['fullName'] ?? "";
          addressController.text = data['address'] ?? "";
          idController.text = data['id'] ?? "";
          nicController.text = data['nic'] ?? "";
        });
      } else {
        print("Error fetching user data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }

    setState(() => isLoading = false);
  }

  void _submitApplication() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, messageController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFAED9E0),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 320,
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
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.jobTitle,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        buildTextField("Full Name", fullNameController,
                            isRequired: true),
                        buildTextField("Address", addressController),
                        buildTextField("ID", idController,
                            isNumeric: true, isRequired: true),
                        buildTextField("NIC", nicController,
                            isNumeric: true, isRequired: true),
                        buildTextField("Additional Message", messageController),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _submitApplication,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0)),
                          ),
                          child: const Text("Send Application",
                              style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String hint, TextEditingController controller,
      {bool isNumeric = false, bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        ),
        validator: isRequired
            ? (value) =>
                value == null || value.isEmpty ? "This field is required" : null
            : null,
      ),
    );
  }
}
