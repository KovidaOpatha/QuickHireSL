import 'package:flutter/material.dart';
import '../services/job_service.dart';
import '../services/auth_service.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({Key? key}) : super(key: key);

  @override
  _PostJobScreenState createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jobService = JobService();
  final _authService = AuthService();
  final List<String> _requirements = [];
  final _requirementController = TextEditingController();

  String _title = '';
  String _company = '';
  String _location = '';
  String _description = '';
  String _employmentType = 'Full-time';
  String _experienceLevel = 'Entry';
  double _salaryMin = 0;
  double _salaryMax = 0;
  String _newRequirement = '';
  bool _isLoading = false;

  final List<String> _employmentTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Internship'
  ];

  final List<String> _experienceLevels = [
    'Entry',
    'Mid-level',
    'Senior',
    'Lead'
  ];

  void _addRequirement() {
    if (_requirementController.text.isNotEmpty) {
      setState(() {
        _requirements.add(_requirementController.text);
        _requirementController.clear();
        _newRequirement = '';
      });
    }
  }

  Future<void> _submitJob() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_requirements.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one requirement')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        // Get the current token
        final token = await _authService.getToken();

        if (token == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please login first')),
            );
          }
          return;
        }

        final jobData = {
          'title': _title,
          'company': _company,
          'location': _location,
          'description': _description,
          'employmentType': _employmentType,
          'experienceLevel': _experienceLevel,
          'salary': {
            'min': _salaryMin,
            'max': _salaryMax,
          },
          'requirements': _requirements,
        };

        final job = await _jobService.createJob(jobData, token);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job posted successfully!')),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error posting job: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  InputDecoration _getInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black87),
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
          'Post a Job',
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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      decoration: _getInputDecoration('Job Title'),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter a job title'
                          : null,
                      onSaved: (value) => _title = value ?? '',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: _getInputDecoration('Company'),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter a company name'
                          : null,
                      onSaved: (value) => _company = value ?? '',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: _getInputDecoration('Location'),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter a location'
                          : null,
                      onSaved: (value) => _location = value ?? '',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: _getInputDecoration('Description'),
                      maxLines: 3,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter a description'
                          : null,
                      onSaved: (value) => _description = value ?? '',
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _employmentType,
                      decoration: _getInputDecoration('Employment Type'),
                      items: _employmentTypes
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) => setState(
                          () => _employmentType = value ?? 'Full-time'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _experienceLevel,
                      decoration: _getInputDecoration('Experience Level'),
                      items: _experienceLevels
                          .map((level) => DropdownMenuItem(
                                value: level,
                                child: Text(level),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _experienceLevel = value ?? 'Entry'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: _getInputDecoration('Min Salary (LKR)'),
                            keyboardType: TextInputType.number,
                            validator: (value) => value?.isEmpty ?? true
                                ? 'Please enter minimum salary'
                                : null,
                            onSaved: (value) =>
                                _salaryMin = double.tryParse(value ?? '0') ?? 0,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            decoration: _getInputDecoration('Max Salary (LKR)'),
                            keyboardType: TextInputType.number,
                            validator: (value) => value?.isEmpty ?? true
                                ? 'Please enter maximum salary'
                                : null,
                            onSaved: (value) =>
                                _salaryMax = double.tryParse(value ?? '0') ?? 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: _getInputDecoration('Add Requirement'),
                            controller: _requirementController,
                            onChanged: (value) => _newRequirement = value,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          color: const Color(0xFF98C9C5),
                          onPressed: _addRequirement,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _requirements
                          .map((req) => Chip(
                                label: Text(req),
                                backgroundColor:
                                    const Color(0xFF98C9C5).withOpacity(0.2),
                                deleteIcon: const Icon(Icons.cancel, size: 18),
                                onDeleted: () =>
                                    setState(() => _requirements.remove(req)),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitJob,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Post Job',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
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
    _requirementController.dispose();
    super.dispose();
  }
}
