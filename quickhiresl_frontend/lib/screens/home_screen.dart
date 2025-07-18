import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/job.dart';
import '../services/job_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../services/favorites_service.dart';
import '../widgets/notification_icon.dart';
import 'post_job_screen.dart';
import 'job_details_screen.dart';
import 'profile_screen.dart';
import 'community_screen.dart';
import 'jobs_screen.dart';
import 'notification_screen.dart';
import 'favorites_screen.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';
import 'matching_jobs_screen.dart';
import 'availability_screen.dart';
import 'job_owner_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final JobService _jobService = JobService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final FavoritesService _favoritesService = FavoritesService();
  final NotificationService _notificationService = NotificationService();

  final TextEditingController _searchController = TextEditingController();

  List<Job> _jobs = [];
  List<Job> _filteredJobs = [];
  bool _isLoading = true;
  int _unreadNotifications = 0;
  bool _isLoadingNotifications = true;
  Map<String, dynamic> _jobOwnerData = {};
  Map<String, bool> _favoriteStatus = {};
  String? _userRole;

  // Track the current index of BottomNavigationBar
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _getUserRole().then((_) {
      // Load other data after role is confirmed
      _loadJobs();
      _loadNotificationCount();
      _loadFavorites();
      _setupNotificationRefresh();
      _loadUserData();
    });
  }

  void _setupNotificationRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadNotificationCount();
        _setupNotificationRefresh();
      }
    });
  }

  Future<void> _loadNotificationCount() async {
    if (mounted) {
      setState(() {
        _isLoadingNotifications = true;
      });
    }

    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadNotifications = count;
          _isLoadingNotifications = false;
        });
      }
    } catch (e) {
      print('Error loading notification count: $e');
      if (mounted) {
        setState(() {
          _isLoadingNotifications = false;
        });
      }
    }
  }

  Future<void> _loadJobs() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final jobs = await _jobService.getJobs();
      if (mounted) {
        setState(() {
          _jobs = jobs;
          _filteredJobs = List.from(_jobs);
          _isLoading = false;
        });

        // Fetch job owner data for each job
        for (final job in jobs) {
          if (job.postedBy != null && job.postedBy!.isNotEmpty) {
            _fetchJobOwnerData(job.postedBy!);
          }

          // Load favorite status for each job
          if (job.id != null) {
            _loadFavoriteStatus(job.id!);
          }
        }
      }
    } catch (e) {
      print('Error loading jobs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading jobs: $e')),
        );
      }
    }
  }

  Future<void> _fetchJobOwnerData(String userId) async {
    try {
      final token = await _authService.getToken();

      print('Fetching job owner data for ID: $userId');

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
          data['profilePicture'] =
              _userService.getFullImageUrl(data['profileImage']);
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

  Future<void> _loadFavoriteStatus(String jobId) async {
    try {
      final isFavorite = await _favoritesService.isJobFavorite(jobId);
      if (mounted) {
        setState(() {
          _favoriteStatus[jobId] = isFavorite;
        });
      }
    } catch (e) {
      print('Error loading favorite status: $e');
    }
  }

  Future<void> _toggleFavorite(String jobId) async {
    try {
      final isFavorite = await _favoritesService.toggleFavorite(jobId);
      setState(() {
        _favoriteStatus[jobId] = isFavorite;
      });
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  Future<void> _navigateToPostJob() async {
    final token = await _authService.getToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login first')),
        );
      }
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PostJobScreen()),
    );

    if (result == true) {
      await _loadJobs();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _filterJobs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredJobs = List.from(_jobs);
      } else {
        query = query.toLowerCase();
        _filteredJobs = _jobs.where((job) {
          final title = job.title.toLowerCase();
          final company = job.company.toLowerCase();
          final location = job.location.toLowerCase();
          final description = job.description.toLowerCase();

          return title.contains(query) ||
              company.contains(query) ||
              location.contains(query) ||
              description.contains(query);
        }).toList();
      }
    });
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return CommunityScreen(onNavigateToTab: _onItemTapped);
      case 1:
        return _buildHomeContent();
      case 2:
        return const JobsScreen();
      case 3:
        // Only show For You page to students
        return _userRole == 'student' ? const MatchingJobsScreen() : _buildHomeContent();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Find your',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Part-time job',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    _showSearchPage(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.transparent),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.search, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          "Search jobs, companies, or locations",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Available now',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          // Update the container for the "Available Soon" message
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255), // Softer pastel background color
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: Colors.blue), // Icon to represent waiting
                SizedBox(width: 8.0), // Space between icon and text
                Text(
                  'Available Soon!',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // const SizedBox(height: 10),
          // SizedBox(
          //   height: 100,
          //   child: ListView(
          //     scrollDirection: Axis.horizontal,
          //     children: List.generate(5, (index) {
          //       return Container(
          //         margin: const EdgeInsets.only(right: 10),
          //         width: 80,
          //         decoration: BoxDecoration(
          //           color: Colors.white,
          //           borderRadius: BorderRadius.circular(10),
          //         ),
          //         child: const Column(
          //           mainAxisAlignment: MainAxisAlignment.center,
          //           children: [
          //             CircleAvatar(
          //               backgroundColor: Colors.grey,
          //               child: Icon(Icons.person, color: Colors.white),
          //             ),
          //             SizedBox(height: 5),
          //             Text("⭐⭐⭐⭐⭐"),
          //           ],
          //         ),
          //       );
          //     }),
          //   ),
          // ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recommended jobs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return _buildJobShimmer();
                    },
                  )
                : _filteredJobs.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No jobs available at the moment',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          // Show a snackbar to indicate refresh is happening
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Refreshing jobs...'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                          await _loadJobs();
                        },
                        child: ListView.builder(
                          itemCount: _filteredJobs.length,
                          itemBuilder: (context, index) {
                            final job = _filteredJobs[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        JobDetailsScreen(job: job),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Profile picture
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF98C9C5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: job.postedBy != null &&
                                              _jobOwnerData
                                                  .containsKey(job.postedBy) &&
                                              _jobOwnerData[job.postedBy]![
                                                      'profilePicture'] !=
                                                  null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                _jobOwnerData[job.postedBy]![
                                                    'profilePicture'],
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (context, error, stackTrace) {
                                                  return Icon(
                                                    Icons.business,
                                                    color: Colors.white
                                                        .withOpacity(0.7),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            'LKR ${job.salary.value}',
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
                                      child: Icon(
                                        job.id != null &&
                                                _favoriteStatus[job.id] == true
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: job.id != null &&
                                                _favoriteStatus[job.id] == true
                                            ? Colors.red
                                            : null,
                                        size: 20,
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
        ],
      ),
    );
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

  Future<void> _loadFavorites() async {
    try {
      final favoriteJobIds = await _favoritesService.getFavoriteJobIds();
      setState(() {
        for (String jobId in favoriteJobIds) {
          _favoriteStatus[jobId] = true;
        }
      });
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  void _showSearchPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _SearchPage(
          jobs: _jobs,
          jobOwnerData: _jobOwnerData,
          favoriteStatus: _favoriteStatus,
          onToggleFavorite: _toggleFavorite,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget selectedScreen = _getSelectedScreen();

    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 1) {
          setState(() {
            _selectedIndex = 1;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF98C9C5),
        appBar: _selectedIndex == 1
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.black),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ),
                title: Image.asset(
                  'assets/quickhire_logo.png', // Path to your logo
                  height: 30,  
                ),
                centerTitle: true,
                actions: [
                  NotificationIcon(
                    unreadCount: _unreadNotifications,
                    isLoading: _isLoadingNotifications,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NotificationScreen()),
                      );
                      // Refresh notification count after returning from notification screen
                      _loadNotificationCount();
                    },
                  ),
                  const SizedBox(width: 16),
                ],
              )
            : null,
        drawer: _buildDrawer(context),
        body: selectedScreen,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Community',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.work),
              label: 'Jobs',
            ),
            // Only show For You tab to students
            if (_userRole == 'student')
              const BottomNavigationBarItem(
                icon: Icon(Icons.recommend),
                label: 'For You',
              ),
          ],
        ),
        floatingActionButton: _selectedIndex == 1 && _userRole == 'jobowner'
            ? FloatingActionButton(
                onPressed: _navigateToPostJob,
                backgroundColor: const Color.fromARGB(200, 152, 201, 197),
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
      ),
    );
  }

  Map<String, dynamic>? _userData;

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

  Future<void> _getUserRole() async {
    try {
      final role = await _authService.getUserRole();
      print('[DEBUG] User role retrieved: $role');
      
      if (mounted) {
        setState(() {
          _userRole = role;
          print('[DEBUG] User role set in state: $_userRole');
        });
      }
      
      // Force a check on the secure storage to verify the role is saved
      final storedRole = await _authService.getUserRole();
      print('[DEBUG] Double-checking stored role: $storedRole');
    } catch (e) {
      print('[ERROR] Failed to get user role: $e');
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF8CBBB3), // Teal/mint color from the image
        child: Column(
          children: [
            // Back button at the top
            Container(
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.only(top: 40, left: 16),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () {
                  Navigator.pop(context); // Close drawer
                },
              ),
            ),
            
            // Profile image with green border
            Container(
              margin: const EdgeInsets.only(top: 30),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF4CAF50), // Green border
                  width: 3,
                ),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator() 
                : CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: _userData?['profileImage'] != null && _userData!['profileImage'].isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            _userData!['profileImage'],
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                            errorBuilder: (context, error, stackTrace) {
                              print('[ERROR] Failed to load profile image: $error');
                              return const Icon(Icons.person, size: 70, color: Colors.black54);
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          ),
                        )
                      : const Icon(Icons.person, size: 70, color: Colors.black54),
                  ),
            ),
            
            // User name and app name/tagline
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 40),
              child: Column(
                children: [
                  // User name
                  if (!_isLoading && _userData != null)
                    Text(
                      _userData?['name'] ?? 'User',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 4),
                  const Text(
                    'Find your next opportunity', // Your tagline from original code
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Favorites menu item
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: const Icon(Icons.favorite, color: Color.fromARGB(255, 0, 0, 0)),
                title: const Text(
                  'Favorites',
                  style: TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const FavoritesScreen()),
                  );
                },
              ),
            ),

            // Profile menu item
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: const Icon(Icons.person, color: Color.fromARGB(255, 0, 0, 0)),
                title: const Text(
                  'Profile',
                  style: TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfileScreen()),
                  );
                },
              ),
            ),

            // Settings menu item
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: const Icon(Icons.settings, color: Color.fromARGB(255, 0, 0, 0)),
                title: const Text(
                  'Settings',
                  style: TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  _showSettingsOptions(context);
                },
              ),
            ),

            // Help & Support menu item
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: const Icon(Icons.help, color: Color.fromARGB(255, 0, 0, 0)),
                title: const Text(
                  'Help & Support',
                  style: TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  // Navigate to help screen
                },
              ),
            ),

            // Add Job Posting menu item for job owners
            if (_userRole == 'jobowner')
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: const Icon(Icons.post_add, color: Color.fromARGB(255, 0, 0, 0)),
                  title: const Text(
                    'Post a Job',
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    _navigateToPostJob();
                  },
                ),
              ),

            // Job Owner Dashboard menu item for job owners
            if (_userRole == 'jobowner')
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: const Icon(Icons.dashboard, color: Color.fromARGB(255, 0, 0, 0)),
                  title: const Text(
                    'Job Owner Dashboard',
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const JobOwnerDashboard(),
                      ),
                    );
                  },
                ),
              ),

            // View My Applications menu item for students
            if (_userRole == 'student')
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: const Icon(Icons.work, color: Color.fromARGB(255, 0, 0, 0)),
                  title: const Text(
                    'View My Applications',
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.pushNamed(context, '/applications');
                  },
                ),
              ),

            // Spacer to push logout to the bottom
            const Spacer(),

            // Logout menu item at the bottom
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Color.fromARGB(255, 0, 0, 0)),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
                onTap: () async {
                  Navigator.pop(context); // Close the drawer

                  // Show confirmation dialog
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.white,
                        title: const Text('Confirm Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the dialog
                            },
                            child: const Text('Cancel',
                                style: TextStyle(color: Colors.black)),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(context).pop(); // Close the dialog
                              await _authService.logout();
                              // Navigate to login screen and clear all previous routes
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (context) => const LoginScreen()),
                                (route) => false,
                              );
                            },
                            child: const Text('Logout',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add this new method to HomeScreen class
  void _showSettingsOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),
              
              // Change Password Option
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Change Password'),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),
              
              // Notification Settings Option
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notification Settings'),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  // Navigate to Notification Settings (you can implement this later)
                },
              ),
              
              // Account Settings Option
              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: const Text('Account Settings'),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  // Navigate to Account Settings (you can implement this later)
                },
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _SearchPage extends StatefulWidget {
  final List<Job> jobs;
  final Map<String, dynamic> jobOwnerData;
  final Map<String, bool> favoriteStatus;
  final Function(String) onToggleFavorite;

  const _SearchPage({
    required this.jobs,
    required this.jobOwnerData,
    required this.favoriteStatus,
    required this.onToggleFavorite,
  });

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<_SearchPage> {
  final JobService _jobService = JobService();
  List<Job> _filteredJobs = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final jobs = await _jobService.getJobs();
      setState(() {
        _filteredJobs = jobs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterJobs(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _loadJobs();
      } else {
        query = query.toLowerCase();
        _filteredJobs = _filteredJobs.where((job) {
          final title = job.title.toLowerCase();
          final company = job.company.toLowerCase();
          final location = job.location.toLowerCase();
          final description = job.description.toLowerCase();

          return title.contains(query) ||
              company.contains(query) ||
              location.contains(query) ||
              description.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF98C9C5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Search Jobs',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                onChanged: _filterJobs,
                decoration: const InputDecoration(
                  hintText: 'Search jobs, companies, or locations',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredJobs.isEmpty
                      ? const Center(
                          child: Text(
                            'No jobs found',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredJobs.length,
                          itemBuilder: (context, index) {
                            final job = _filteredJobs[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        JobDetailsScreen(job: job),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              job.title,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.favorite,
                                              color: job.id != null &&
                                                      widget.favoriteStatus[job.id] ==
                                                          true
                                                  ? Colors.red
                                                  : null,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              if (job.id != null) {
                                                widget.onToggleFavorite(job.id!);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
