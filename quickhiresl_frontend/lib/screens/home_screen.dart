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

  // Track the current index of BottomNavigationBar
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadJobs();
    _loadNotificationCount();
    _loadFavorites();
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
                                            color:
                                                Colors.white.withOpacity(0.7),
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
                title: const Text(
                  'QuickHire',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Community',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work),
              label: 'Jobs',
            ),
          ],
        ),
        floatingActionButton: _selectedIndex == 1
            ? FloatingActionButton(
                onPressed: _navigateToPostJob,
                child: const Icon(Icons.add),
                backgroundColor: Colors.black,
              )
            : null,
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF98C9C5),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.black),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'QuickHire',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Find your next opportunity',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: const Text(
                'Favorites',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
            ListTile(
              leading: const Icon(Icons.person, color: Colors.black),
              title: const Text(
                'Profile',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.black),
              title: const Text(
                'Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Navigate to settings screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.help, color: Colors.black),
              title: const Text(
                'Help & Support',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Navigate to help screen
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.black),
              title: const Text(
                'Logout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
          ],
        ),
      ),
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
  final TextEditingController _searchController = TextEditingController();
  List<Job> _filteredJobs = [];

  @override
  void initState() {
    super.initState();
    _filteredJobs = List.from(widget.jobs);
  }

  void _filterJobs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredJobs = List.from(widget.jobs);
      } else {
        query = query.toLowerCase();
        _filteredJobs = widget.jobs.where((job) {
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterJobs,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Search jobs, companies, or locations",
                  prefixIcon: const Icon(Icons.search),
                  border: InputBorder.none,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterJobs('');
                          },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredJobs.isEmpty
                  ? const Center(
                      child: Text(
                        'No jobs found',
                        style: TextStyle(color: Colors.black54, fontSize: 16),
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
                                          widget.jobOwnerData
                                              .containsKey(job.postedBy) &&
                                          widget.jobOwnerData[job.postedBy]
                                                  ?['profilePicture'] !=
                                              null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            widget.jobOwnerData[job.postedBy]
                                                ['profilePicture'],
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
                                      widget.onToggleFavorite(job.id!);
                                      setState(() {}); // Refresh UI
                                    }
                                  },
                                  child: Icon(
                                    job.id != null &&
                                            widget.favoriteStatus[job.id] ==
                                                true
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: job.id != null &&
                                            widget.favoriteStatus[job.id] ==
                                                true
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
          ],
        ),
      ),
    );
  }
}
