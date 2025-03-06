import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/job.dart';
import '../services/job_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../widgets/notification_icon.dart';
import 'post_job_screen.dart';
import 'job_details_screen.dart';
import 'profile_screen.dart';
import 'community_screen.dart';
import 'jobs_screen.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final JobService _jobService = JobService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService();
  List<Job> _jobs = [];
  bool _isLoading = true;
  bool _isLoadingNotifications = true;
  int _unreadNotifications = 0;
  Map<String, Map<String, dynamic>> _jobOwnerData = {};

  // Track the current index of BottomNavigationBar
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadJobs();
    _loadNotificationCount();
    // Refresh notification count every 30 seconds
    _setupNotificationRefresh();
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
          _isLoading = false;
        });
        
        // Fetch job owner data for each job
        for (final job in jobs) {
          if (job.postedBy != null && job.postedBy!.isNotEmpty) {
            _fetchJobOwnerData(job.postedBy!);
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

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return CommunityScreen(
          onNavigateToTab: _onItemTapped,
        );
      case 1:
        return _buildHomeScreen();
      case 2:
        return const JobsScreen();
      default:
        return _buildHomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
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
        body: _getSelectedScreen(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.people), label: "Community"),
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.work), label: "Jobs"),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _navigateToPostJob,
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF98C9C5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {},
        ),
        title: const Text(
          'QuickHire',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          NotificationIcon(
            unreadCount: _unreadNotifications,
            isLoading: _isLoadingNotifications,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationScreen()),
              );
              // Refresh notification count after returning from notification screen
              _loadNotificationCount();
            },
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.black),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[300],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
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
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: List.generate(5, (index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 10),
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        SizedBox(height: 5),
                        Text("⭐⭐⭐⭐⭐"),
                      ],
                    ),
                  );
                }),
              ),
            ),
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
                  : _jobs.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No jobs available at the moment',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _jobs.length,
                          itemBuilder: (context, index) {
                            final job = _jobs[index];
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
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            'LKR ${job.salary['min']} - ${job.salary['max']}',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.favorite_border),
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

  Widget _buildLocationScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Screen'),
      ),
      body: Center(child: const Text('Location Screen Content')),
    );
  }
}
