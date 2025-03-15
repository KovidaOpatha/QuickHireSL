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
    'Athurugiriya'
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

  // Search functionality
  String _searchQuery = '';
  List<String> _filteredLocations = [];

  final Set<String> _selectedLocations = {};
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _filteredLocations = List.from(_availableLocations);
  }

  void _filterLocations(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredLocations = List.from(_availableLocations);
      } else {
        _filteredLocations = _availableLocations
            .where((location) => 
                location.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

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

            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: _filterLocations,
                decoration: InputDecoration(
                  hintText: 'Search locations...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF98C9C5), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // Selected Locations Count
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selected: ${_selectedLocations.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_selectedLocations.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedLocations.clear();
                        });
                      },
                      child: const Text(
                        'Clear All',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Location Selection List
            Expanded(
              child: _filteredLocations.isEmpty
                  ? const Center(
                      child: Text(
                        'No locations found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredLocations.length,
                      itemBuilder: (context, index) {
                        final location = _filteredLocations[index];
                        final isSelected = _selectedLocations.contains(location);
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                          child: Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected 
                                    ? const Color(0xFF98C9C5) 
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedLocations.remove(location);
                                  } else {
                                    _selectedLocations.add(location);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      location,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF98C9C5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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
                    elevation: 3,
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