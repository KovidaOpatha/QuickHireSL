import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/job.dart';
import '../services/job_matching_service.dart';
import '../services/auth_service.dart';
import 'job_details_screen.dart';

class MatchingJobsScreen extends StatefulWidget {
  const MatchingJobsScreen({Key? key}) : super(key: key);

  @override
  _MatchingJobsScreenState createState() => _MatchingJobsScreenState();
}

class _MatchingJobsScreenState extends State<MatchingJobsScreen> {
  final JobMatchingService _jobMatchingService = JobMatchingService();
  final AuthService _authService = AuthService();
  
  List<dynamic> _matchingJobs = [];
  bool _isLoading = true;
  String? _userId;
  String _errorMessage = '';
  
  // Filter options
  String _sortBy = 'score';
  String _sortOrder = 'desc';
  int _minScore = 30;
  String? _selectedLocation;
  String? _selectedCategory;
  
  // List of common locations and categories for filtering
  final List<String> _locations = [
    'Colombo',
    'Gampaha',
    'Kalutara',
    'Kandy',
    'Galle',
    'Matara',
    'Jaffna',
    'Batticaloa',
    'Anuradhapura',
  ];
  
  final List<String> _categories = [
    'IT & Software',
    'Accounting',
    'Marketing',
    'Sales',
    'Customer Service',
    'Healthcare',
    'Education',
    'Engineering',
    'Hospitality',
    'Retail',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = await _authService.getUserId();
      
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not authenticated';
        });
        return;
      }
      
      _userId = userId;
      await _loadMatchingJobs();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading user data: $e';
      });
    }
  }

  Future<void> _loadMatchingJobs() async {
    if (_userId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final response = await _jobMatchingService.getMatchingJobs(
        _userId!,
        limit: 20,
        minScore: _minScore,
        includeDetails: true,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        location: _selectedLocation,
        category: _selectedCategory,
      );
      
      if (response['success']) {
        setState(() {
          _matchingJobs = response['jobs'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response['error'] ?? 'Failed to load matching jobs';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  void _applyFilters() {
    _loadMatchingJobs();
  }

  void _resetFilters() {
    setState(() {
      _sortBy = 'score';
      _sortOrder = 'desc';
      _minScore = 30;
      _selectedLocation = null;
      _selectedCategory = null;
    });
    _loadMatchingJobs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF98C9C5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF98C9C5),
        title: const Text(
          'Matching Jobs',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : _matchingJobs.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'No matching jobs found. Try adjusting your preferences or filters.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMatchingJobs,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _matchingJobs.length,
                        itemBuilder: (context, index) {
                          final job = _matchingJobs[index];
                          return _buildJobCard(job);
                        },
                      ),
                    ),
    );
  }

  Widget _buildJobCard(dynamic job) {
    final matchScore = job['matchScore'] ?? 0;
    final matchReasons = List<String>.from(job['matchReasons'] ?? []);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          print('Job data: $job'); // Debug log to see the job data structure
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobDetailsScreen(job: Job(
                id: job['jobId'],
                title: job['title'] ?? '',
                company: job['company'] ?? '',
                location: job['location'] ?? '',
                description: job['description'] ?? '',
                requirements: List<String>.from(job['requirements'] ?? []),
                salary: Salary(
                  value: job['salary'] != null 
                    ? (job['salary'] is int || job['salary'] is double) 
                      ? job['salary'] 
                      : job['salary']['min'] != null 
                        ? job['salary']['min'] 
                        : job['salary']['value'] != null 
                          ? job['salary']['value'] 
                          : 0
                    : 0,
                  currency: job['salary'] != null && job['salary']['currency'] != null ? job['salary']['currency'] : 'LKR',
                ),
                postedBy: job['postedBy']?.toString() ?? '',
                createdAt: job['postedDate'] != null ? DateTime.parse(job['postedDate']) : DateTime.now(),
                employmentType: job['employmentType'] ?? '',
                experienceLevel: job['experienceLevel'] ?? '',
              )),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      job['title'] ?? 'Job Title',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getMatchScoreColor(matchScore),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$matchScore% Match',
                      style: TextStyle(
                        color: matchScore > 50 ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                job['company'] ?? 'Company Name',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    job['location'] ?? 'Location',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.category, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    job['category'] ?? 'Category',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              if (job['salary'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Rs. ${job['salary']}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Why this matches you:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ...matchReasons.map((reason) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reason,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMatchScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Filter Jobs'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sort by
                  const Text(
                    'Sort by:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _sortBy,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'score', child: Text('Match Score')),
                      DropdownMenuItem(value: 'date', child: Text('Date Posted')),
                      DropdownMenuItem(value: 'salary', child: Text('Salary')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _sortBy = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Sort order
                  const Text(
                    'Sort order:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _sortOrder,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'desc', child: Text('Highest to Lowest')),
                      DropdownMenuItem(value: 'asc', child: Text('Lowest to Highest')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _sortOrder = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Minimum match score
                  const Text(
                    'Minimum match score:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _minScore.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 10,
                    label: '$_minScore%',
                    activeColor: const Color(0xFF98C9C5),
                    onChanged: (value) {
                      setState(() {
                        _minScore = value.round();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Location filter
                  const Text(
                    'Location:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: _selectedLocation,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Locations')),
                      ..._locations.map((location) => DropdownMenuItem(
                        value: location,
                        child: Text(location),
                      )).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedLocation = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Category filter
                  const Text(
                    'Category:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Categories')),
                      ..._categories.map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      )).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetFilters();
                },
                child: const Text('Reset'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _applyFilters();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF98C9C5),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }
}
