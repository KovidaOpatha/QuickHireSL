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
          'requirements': _requirements,
          'salary': {
            'min': _salaryMin,
            'max': _salaryMax,
            'currency': 'LKR'
          },
          'employmentType': _employmentType,
          'experienceLevel': _experienceLevel,
        };

        await _jobService.createJob(jobData, token);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job posted successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          await Future.delayed(const Duration(milliseconds: 500));
          
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error posting job: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Job'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Job Title'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a job title' : null,
                onSaved: (value) => _title = value ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Company'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a company name' : null,
                onSaved: (value) => _company = value ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a location' : null,
                onSaved: (value) => _location = value ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a description' : null,
                onSaved: (value) => _description = value ?? '',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _employmentType,
                decoration: const InputDecoration(labelText: 'Employment Type'),
                items: _employmentTypes
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _employmentType = value ?? 'Full-time'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _experienceLevel,
                decoration: const InputDecoration(labelText: 'Experience Level'),
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
                      decoration: const InputDecoration(labelText: 'Min Salary (LKR)'),
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
                      decoration: const InputDecoration(labelText: 'Max Salary (LKR)'),
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
                      decoration: const InputDecoration(labelText: 'Add Requirement'),
                      controller: _requirementController,
                      onChanged: (value) => _newRequirement = value,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addRequirement,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._requirements.map((req) => Chip(
                    label: Text(req),
                    onDeleted: () =>
                        setState(() => _requirements.remove(req)),
                  )),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitJob,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Post Job'),
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
