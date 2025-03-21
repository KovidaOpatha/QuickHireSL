import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/availability_service.dart';
import '../services/auth_service.dart';

class AvailabilityScreen extends StatefulWidget {
  final bool fromRegistration;
  
  const AvailabilityScreen({
    Key? key, 
    this.fromRegistration = false
  }) : super(key: key);

  @override
  _AvailabilityScreenState createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final AvailabilityService _availabilityService = AvailabilityService();
  final AuthService _authService = AuthService();
  
  List<Map<String, dynamic>> _availabilityDates = [];
  bool _isLoading = true;
  String? _userId;
  String _errorMessage = '';
  
  // For adding new availability
  DateTime? _selectedDate;
  bool _isFullDay = false;
  final List<Map<String, String>> _timeSlots = [];
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = await _authService.getUserId();
      
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not authenticated';
        });
        return;
      }
      
      _userId = userId;
      await _loadAvailability();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading user data: $e';
      });
    }
  }

  Future<void> _loadAvailability() async {
    if (_userId == null) return;
    
    try {
      final response = await _availabilityService.getUserAvailability(_userId!);
      
      if (response['success']) {
        final availabilityData = response['availability'] as List;
        setState(() {
          _availabilityDates = availabilityData.map((item) => item as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response['error'] ?? 'Failed to load availability';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
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
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF98C9C5),
              onPrimary: Colors.black,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      
      setState(() {
        if (isStartTime) {
          _startTimeController.text = formattedTime;
        } else {
          _endTimeController.text = formattedTime;
        }
      });
    }
  }

  void _addTimeSlot() {
    if (_startTimeController.text.isNotEmpty && _endTimeController.text.isNotEmpty) {
      setState(() {
        _timeSlots.add({
          'startTime': _startTimeController.text,
          'endTime': _endTimeController.text,
        });
        _startTimeController.clear();
        _endTimeController.clear();
      });
    }
  }

  void _removeTimeSlot(int index) {
    setState(() {
      _timeSlots.removeAt(index);
    });
  }

  Future<void> _saveAvailability() async {
    if (_userId == null || _selectedDate == null) return;
    
    if (!_isFullDay && _timeSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one time slot or select full day')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final availabilityData = {
        'date': _selectedDate!.toIso8601String(),
        'isFullDay': _isFullDay,
        'timeSlots': _timeSlots,
      };
      
      final response = await _availabilityService.addAvailabilityDate(_userId!, availabilityData);
      
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Availability added successfully')),
        );
        
        // Reset form and reload availability
        setState(() {
          _selectedDate = null;
          _isFullDay = false;
          _timeSlots.clear();
          _startTimeController.clear();
          _endTimeController.clear();
        });
        
        await _loadAvailability();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error'] ?? 'Failed to add availability')),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAvailability(String dateId) async {
    if (_userId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final response = await _availabilityService.removeAvailabilityDate(_userId!, dateId);
      
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Availability removed successfully')),
        );
        await _loadAvailability();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error'] ?? 'Failed to remove availability')),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('EEE, MMM d, yyyy').format(date);
  }

  void _completeRegistration() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated. Please log in again.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if user has added at least one availability date
      if (_availabilityDates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one availability date before proceeding.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Update user registration status
      final response = await _authService.updateUserProfile(
        _userId!,
        {'registrationComplete': true},
      );

      setState(() => _isLoading = false);

      if (response['success']) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration completed successfully!')),
        );

        // Navigate to home screen or dashboard
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error'] ?? 'Failed to complete registration')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
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
          'Manage Availability',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Add new availability section
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Add New Availability',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Date selection
                                InkWell(
                                  onTap: () => _selectDate(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _selectedDate == null
                                              ? 'Select Date'
                                              : DateFormat('EEE, MMM d, yyyy').format(_selectedDate!),
                                          style: TextStyle(
                                            color: _selectedDate == null ? Colors.grey : Colors.black,
                                          ),
                                        ),
                                        const Icon(Icons.calendar_today, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Full day checkbox
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _isFullDay,
                                      onChanged: (value) {
                                        setState(() {
                                          _isFullDay = value ?? false;
                                        });
                                      },
                                      activeColor: const Color(0xFF98C9C5),
                                    ),
                                    const Text('Available Full Day'),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                // Time slots section (only if not full day)
                                if (!_isFullDay) ...[
                                  const Text(
                                    'Add Time Slots',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  // Time slot input
                                  Row(
                                    children: [
                                      // Start time
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => _selectTime(context, true),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey.shade300),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  _startTimeController.text.isEmpty
                                                      ? 'Start Time'
                                                      : _startTimeController.text,
                                                  style: TextStyle(
                                                    color: _startTimeController.text.isEmpty ? Colors.grey : Colors.black,
                                                  ),
                                                ),
                                                const Icon(Icons.access_time, size: 20),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      
                                      // End time
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => _selectTime(context, false),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey.shade300),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  _endTimeController.text.isEmpty
                                                      ? 'End Time'
                                                      : _endTimeController.text,
                                                  style: TextStyle(
                                                    color: _endTimeController.text.isEmpty ? Colors.grey : Colors.black,
                                                  ),
                                                ),
                                                const Icon(Icons.access_time, size: 20),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      // Add button
                                      IconButton(
                                        icon: const Icon(Icons.add_circle, color: Color(0xFF98C9C5)),
                                        onPressed: _addTimeSlot,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Time slots list
                                  if (_timeSlots.isNotEmpty) ...[
                                    const Text(
                                      'Added Time Slots:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _timeSlots.length,
                                      itemBuilder: (context, index) {
                                        final slot = _timeSlots[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                                const SizedBox(width: 8),
                                                Text('${slot['startTime']} - ${slot['endTime']}'),
                                                const Spacer(),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                  onPressed: () => _removeTimeSlot(index),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ],
                                
                                const SizedBox(height: 16),
                                
                                // Save button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _selectedDate == null ? null : _saveAvailability,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF98C9C5),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Save Availability'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Current availability section
                        const Text(
                          'Your Available Dates',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        _availabilityDates.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'No availability dates added yet. Add your first available date above.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _availabilityDates.length,
                                itemBuilder: (context, index) {
                                  final availability = _availabilityDates[index];
                                  final date = _formatDate(availability['date']);
                                  final isFullDay = availability['isFullDay'] ?? false;
                                  final timeSlots = availability['timeSlots'] as List? ?? [];
                                  
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.calendar_today, size: 20),
                                              const SizedBox(width: 8),
                                              Text(
                                                date,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const Spacer(),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                onPressed: () => _deleteAvailability(availability['_id']),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          if (isFullDay)
                                            const Text('Available: Full Day')
                                          else if (timeSlots.isNotEmpty)
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Available during:'),
                                                const SizedBox(height: 4),
                                                ...timeSlots.map((slot) {
                                                  return Padding(
                                                    padding: const EdgeInsets.only(bottom: 4.0),
                                                    child: Text('• ${slot['startTime']} - ${slot['endTime']}'),
                                                  );
                                                }).toList(),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                        
                        // Add Complete Registration button at the bottom
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: widget.fromRegistration ? _completeRegistration : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Complete Registration',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
    );
  }
}
