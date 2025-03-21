import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../widgets/rating_display.dart';
import 'job_owner_dashboard.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

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
      print('[DEBUG] User data: ${response['data']}');
      if (response['data']['jobOwnerDetails'] != null) {
        print('[DEBUG] Job owner details: ${response['data']['jobOwnerDetails']}');
      }
      setState(() {
        _userData = response['data'];
        _isLoading = false;
      });
    } catch (e) {
      print('[ERROR] Failed to load user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile(Map<String, dynamic> updatedData, {File? profileImage}) async {
    setState(() => _isLoading = true);
    print('[DEBUG] Updating profile with data: $updatedData');

    try {
      final response = await _userService.updateUserProfile(updatedData, profileImage: profileImage);
      print('[DEBUG] Update response: $response');
      if (response['success']) {
        if (mounted) {
          setState(() {
            _userData = response['data'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile: ${response['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      _loadUserData(); // Reload user data to reflect changes
    } catch (e) {
      print('[ERROR] Failed to update profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showEditProfileDialog() {
    final role = _userData?['role'] ?? '';
    final controllers = <String, TextEditingController>{};
    final Map<String, dynamic> updatedData = {};
    File? _imageFile;
    
    // Initialize controllers with current values
    controllers['bio'] = TextEditingController(
      text: _userData?['bio'] ?? '',
    );
    
    if (role == 'student') {
      controllers['fullName'] = TextEditingController(
        text: _userData?['studentDetails']?['fullName'] ?? '',
      );
      controllers['mobileNumber'] = TextEditingController(
        text: _userData?['studentDetails']?['mobileNumber'] ?? '',
      );
      
      updatedData['studentDetails'] = {};
    } else if (role == 'jobowner') {
      controllers['email'] = TextEditingController(
        text: _userData?['email'] ?? '',
      );
      controllers['shopName'] = TextEditingController(
        text: _userData?['jobOwnerDetails']?['shopName'] ?? '',
      );
      controllers['shopLocation'] = TextEditingController(
        text: _userData?['jobOwnerDetails']?['shopLocation'] ?? '',
      );
      controllers['shopRegisterNo'] = TextEditingController(
        text: _userData?['jobOwnerDetails']?['shopRegisterNo'] ?? '',
      );
      
      updatedData['jobOwnerDetails'] = {};
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: const Color.fromARGB(255, 0, 0, 0)),
            SizedBox(width: 8),
            Text(
              'Edit Profile',
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 0, 0),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Image Picker
              StatefulBuilder(
                builder: (context, setState) => Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                        
                        if (image != null) {
                          setState(() {
                            _imageFile = File(image.path);
                          });
                        }
                      },
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _imageFile != null 
                              ? FileImage(_imageFile!) 
                              : (_userData?['profileImage'] != null 
                                ? NetworkImage(_userData?['profileImage']) as ImageProvider 
                                : null),
                            child: (_imageFile == null && _userData?['profileImage'] == null)
                              ? const Icon(Icons.person, size: 40, color: Colors.grey)
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
                              child: const Icon(Icons.camera_alt, size: 20, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tap to change profile picture',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              
              if (role == 'student') ...[
                TextField(
                  controller: controllers['fullName'],
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: TextStyle(color: const Color.fromARGB(221, 0, 0, 0)),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controllers['mobileNumber'],
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    labelStyle: TextStyle(color: Colors.black87),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
              
              if (role == 'jobowner') ...[
                TextField(
                  controller: controllers['email'],
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.black87),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controllers['shopName'],
                  decoration: InputDecoration(
                    labelText: 'Shop Name',
                    labelStyle: TextStyle(color: Colors.black87),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controllers['shopLocation'],
                  decoration: InputDecoration(
                    labelText: 'Shop Location',
                    labelStyle: TextStyle(color: Colors.black87),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controllers['shopRegisterNo'],
                  decoration: InputDecoration(
                    labelText: 'Shop Register No',
                    labelStyle: TextStyle(color: Colors.black87),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                    ),
                  ),
                ),
              ],
              TextField(
                controller: controllers['bio'],
                decoration: InputDecoration(
                  labelText: 'Bio',
                  labelStyle: TextStyle(color: Colors.black87),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                ),
                minLines: 5,
                maxLines: 10,
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
              // Prepare updated data based on role
              if (role == 'student') {
                updatedData['studentDetails'] = {
                  'fullName': controllers['fullName']?.text,
                  'mobileNumber': controllers['mobileNumber']?.text,
                };
              } else if (role == 'jobowner') {
                updatedData['email'] = controllers['email']?.text;
                updatedData['jobOwnerDetails'] = {
                  'shopName': controllers['shopName']?.text,
                  'shopLocation': controllers['shopLocation']?.text,
                  'shopRegisterNo': controllers['shopRegisterNo']?.text,
                };
              }
              updatedData['bio'] = controllers['bio']?.text;
              
              _updateProfile(updatedData, profileImage: _imageFile);
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
    if (rating == null) return 0.0;
    if (rating is int) return rating.toDouble();
    if (rating is double) return rating;
    if (rating is String) return double.tryParse(rating) ?? 0.0;
    return 0.0;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
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

  void _showEditBioDialog() {
    final controllers = <String, TextEditingController>{};
    controllers['bio'] = TextEditingController(
      text: _userData?['bio'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: const Color.fromARGB(255, 0, 0, 0)),
            SizedBox(width: 8),
            Text(
              'Edit Bio',
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 0, 0),
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
                controller: controllers['bio'],
                decoration: InputDecoration(
                  labelText: 'Bio',
                  labelStyle: TextStyle(color: Colors.black87),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                ),
                minLines: 5,
                maxLines: 10,
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
              final Map<String, dynamic> updatedData = {};
              updatedData['bio'] = controllers['bio']?.text;
              _updateProfile(updatedData);
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
                    // Profile Image and Basic Info
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Profile Image
                            Stack(
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
                                  child: GestureDetector(
                                    onTap: _showEditProfileDialog,
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
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
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
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),

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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                color: const Color(0xFF98C9C5),
                                onPressed: _showEditBioDialog,
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
                          
                          Text(
                            'Member since: ${_userData?['createdAt'] != null ? _formatDate(_userData?['createdAt']) : 'Loading...'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Text(
                              _userData != null && _userData!['bio'] != null && _userData!['bio'].toString().isNotEmpty
                                  ? _userData!['bio']
                                  : 'No bio provided yet. Tap the edit button to add a bio.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.5,
                              ),
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
                          // Rating Display
                          if (_userData != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Column(
                                children: [
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
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatColumn('Jobs',
                                  _userData?['jobsCount']?.toString() ?? '0'),
                              _buildStatColumn('Experience',
                                  _userData?['experience']?.toString() ?? '0'),
                              _buildStatColumn('Completed',
                                  _userData?['completedJobs']?.toString() ?? '0'),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                color: const Color(0xFF98C9C5),
                                onPressed: _showEditProfileDialog,
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
                          
                          // Show different fields based on user role
                          if (_userData?['role'] == 'student') ...[
                            _buildInfoRow('Full Name', _userData?['studentDetails']?['fullName'] ?? 'Not provided'),
                            _buildInfoRow('Mobile', _userData?['studentDetails']?['mobileNumber'] ?? 'Not provided'),
                            _buildInfoRow('Role', 'Student'),
                          ] else if (_userData?['role'] == 'jobowner') ...[
                            _buildInfoRow('Email', _userData?['email'] ?? 'Not provided'),
                            _buildInfoRow('Shop Name', _userData?['jobOwnerDetails']?['shopName'] ?? 'Not provided'),
                            _buildInfoRow('Shop Location', _userData?['jobOwnerDetails']?['shopLocation'] ?? 'Not provided'),
                            _buildInfoRow('Shop Register No', _userData?['jobOwnerDetails']?['shopRegisterNo'] ?? 'Not provided'),
                            _buildInfoRow('Role', 'Job Owner'),
                          ] else ...[
                            _buildInfoRow('Email', _userData?['email'] ?? 'Not provided'),
                            _buildInfoRow('Role', _userData?['role'] ?? 'Not provided'),
                          ],
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
