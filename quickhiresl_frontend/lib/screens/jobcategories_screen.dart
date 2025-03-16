import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'availability_screen.dart'; // Import the AvailabilityScreen
import '../services/auth_service.dart';

class JobCategoriesScreen extends StatefulWidget {
  final String? userId;
  
  const JobCategoriesScreen({Key? key, this.userId}) : super(key: key);

  @override
  _JobCategoriesScreenState createState() => _JobCategoriesScreenState();
}

class _JobCategoriesScreenState extends State<JobCategoriesScreen> {
  // All available job categories
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

  // Most common job categories to show by default
  final List<String> _commonCategories = [
    "Supermarket Cashier",
    "Customer Assistant",
    "Fast Food Crew",
    "Waiter/Waitress",
    "Call Center Agent",
    "Delivery Rider",
    "Cleaning Staff",
    "Data Entry Staff",
    "Receptionist",
  ];

  late List<String> _displayedCategories;
  final Set<String> _selectedCategories = {};
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _displayedCategories = List.from(_commonCategories);
    _searchController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCategories);
    _searchController.dispose();
    super.dispose();
  }

  void _filterCategories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _isSearching = false;
        _displayedCategories = List.from(_commonCategories);
      } else {
        _isSearching = true;
        _displayedCategories = _allCategories
            .where((category) => category.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _saveJobPreferences() async {
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one job category')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.userId != null) {
        // Get the user profile first to retrieve existing preferences
        final userProfileResponse = await _authService.getUserProfile(widget.userId!);
        
        // Extract existing preferred locations or use an empty list if not found
        List<String> existingLocations = [];
        if (userProfileResponse['success'] && 
            userProfileResponse['data'] != null && 
            userProfileResponse['data']['studentDetails'] != null &&
            userProfileResponse['data']['studentDetails']['preferredLocations'] != null) {
          existingLocations = List<String>.from(
            userProfileResponse['data']['studentDetails']['preferredLocations']
          );
        }
        
        // Save the selected categories to the user's profile
        final preferences = {
          'preferredJobs': _selectedCategories.toList(),
          'preferredLocations': existingLocations, // Include existing locations
        };

        final response = await _authService.updateUserPreferences(
          widget.userId!, 
          preferences,
        );

        if (!response['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['error'] ?? 'Failed to save preferences. Please try again.')),
          );
          setState(() => _isLoading = false);
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job preferences saved successfully!')),
        );
        
        // Navigate to the Availability Screen
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AvailabilityScreen(),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                    'Job Categories',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Select job categories you\'re interested in',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),

            // Selected Categories Count
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selected: ${_selectedCategories.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_selectedCategories.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategories.clear();
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
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for more job categories',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
            ),
            
            // Search Results or Common Categories Label
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _isSearching ? 'Search Results:' : 'Common Job Categories:',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            
            // Categories Grid
            Expanded(
              child: _displayedCategories.isEmpty
                  ? const Center(
                      child: Text(
                        'No matching job categories found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.0,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _displayedCategories.length,
                        itemBuilder: (context, index) {
                          final category = _displayedCategories[index];
                          final isSelected = _selectedCategories.contains(category);
                          
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedCategories.remove(category);
                                } else {
                                  _selectedCategories.add(category);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF98C9C5) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF98C9C5) : Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Text(
                                        category,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? Colors.black : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(1),
                                        decoration: const BoxDecoration(
                                          color: Colors.black,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
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
                  onPressed: _isLoading ? null : _saveJobPreferences,
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
                          "Finish",
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
}
