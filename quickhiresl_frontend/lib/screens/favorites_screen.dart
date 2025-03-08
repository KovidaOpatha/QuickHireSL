import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/job.dart';
import '../services/job_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../services/favorites_service.dart';
import 'job_details_screen.dart';
import 'home_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final JobService _jobService = JobService();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final FavoritesService _favoritesService = FavoritesService();
  List<Job> _allJobs = [];
  List<Job> _favoriteJobs = [];
  bool _isLoading = true;
  Map<String, Map<String, dynamic>> _jobOwnerData = {};

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final jobs = await _jobService.getJobs();
      final favoriteJobs = await _favoritesService.getFavoriteJobs(jobs);
      
      if (mounted) {
        setState(() {
          _allJobs = jobs;
          _favoriteJobs = favoriteJobs;
          _isLoading = false;
        });
        
        // Fetch job owner data for each favorite job
        for (final job in favoriteJobs) {
          if (job.postedBy != null && job.postedBy!.isNotEmpty) {
            _fetchJobOwnerData(job.postedBy!);
          }
        }
      }
    } catch (e) {
      print('Error loading favorite jobs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading favorite jobs: $e')),
        );
      }
    }
  }

  Future<void> _fetchJobOwnerData(String userId) async {
    try {
      final token = await _authService.getToken();
      
      final response = await http.get(
        Uri.parse('${_userService.baseUrl}/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['profileImage'] != null) {
          data['profilePicture'] = _userService.getFullImageUrl(data['profileImage']);
        }
        
        setState(() {
          _jobOwnerData[userId] = data;
        });
      } else {
        print('Failed to fetch job owner data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching job owner data: $e');
    }
  }

  Future<void> _toggleFavorite(String jobId) async {
    try {
      final newStatus = await _favoritesService.toggleFavorite(jobId);
      
      // If removed from favorites, update the UI
      if (!newStatus) {
        setState(() {
          _favoriteJobs.removeWhere((job) => job.id == jobId);
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? 'Added to favorites' : 'Removed from favorites'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating favorites')),
      );
    }
  }

  Widget _buildJobShimmer() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 150,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 14,
                  width: 100,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to home screen when back button is pressed
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
        return false; // Prevent default back button behavior
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF98C9C5),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Favorite Jobs',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              // Navigate to home screen when back button is pressed with home tab selected
              final homeScreen = HomeScreen();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => homeScreen),
                (route) => false,
              );
            },
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _loadJobs,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Favorites (${_favoriteJobs.length})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _isLoading
                      ? ListView.builder(
                          itemCount: 3,
                          itemBuilder: (context, index) {
                            return _buildJobShimmer();
                          },
                        )
                      : _favoriteJobs.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.favorite_border,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No favorite jobs yet',
                                      style: TextStyle(color: Colors.grey),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Tap the heart icon on jobs you like to add them to favorites',
                                      style: TextStyle(color: Colors.grey),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _favoriteJobs.length,
                              itemBuilder: (context, index) {
                                final job = _favoriteJobs[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => JobDetailsScreen(job: job),
                                      ),
                                    ).then((_) => _loadJobs()); // Refresh when returning
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF98C9C5),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: job.postedBy != null && 
                                                _jobOwnerData.containsKey(job.postedBy) && 
                                                _jobOwnerData[job.postedBy]!['profilePicture'] != null
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(
                                                    _jobOwnerData[job.postedBy]!['profilePicture'],
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Icon(
                                                        Icons.business,
                                                        color: Colors.white.withOpacity(0.7),
                                                        size: 30,
                                                      );
                                                    },
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.business,
                                                  color: Colors.white.withOpacity(0.7),
                                                  size: 30,
                                                ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                job.title,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                '${job.company} • ${job.location}',
                                                style: const TextStyle(color: Colors.grey),
                                              ),
                                              Text(
                                                'LKR ${job.salary.min} - ${job.salary.max}',
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            if (job.id != null) {
                                              _toggleFavorite(job.id!);
                                            }
                                          },
                                          child: const Icon(
                                            Icons.favorite,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
