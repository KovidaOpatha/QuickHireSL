import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'availability_screen.dart';

class JobPreferencesScreen extends StatefulWidget {
  final bool fromRegistration;
  
  const JobPreferencesScreen({
    Key? key, 
    this.fromRegistration = false,
  }) : super(key: key);

  @override
  _JobPreferencesScreenState createState() => _JobPreferencesScreenState();
}

class _JobPreferencesScreenState extends State<JobPreferencesScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _userData;
  
  // Job preference data
  List<String> _selectedCategories = [];
  List<String> _selectedLocations = [];
  double _minSalary = 10000;
  double _maxSalary = 100000;
  
  // Available options
  final List<String> _allCategories = [
    'IT & Software',
    'Accounting',
    'Marketing',
    'Sales',
    'Customer Service',
    'Healthcare',
    'Education',
    'Engineering',
    'Hospitality',
    'Retail',
  ];
  
  final List<String> _allLocations = [
    'Colombo',
    'Gampaha',
    'Kalutara',
    'Kandy',
    'Galle',
    'Matara',
    'Jaffna',
    'Batticaloa',
    'Anuradhapura',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _userService.getUserProfile();
      
      if (response['success']) {
        final userData = response['data'];
        
        setState(() {
          _userData = userData;
          
          // Load existing preferences if available
          if (userData['studentDetails'] != null) {
            final studentDetails = userData['studentDetails'];
            
            if (studentDetails['jobPreferences'] != null) {
              final jobPreferences = studentDetails['jobPreferences'];
              
              _selectedCategories = List<String>.from(jobPreferences['categories'] ?? []);
              _selectedLocations = List<String>.from(jobPreferences['locations'] ?? []);
              
              if (jobPreferences['salary'] != null) {
                _minSalary = (jobPreferences['salary']['min'] ?? 10000).toDouble();
                _maxSalary = (jobPreferences['salary']['max'] ?? 100000).toDouble();
              }
            }
          }
          
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user data: ${response['error']}')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    
    try {
      final jobPreferences = {
        'categories': _selectedCategories,
        'locations': _selectedLocations,
        'salary': {
          'min': _minSalary.toInt(),
          'max': _maxSalary.toInt(),
        },
      };
      
      final response = await _userService.updateJobPreferences(jobPreferences);
      
      setState(() => _isSaving = false);
      
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job preferences saved successfully')),
        );
        
        if (widget.fromRegistration) {
          // Navigate to availability screen if coming from registration
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AvailabilityScreen(fromRegistration: true),
            ),
          );
        } else {
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save preferences: ${response['error']}')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF98C9C5),
        title: const Text(
          'Job Preferences',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Introduction text
                  const Text(
                    'Set your job preferences to help us find the best matches for you',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Job Categories
                  const Text(
                    'Job Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select the categories you are interested in',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _allCategories.map((category) {
                      final isSelected = _selectedCategories.contains(category);
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                          });
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor: const Color(0xFF98C9C5),
                        checkmarkColor: Colors.black,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.black87,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  // Preferred Locations
                  const Text(
                    'Preferred Locations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select locations where you would like to work',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _allLocations.map((location) {
                      final isSelected = _selectedLocations.contains(location);
                      return FilterChip(
                        label: Text(location),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedLocations.add(location);
                            } else {
                              _selectedLocations.remove(location);
                            }
                          });
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor: const Color(0xFF98C9C5),
                        checkmarkColor: Colors.black,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.black87,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  // Salary Range
                  const Text(
                    'Salary Range (Rs.)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select your expected salary range',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rs. ${_minSalary.toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Rs. ${_maxSalary.toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: RangeValues(_minSalary, _maxSalary),
                    min: 10000,
                    max: 200000,
                    divisions: 19,
                    activeColor: const Color(0xFF98C9C5),
                    inactiveColor: Colors.grey[300],
                    labels: RangeLabels(
                      'Rs. ${_minSalary.toInt()}',
                      'Rs. ${_maxSalary.toInt()}',
                    ),
                    onChanged: (values) {
                      setState(() {
                        _minSalary = values.start;
                        _maxSalary = values.end;
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _savePreferences,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF98C9C5),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : const Text(
                              'Save Preferences',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  
                  if (widget.fromRegistration) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          // Skip to availability screen
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AvailabilityScreen(fromRegistration: true),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black54,
                        ),
                        child: const Text('Skip for now'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
