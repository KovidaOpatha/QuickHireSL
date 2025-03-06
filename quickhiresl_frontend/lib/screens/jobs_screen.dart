import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/job.dart';
import '../services/job_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'job_details_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({Key? key}) : super(key: key);

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final JobService _jobService = JobService();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  List<Job> _jobs = [];
  List<Job> _filteredJobs = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  Map<String, Map<String, dynamic>> _jobOwnerData = {};

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          _filteredJobs = jobs;
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

  void _filterJobs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredJobs = _jobs;
      } else {
        _filteredJobs = _jobs.where((job) {
          final titleLower = job.title.toLowerCase();
          final companyLower = job.company.toLowerCase();
          final locationLower = job.location.toLowerCase();
          final searchLower = query.toLowerCase();
          
          return titleLower.contains(searchLower) ||
                 companyLower.contains(searchLower) ||
                 locationLower.contains(searchLower);
        }).toList();
      }
    });
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
    return Scaffold(
      backgroundColor: const Color(0xFF98C9C5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,  
        title: const Text(
          'Available Jobs',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadJobs,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterJobs,
                  decoration: InputDecoration(
                    hintText: "Search jobs, companies, or locations",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[300],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
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
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _searchController.text.isEmpty
                        ? 'All Jobs'
                        : 'Search Results (${_filteredJobs.length})',
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
                    : _filteredJobs.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.search_off,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchController.text.isEmpty
                                        ? 'No jobs available at the moment'
                                        : 'No jobs found matching "${_searchController.text}"',
                                    style: const TextStyle(color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
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
                                      builder: (context) => JobDetailsScreen(job: job),
                                    ),
                                  );
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
      ),
    );
  }
}
