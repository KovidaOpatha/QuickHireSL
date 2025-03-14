import 'package:flutter/material.dart';
import 'jobcategories_screen.dart';
import '../services/auth_service.dart';

class LocationSelectionScreen extends StatefulWidget {
  final String userId;

  const LocationSelectionScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _LocationSelectionScreenState createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final List<String> _availableLocations = [
    'Dehiwala',
    'Mount Lavinia',
    'Nugegoda',
    'Maharagama',
    'Boralesgamuwa',
    'Battaramulla',
    'Kaduwela',
    'Malabe',
    'Homagama',
    'Pannipitiya',
    'Piliyandala',
    'Ratmalana',
    'Wattala',
    'Kelaniya',
    'Ja-Ela',
    'Negombo',
    'Panadura',
    'Moratuwa',
    'Kadawatha',
    'Gampaha',
  ];

  final Set<String> _selectedLocations = {};
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
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
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Select Job Locations',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Choose locations where you\'re looking for jobs',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),

            // Location Selection List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Select multiple locations:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _availableLocations.length,
                        itemBuilder: (context, index) {
                          final location = _availableLocations[index];
                          return CheckboxListTile(
                            title: Text(location),
                            value: _selectedLocations.contains(location),
                            onChanged: (bool? selected) {
                              setState(() {
                                if (selected == true) {
                                  _selectedLocations.add(location);
                                } else {
                                  _selectedLocations.remove(location);
                                }
                              });
                            },
                            activeColor: Colors.black,
                            checkColor: Colors.white,
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Continue Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveLocationsAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 18,
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
    );
  }

  Future<void> _saveLocationsAndContinue() async {
    if (_selectedLocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one location')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Save the selected locations to the user's profile
      final locationDetails = {
        'preferredLocations': _selectedLocations.toList(),
      };

      final response = await _authService.updateUserPreferences(
        widget.userId, 
        locationDetails,
      );

      if (response['success']) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const JobCategoriesScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error'] ?? 'Failed to save locations. Please try again.')),
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
