import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import '../models/feedback.dart' as app_models;
import '../services/auth_service.dart';
import 'rating_display.dart';

void showFeedbackViewDialog(
  BuildContext context, {
  String? applicationId,
  String? userId,
}) {
  // Either applicationId or userId must be provided
  assert(applicationId != null || userId != null,
      'Either applicationId or userId must be provided');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return _FeedbackViewWidget(
            applicationId: applicationId,
            userId: userId,
            scrollController: scrollController,
          );
        },
      );
    },
  );
}

class _FeedbackViewWidget extends StatefulWidget {
  final String? applicationId;
  final String? userId;
  final ScrollController scrollController;

  const _FeedbackViewWidget({
    Key? key,
    this.applicationId,
    this.userId,
    required this.scrollController,
  }) : super(key: key);

  @override
  State<_FeedbackViewWidget> createState() => _FeedbackViewWidgetState();
}

class _FeedbackViewWidgetState extends State<_FeedbackViewWidget> {
  List<app_models.Feedback> _feedbacks = [];
  bool _isLoading = true;
  String? _error;
  double _averageRating = 0.0;
  final AuthService _authService = AuthService();
  String? _currentUserId;
  String? _currentUserEmail;

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
        endpoints.add(
            '${Config.apiUrl}/feedbacks/application/${widget.applicationId}');
      }

      print("DEBUG: Trying ${endpoints.length} possible endpoints");

      // First, check if the server is running at all
      try {
        final response = await http.get(Uri.parse('${Config.apiUrl}/health'));
        print("DEBUG: API health check status: ${response.statusCode}");
        if (response.statusCode == 200) {
          print("DEBUG: API server is running");
        } else {
          print(
              "DEBUG: API server might not be running properly. Status: ${response.statusCode}");
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

          print(
              "DEBUG: Response status from $endpoint: ${response.statusCode}");
          print("DEBUG: Response headers: ${response.headers}");
          if (response.statusCode == 200) {
            print(
                "DEBUG: Response body from $endpoint: ${response.body.substring(0, min(500, response.body.length))}...");

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
                  var possibleList = data.values
                      .firstWhere((value) => value is List, orElse: () => null);
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
                print(
                    "DEBUG: Found ${feedbackData.length} feedbacks from $endpoint");

                setState(() {
                  _isLoading = false;

                  _feedbacks = feedbackData
                      .map((item) {
                        try {
                          // Normalize the data structure
                          Map<String, dynamic> normalizedItem = item is Map
                              ? Map<String, dynamic>.from(item)
                              : {};

                          // Handle user objects with firstName/lastName instead of name
                          if (normalizedItem['userId'] != null) {
                            var userData = normalizedItem['userId'] is Map
                                ? Map<String, dynamic>.from(
                                    normalizedItem['userId'])
                                : {'id': normalizedItem['userId'].toString()};

                            if (userData.containsKey('firstName') ||
                                userData.containsKey('lastName')) {
                              String firstName =
                                  userData['firstName']?.toString() ?? '';
                              String lastName =
                                  userData['lastName']?.toString() ?? '';
                              userData['name'] = '$firstName $lastName'.trim();
                            }

                            normalizedItem['fromUser'] = userData;
                          }

                          if (normalizedItem['targetUserId'] != null) {
                            var targetUserData =
                                normalizedItem['targetUserId'] is Map
                                    ? Map<String, dynamic>.from(
                                        normalizedItem['targetUserId'])
                                    : {
                                        'id': normalizedItem['targetUserId']
                                            .toString()
                                      };

                            if (targetUserData.containsKey('firstName') ||
                                targetUserData.containsKey('lastName')) {
                              String firstName =
                                  targetUserData['firstName']?.toString() ?? '';
                              String lastName =
                                  targetUserData['lastName']?.toString() ?? '';
                              targetUserData['name'] =
                                  '$firstName $lastName'.trim();
                            }

                            normalizedItem['targetUser'] = targetUserData;
                          }

                          return app_models.Feedback.fromJson(normalizedItem);
                        } catch (e) {
                          print("DEBUG: Error parsing feedback item: $e");
                          print("DEBUG: Problem item: $item");
                          return null;
                        }
                      })
                      .whereType<app_models.Feedback>()
                      .toList();

                  if (_feedbacks.isNotEmpty) {
                    _averageRating = _feedbacks.fold(
                            0.0, (sum, feedback) => sum + feedback.rating) /
                        _feedbacks.length;
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
            print(
                "DEBUG: Error response from $endpoint: ${response.statusCode} - ${response.body}");
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
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Back button and title row
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Icon(Icons.arrow_back, color: Colors.black),
                  ),
                  Text(
                    'Ratings & Reviews',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  // Always show debug button during development to help with testing
                  IconButton(
                    icon: Icon(Icons.bug_report,
                        color: _error != null ? Colors.orange : Colors.grey),
                    onPressed: _testApiEndpoints,
                    tooltip: 'Test with Mock Data',
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            Flexible(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _error != null
                      ? _buildErrorDisplay()
                      : _feedbacks.isEmpty
                          ? _buildNoFeedbackDisplay()
                          : _buildFeedbackList(),
            ),
          ],
        ),
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

  Widget _buildFeedbackList() {
    return Column(
      children: [
        // Display average rating at the top
        if (_feedbacks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Average Rating',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _averageRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF98C9C5),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.star, color: Colors.amber, size: 24),
                    Text(
                      ' (${_feedbacks.length} ${_feedbacks.length == 1 ? 'review' : 'reviews'})',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        Expanded(
          child: ListView.separated(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(20),
            itemCount: _feedbacks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final feedback = _feedbacks[index];
              return _buildReviewCard(feedback, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(app_models.Feedback feedback, int index) {
    final userName = _getUserNameForFeedback(feedback);
    // Get initials for avatar
    final initials = userName != "Anonymous User"
        ? userName
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .join('')
            .toUpperCase()
        : 'AU';

    // Alternate card styles for visual interest
    final isEven = index % 2 == 0;
    final cardGradient = isEven
        ? LinearGradient(
            colors: [Colors.white, Color(0xFFF8F9FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [Color(0xFFF8F9FF), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and rating
          Row(
            children: [
              // User avatar with gradient
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF3498DB).withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials.length > 2 ? initials.substring(0, 2) : initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              // User name and rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        RatingDisplay(
                          rating: feedback.rating.toDouble(),
                          size: 18,
                          showText: false,
                          showValue: false,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${feedback.rating.toDouble()}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Review text with decorative quote marks
          if (feedback.feedback != null && feedback.feedback!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Icon(
                      Icons.format_quote,
                      color: Colors.grey.withOpacity(0.2),
                      size: 20,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                    child: Text(
                      feedback.feedback!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF4B5563),
                        height: 1.6,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Transform.rotate(
                      angle: 3.14, // 180 degrees in radians
                      child: Icon(
                        Icons.format_quote,
                        color: Colors.grey.withOpacity(0.2),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.grey[400],
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No comment provided',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Method to test the API with mock data for debugging
  Future<void> _testApiEndpoints() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print("DEBUG: Testing with mock feedback data");

      // Create mock feedback data
      final mockFeedbacks = [
        {
          "_id": "mock1",
          "rating": 5,
          "feedback":
              "This person was excellent to work with. Very professional and delivered high-quality work ahead of schedule.",
          "applicationId": "app123",
          "fromUser": {
            "_id": "user1",
            "firstName": "John",
            "lastName": "Smith",
            "email": "john.smith@example.com",
            "role": "jobseeker"
          },
          "targetUserId": {
            "_id": widget.userId ?? "default-user",
            "firstName": "Target",
            "lastName": "User",
            "email": "target@example.com",
            "role": "employer"
          },
          "createdAt":
              DateTime.now().subtract(Duration(days: 5)).toIso8601String(),
        },
        {
          "_id": "mock2",
          "rating": 4,
          "feedback":
              "Good job overall. Communication was clear and the work was completed as requested.",
          "applicationId": "app456",
          "userId": {
            "_id": "user2",
            "firstName": "Sarah",
            "lastName": "Johnson",
            "email": "sarah.j@example.com",
            "role": "jobseeker"
          },
          "targetUserId": {
            "_id": widget.userId ?? "default-user",
            "firstName": "Target",
            "lastName": "User",
            "email": "target@example.com",
            "role": "employer"
          },
          "createdAt":
              DateTime.now().subtract(Duration(days: 12)).toIso8601String(),
        },
        {
          "_id": "mock3",
          "rating": 3,
          "feedback":
              "Satisfactory work. Met expectations but could improve on timeliness.",
          "applicationId": "app789",
          "userId": {
            "_id": "user3",
            "firstName": "Michael",
            "lastName": "Wong",
            "email": "michael.w@example.com",
            "role": "jobseeker"
          },
          "targetUserId": {
            "_id": widget.userId ?? "default-user",
            "firstName": "Target",
            "lastName": "User",
            "email": "target@example.com",
            "role": "employer"
          },
          "createdAt":
              DateTime.now().subtract(Duration(days: 20)).toIso8601String(),
        }
      ];

      // Process the mock data
      setState(() {
        _isLoading = false;
        _feedbacks = mockFeedbacks
            .map((item) {
              try {
                // Handle user objects with firstName/lastName instead of name
                if (item['userId'] != null && item['userId'] is Map) {
                  Map<String, dynamic> userData =
                      item['userId'] as Map<String, dynamic>;
                  print("DEBUG: User data from API: $userData");

                  // Convert firstName/lastName to name
                  if (userData.containsKey('firstName') ||
                      userData.containsKey('lastName')) {
                    String firstName = userData['firstName']?.toString() ?? '';
                    String lastName = userData['lastName']?.toString() ?? '';
                    userData['name'] = '$firstName $lastName'.trim();
                    print(
                        "DEBUG: Created name from firstName/lastName: ${userData['name']}");
                  }

                  // Map to fromUser for our model
                  if (!item.containsKey('fromUser')) {
                    item['fromUser'] = userData;
                  }
                }

                if (item['targetUserId'] != null &&
                    item['targetUserId'] is Map) {
                  Map<String, dynamic> targetUserData =
                      item['targetUserId'] as Map<String, dynamic>;
                  print("DEBUG: Target user data from API: $targetUserData");

                  // Convert firstName/lastName to name
                  if (targetUserData.containsKey('firstName') ||
                      targetUserData.containsKey('lastName')) {
                    String firstName =
                        targetUserData['firstName']?.toString() ?? '';
                    String lastName =
                        targetUserData['lastName']?.toString() ?? '';
                    targetUserData['name'] = '$firstName $lastName'.trim();
                    print(
                        "DEBUG: Created target name from firstName/lastName: ${targetUserData['name']}");
                  }

                  // Map to targetUser for our model
                  if (!item.containsKey('targetUser')) {
                    item['targetUser'] = targetUserData;
                  }
                }

                return app_models.Feedback.fromJson(item);
              } catch (e) {
                print("DEBUG: Error parsing mock feedback item: $e");
                print("DEBUG: Problem item: $item");
                return null;
              }
            })
            .whereType<app_models.Feedback>()
            .toList();

        if (_feedbacks.isNotEmpty) {
          _averageRating =
              _feedbacks.fold(0.0, (sum, feedback) => sum + feedback.rating) /
                  _feedbacks.length;
        }
      });

      print("DEBUG: Successfully loaded ${_feedbacks.length} mock feedbacks");
      if (_feedbacks.isNotEmpty) {
        print(
            "DEBUG: First feedback user name: ${_getUserNameForFeedback(_feedbacks.first)}");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error with mock data: $e';
      });
      print("DEBUG: Error loading mock data: $e");
    }
  }
}
