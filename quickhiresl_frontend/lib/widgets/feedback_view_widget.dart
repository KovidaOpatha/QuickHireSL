import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import '../models/feedback.dart' as app_models;
import '../services/auth_service.dart';
import 'rating_display.dart';

class FeedbackViewWidget extends StatefulWidget {
  final String? applicationId;
  final String? userId;

  const FeedbackViewWidget({
    Key? key,
    this.applicationId,
    this.userId,
  }) : super(key: key);

  @override
  State<FeedbackViewWidget> createState() => _FeedbackViewWidgetState();
}

class _FeedbackViewWidgetState extends State<FeedbackViewWidget> {
  List<app_models.Feedback> _feedbacks = [];
  bool _isLoading = true;
  String? _error;
  double _averageRating = 0.0;
  final AuthService _authService = AuthService();
  String? _currentUserId;
  String? _currentUserEmail;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _getCurrentUserInfo();
    _loadFeedbacks();
  }

  Future<void> _getCurrentUserInfo() async {
    _currentUserId = await _authService.getUserId();
    _currentUserEmail = await _authService.getEmail();
  }

  Future<void> _loadFeedbacks() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        // Clear existing feedbacks to avoid duplication
        _feedbacks = [];
        _averageRating = 0.0;
      });

      print("DEBUG: Starting to load feedbacks");

      final token = await const FlutterSecureStorage().read(key: 'jwt_token');

      if (token == null) {
        setState(() {
          _error = 'Please login to view feedbacks';
          _isLoading = false;
        });
        print("DEBUG: No JWT token found");
        return;
      }

      print("DEBUG: Application ID: ${widget.applicationId}");
      print("DEBUG: User ID: ${widget.userId}");
      
      // Try multiple endpoint formats to handle potential backend inconsistencies
      final List<String> endpoints = [];
      
      if (widget.userId != null) {
        // Use the correct endpoint based on the backend implementation
        endpoints.add('${Config.apiUrl}/feedbacks/user/${widget.userId}');
        endpoints.add('${Config.apiUrl}/feedbacks/user/${widget.userId}/all');
      }
      
      if (widget.applicationId != null) {
        // Use the correct endpoint based on the backend implementation
        endpoints.add('${Config.apiUrl}/feedbacks/application/${widget.applicationId}');
      }
      
      print("DEBUG: Trying ${endpoints.length} possible endpoints");
      
      // First, check if the server is running at all
      try {
        final response = await http.get(Uri.parse('${Config.apiUrl}/health'));
        print("DEBUG: API health check status: ${response.statusCode}");
        if (response.statusCode == 200) {
          print("DEBUG: API server is running");
        } else {
          print("DEBUG: API server might not be running properly. Status: ${response.statusCode}");
        }
      } catch (e) {
        print("DEBUG: API server seems to be down: $e");
      }
      
      bool foundValidResponse = false;
      
      // Try each endpoint until we find a valid response
      for (final endpoint in endpoints) {
        try {
          print("DEBUG: Trying endpoint: $endpoint");
          
          final response = await http.get(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
          
          print("DEBUG: Response status from $endpoint: ${response.statusCode}");
          print("DEBUG: Response headers: ${response.headers}");
          if (response.statusCode == 200) {
            print("DEBUG: Response body from $endpoint: ${response.body.substring(0, min(500, response.body.length))}...");
            
            try {
              final data = json.decode(response.body);
              print("DEBUG: Raw API response data: $data");
              
              // Handle different response formats
              List<dynamic> feedbackData;
              
              if (data is Map) {
                if (data.containsKey('success') && data.containsKey('data')) {
                  // Format: { success: true, data: [...] }
                  feedbackData = data['data'] as List;
                } else if (data.containsKey('feedbacks')) {
                  // Format: { feedbacks: [...] }
                  feedbackData = data['feedbacks'] as List;
                } else {
                  // Try to find any list in the response
                  var possibleList = data.values.firstWhere(
                    (value) => value is List,
                    orElse: () => null
                  );
                  if (possibleList != null) {
                    feedbackData = possibleList as List;
                  } else {
                    // Wrap single feedback in a list
                    feedbackData = [data];
                  }
                }
              } else if (data is List) {
                // Direct list format
                feedbackData = data;
              } else {
                throw Exception('Unexpected response format');
              }
              
              if (feedbackData.isNotEmpty) {
                print("DEBUG: Found ${feedbackData.length} feedbacks from $endpoint");
                
                setState(() {
                  _isLoading = false;
                  
                  _feedbacks = feedbackData.map((item) {
                    try {
                      // Normalize the data structure
                      Map<String, dynamic> normalizedItem = item is Map ? Map<String, dynamic>.from(item) : {};
                      
                      // Handle user objects with firstName/lastName instead of name
                      if (normalizedItem['userId'] != null) {
                        var userData = normalizedItem['userId'] is Map ? 
                          Map<String, dynamic>.from(normalizedItem['userId']) : 
                          {'id': normalizedItem['userId'].toString()};
                        
                        if (userData.containsKey('firstName') || userData.containsKey('lastName')) {
                          String firstName = userData['firstName']?.toString() ?? '';
                          String lastName = userData['lastName']?.toString() ?? '';
                          userData['name'] = '$firstName $lastName'.trim();
                        }
                        
                        normalizedItem['fromUser'] = userData;
                      }
                      
                      if (normalizedItem['targetUserId'] != null) {
                        var targetUserData = normalizedItem['targetUserId'] is Map ? 
                          Map<String, dynamic>.from(normalizedItem['targetUserId']) : 
                          {'id': normalizedItem['targetUserId'].toString()};
                        
                        if (targetUserData.containsKey('firstName') || targetUserData.containsKey('lastName')) {
                          String firstName = targetUserData['firstName']?.toString() ?? '';
                          String lastName = targetUserData['lastName']?.toString() ?? '';
                          targetUserData['name'] = '$firstName $lastName'.trim();
                        }
                        
                        normalizedItem['targetUser'] = targetUserData;
                      }
                      
                      return app_models.Feedback.fromJson(normalizedItem);
                    } catch (e) {
                      print("DEBUG: Error parsing feedback item: $e");
                      print("DEBUG: Problem item: $item");
                      return null;
                    }
                  }).whereType<app_models.Feedback>().toList();
                  
                  if (_feedbacks.isNotEmpty) {
                    _averageRating = _feedbacks.fold(0.0, 
                      (sum, feedback) => sum + feedback.rating) / _feedbacks.length;
                  }
                });
                
                foundValidResponse = true;
                print("DEBUG: Successfully processed feedback from $endpoint");
                break;
              }
            } catch (e) {
              print("DEBUG: Error parsing response from $endpoint: $e");
            }
          } else if (response.statusCode == 404) {
            print("DEBUG: Endpoint not found: $endpoint");
          } else {
            print("DEBUG: Error response from $endpoint: ${response.statusCode} - ${response.body}");
          }
        } catch (e) {
          print("DEBUG: Exception trying endpoint $endpoint: $e");
        }
      }
      
      if (!foundValidResponse) {
        setState(() {
          _isLoading = false;
          _error = 'Could not find feedback data. Please try again later.';
        });
        print("DEBUG: No valid feedback found from any endpoint");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error: $e';
      });
      print("DEBUG: Exception during feedback loading: $e");
    }
  }

  // Helper method to get the user name from feedback
  String _getUserNameForFeedback(app_models.Feedback feedback) {
    try {
      // First try to get the name from fromUser
      if (feedback.fromUser != null) {
        final user = feedback.fromUser!;
        
        // If this feedback is from the current logged-in user, show "You"
        if (_currentUserId != null && user.id == _currentUserId) {
          return "You";
        }
        
        // Try to use the user's name if it's not empty
        if (user.name.isNotEmpty) {
          return user.name;
        }
        
        // Fall back to email if name is empty
        if (user.email.isNotEmpty) {
          // If this is the current user's email, show "You"
          if (_currentUserEmail != null && user.email == _currentUserEmail) {
            return "You";
          }
          return user.email;
        }
        
        // If both name and email are empty, use the user ID
        if (user.id.isNotEmpty) {
          // If this is the current user's ID, show "You"
          if (_currentUserId != null && user.id == _currentUserId) {
            return "You";
          }
          return "User ${user.id}";
        }
      }
      
      // If fromUser is not available or has no usable identifier, return a placeholder
      return "Anonymous User";
    } catch (e) {
      print("Error getting user name: $e");
      return "Anonymous User";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8F9FF),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Average rating display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFF98C9C5),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF98C9C5).withOpacity(0.3),
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    _averageRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          // Feedback list
          Container(
            constraints: BoxConstraints(
              maxHeight: 300, // Fixed height for the feedback list
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorDisplay()
                    : _feedbacks.isEmpty
                        ? _buildNoFeedbackDisplay()
                        : ListView.separated(
                            controller: _scrollController,
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _feedbacks.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: Colors.grey.withOpacity(0.1),
                            ),
                            itemBuilder: (context, index) {
                              final feedback = _feedbacks[index];
                              return _buildReviewCard(feedback, index);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          SizedBox(height: 16),
          Text(
            'Error Loading Feedback',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _error ?? 'An unknown error occurred',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFeedbacks,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF98C9C5),
            ),
            child: Text('Try Again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFeedbackDisplay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feedback_outlined, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              'No Feedback Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'There are no ratings or reviews available.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(app_models.Feedback feedback, int index) {
    bool isEven = index % 2 == 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : Color(0xFFFAFAFA),
        border: Border(
          left: BorderSide(
            color: Color(0xFF98C9C5).withOpacity(isEven ? 0.5 : 0.2),
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Feedback text
          if (feedback.feedback != null && feedback.feedback!.isNotEmpty)
            Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                feedback.feedback!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
          // Rating and Anonymous User
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RatingDisplay(
                  rating: feedback.rating.toDouble(),
                  size: 16,
                  showText: false,
                  showValue: false,
                ),
                const SizedBox(width: 8),
                Text(
                  'Anonymous User',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
