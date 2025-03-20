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
  final JobService _jobService = JobService();
  final AuthService _authService = AuthService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _requirementController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();

  List<String> _requirements = [];
  String _employmentType = 'Full-time';
  String _experienceLevel = 'Entry';
  String _category = '';
  double _salary = 0;
  List<Map<String, dynamic>> _availableDates = [];
  bool _isSubmitting = false;

  // Controllers for date selection
  DateTime? _selectedDate;
  bool _isFullDay = false;
  final List<Map<String, String>> _selectedTimeSlots = [];

  // All available job categories (same as in JobCategoriesScreen)
  final List<String> _allCategories = [
    "Supermarket Cashier",
    "Shelf Stacker",
    "Customer Assistant",
    "Promotional Staff",
    "Fast Food Crew",
    "Pharmacy Sales Assistant",
    "Waiter/Waitress",
    "Hotel Banquet Staff",
    "Call Center Agent",
    "Petrol Station Attendant",
    "Clothing Store Assistant",
    "Mobile Shop Assistant",
    "Cinema Ticket Staff",
    "Event Assistant",
    "Delivery Rider",
    "Parking Attendant",
    "Security Assistant",
    "Cleaning Staff",
    "Warehouse Packer",
    "Street Food Helper",
    "Florist Assistant",
    "Receptionist",
    "Gym Receptionist",
    "Bakery Sales Assistant",
    "Call Operator",
    "Data Entry Staff",
    "Ice Cream Shop Staff",
    "Printing Shop Assistant",
    "Petrol Shed Cashier",
    "Tutor (Online/In-person)",
  ];

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
      });
    }
  }

  // Show date picker to select a date
  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF98C9C5),
              onPrimary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null) {
      // Check if date already exists
      final existingDateIndex = _availableDates.indexWhere(
        (item) => _isSameDay(DateTime.parse(item['date']), pickedDate)
      );
      
      if (existingDateIndex != -1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This date is already added')),
          );
        }
        return;
      }
      
      setState(() {
        _selectedDate = pickedDate;
        _isFullDay = false;
        _selectedTimeSlots.clear();
      });
      
      // Show bottom sheet for availability options
      _showAvailabilityOptions();
    }
  }

  // Show bottom sheet with availability options
  void _showAvailabilityOptions() {
    if (_selectedDate == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Date: ${_formatDate(_selectedDate!)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Available Full Day'),
                      value: _isFullDay,
                      onChanged: (value) {
                        setModalState(() {
                          _isFullDay = value;
                        });
                      },
                      activeColor: const Color(0xFF98C9C5),
                    ),
                    if (!_isFullDay) ...[  
                      const SizedBox(height: 8),
                      const Text('Time Slots:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _selectedTimeSlots.length,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              dense: true,
                              title: Text('${_selectedTimeSlots[index]['startTime']} - ${_selectedTimeSlots[index]['endTime']}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setModalState(() {
                                    _selectedTimeSlots.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: const Text('Add Time Slot'),
                        onPressed: () async {
                          final TimeOfDay? startTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          
                          if (startTime != null) {
                            final TimeOfDay? endTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(hour: (startTime.hour + 1) % 24, minute: startTime.minute),
                            );
                            
                            if (endTime != null) {
                              setModalState(() {
                                _selectedTimeSlots.add({
                                  'startTime': _formatTimeOfDay(startTime),
                                  'endTime': _formatTimeOfDay(endTime),
                                });
                              });
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF98C9C5),
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (!_isFullDay && _selectedTimeSlots.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please add at least one time slot or select full day')),
                            );
                            return;
                          }
                          
                          setState(() {
                            _availableDates.add({
                              'date': _selectedDate!.toIso8601String(),
                              'isFullDay': _isFullDay,
                              'timeSlots': List<Map<String, String>>.from(_selectedTimeSlots),
                            });
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Add Date', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Remove a date availability
  void _removeDateAvailability(int index) {
    setState(() {
      _availableDates.removeAt(index);
    });
  }

  // Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Format TimeOfDay for storage
  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;

    if (_requirements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one requirement')),
      );
      return;
    }

    if (_category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a job category')),
      );
      return;
    }

    if (_availableDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one available date')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    _formKey.currentState!.save();

    try {
      final userId = await _authService.getUserId();

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final jobData = {
        'title': _titleController.text.trim(),
        'company': _companyController.text.trim(),
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'requirements': _requirements,
        'salary': _salary,
        'employmentType': _employmentType,
        'experienceLevel': _experienceLevel,
        'postedBy': userId,
        'category': _category,
        'availableDates': _availableDates,
      };

      final job = await _jobService.createJob(jobData);

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
        setState(() => _isSubmitting = false);
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
                      controller: _titleController,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter a job title'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: _getInputDecoration('Company'),
                      controller: _companyController,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter a company name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: _getInputDecoration('Location'),
                      controller: _locationController,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter a location'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: _getInputDecoration('Description'),
                      controller: _descriptionController,
                      maxLines: 3,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter a description'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Job Category',
                        border: OutlineInputBorder(),
                      ),
                      value: _category.isNotEmpty ? _category : null,
                      hint: const Text('Select a job category'),
                      isExpanded: true,
                      items: _allCategories
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a job category';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _category = value!;
                        });
                      },
                      onSaved: (value) {
                        _category = value!;
                      },
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
                    TextFormField(
                      decoration: _getInputDecoration('Salary (LKR)'),
                      controller: _salaryController,
                      keyboardType: TextInputType.number,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter salary'
                          : null,
                      onSaved: (value) =>
                          _salary = double.tryParse(value ?? '0') ?? 0,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: _getInputDecoration('Add Requirement'),
                            controller: _requirementController,
                            onChanged: (value) => setState(() {}),
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
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _selectDate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF98C9C5),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Add Date Availability'),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableDates
                          .asMap()
                          .entries
                          .map((entry) => Chip(
                                label: Text(
                                  '${_formatDate(DateTime.parse(entry.value['date']))} - ${entry.value['isFullDay'] ? 'Full Day' : entry.value['timeSlots'].map((slot) => '${slot['startTime']} - ${slot['endTime']}').join(', ')}',
                                ),
                                backgroundColor:
                                    const Color(0xFF98C9C5).withOpacity(0.2),
                                deleteIcon: const Icon(Icons.cancel, size: 18),
                                onDeleted: () =>
                                    _removeDateAvailability(entry.key),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitJob,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isSubmitting
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
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _salaryController.dispose();
    super.dispose();
  }
}
