import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../widgets/rating_display.dart';
import 'login_screen.dart';
import 'job_owner_dashboard.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final response = await _userService.getUserProfile();
      setState(() {
        _userData = response['data'];
        _isLoading = false;
      });
    } catch (e) {
      print('[ERROR] Failed to load user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await _authService.logout();
      if (mounted) {
        // Navigate to login screen and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('[ERROR] Failed to sign out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to sign out. Please try again.')),
        );
      }
    }
  }

  Future<void> _checkAndUpdateRole() async {
    final storage = FlutterSecureStorage();
    final currentRole = await storage.read(key: 'user_role');
    print('[DEBUG] Current user role: $currentRole');

    // Set role to job_owner for testing
    await storage.write(key: 'user_role', value: 'job_owner');
    print('[DEBUG] Updated user role to: job_owner');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Role updated to job_owner. Please restart the app.')),
    );
  }

  Future<void> _updateProfile(String name, String phone, String bio) async {
    setState(() => _isLoading = true);

    try {
      final response = await _userService.updateUserProfile({
        'name': name,
        'phone': phone,
        'bio': bio,
      });

      if (response['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          // Reload user data to show updated information
          await _loadUserData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response['error'] ?? 'Failed to update profile')),
          );
        }
      }
    } catch (e) {
      print('[ERROR] Failed to update profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEditProfileDialog() {
    final nameController =
        TextEditingController(text: _userData?['name'] ?? '');
    final phoneController =
        TextEditingController(text: _userData?['phone'] ?? '');
    final bioController = TextEditingController(text: _userData?['bio'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: Color.fromARGB(255, 0, 0, 0), size: 24),
            SizedBox(width: 8),
            Text(
              'Edit Profile',
              style: TextStyle(
                color: Color.fromARGB(255, 0, 0, 0),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle:
                      TextStyle(color: const Color.fromARGB(221, 0, 0, 0)),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  labelStyle: TextStyle(color: Colors.black87),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bioController,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  labelStyle: TextStyle(color: Colors.black87),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black54,
            ),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateProfile(
                nameController.text,
                phoneController.text,
                bioController.text,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 0, 0, 0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  double _parseRating(dynamic rating) {
    if (rating is int) {
      return rating.toDouble();
    } else if (rating is double) {
      return rating;
    } else {
      return 0;
    }
  }

  // Helper method to get the correct image provider
  ImageProvider? _getProfileImage() {
    if (_userData == null || 
        _userData!['profileImage'] == null || 
        _userData!['profileImage'].isEmpty) {
      return null;
    }
    
    final imageUrl = _userData!['profileImage'];
    
    if (imageUrl.startsWith('data:image')) {
      // Handle data URL
      try {
        final base64String = imageUrl.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        print('Error decoding base64 image: $e');
        return null;
      }
    } else {
      // Handle network image
      return NetworkImage(imageUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color(0xFF98C9C5), // Deep blue color
        title: const Text(
          'Profile',
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleSignOut,
            tooltip: 'Sign Out',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _checkAndUpdateRole,
            tooltip: 'Debug: Set as Job Owner',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Image
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: _getProfileImage(),
                              child: _userData?['profileImage'] == null ||
                                      _userData!['profileImage'].isEmpty
                                  ? const Icon(Icons.person,
                                      size: 60, color: Colors.grey)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: const Icon(Icons.camera_alt,
                                    size: 20, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // User Rating
                    if (_userData != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          children: [
                            const Text(
                              "Rating",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            RatingDisplay(
                              rating: _parseRating(_userData?['rating']),
                              size: 24,
                              showText: true,
                              showValue: true,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Based on feedback from ${_userData?['completedJobs'] ?? 0} completed jobs",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Name
                    Text(
                      _userData?['name'] ?? 'Loading...',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    // Email
                    Text(
                      _userData?['email'] ?? 'Loading...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Edit Profile Button
                    ElevatedButton.icon(
                      onPressed: _showEditProfileDialog,
                      icon: const Icon(Icons.edit,
                          size: 16, color: const Color(0xFF98C9C5)),
                      label: const Text('Edit Profile',
                          style: TextStyle(color: const Color(0xFF98C9C5))),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // About Me Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color.fromARGB(255, 0, 0, 0)
                                .withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_outline,
                                  color: const Color(0xFF98C9C5), size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'About Me',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            height: 1,
                            color: const Color.fromARGB(255, 0, 0, 0)
                                .withOpacity(0.1),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          Text(
                            _userData?['bio'] ??
                                'No bio provided yet. Tap "Edit Profile" to add a bio.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Stats Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF98C9C5).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color.fromARGB(255, 0, 0, 0)
                                .withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bar_chart,
                                  color: const Color(0xFF98C9C5), size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Activity Statistics',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: double.infinity,
                            height: 1,
                            color: const Color.fromARGB(255, 255, 255, 255)
                                .withOpacity(0.1),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatColumn('Rating',
                                  _userData?['rating']?.toString() ?? '0'),
                              _buildStatColumn('Jobs',
                                  _userData?['jobsCount']?.toString() ?? '0'),
                              _buildStatColumn('Experience',
                                  _userData?['experience']?.toString() ?? '0'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // User Information Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color.fromARGB(255, 0, 0, 0)
                                .withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: const Color(0xFF98C9C5), size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'User Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: double.infinity,
                            height: 1,
                            color: const Color.fromARGB(255, 0, 0, 0)
                                .withOpacity(0.1),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow('ID', _userData?['userId'] ?? 'N/A'),
                          _buildInfoRow(
                              'Phone', _userData?['phone'] ?? 'Not provided'),
                          _buildInfoRow('Role', _userData?['role'] ?? 'User'),
                          _buildInfoRow('Joined',
                              'January 2023'), // Replace with actual join date
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
