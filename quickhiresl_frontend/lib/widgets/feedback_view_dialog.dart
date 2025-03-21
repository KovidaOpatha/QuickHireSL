import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import '../models/feedback.dart' as app_models;
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
      return Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: _FeedbackViewWidget(
          applicationId: applicationId,
          userId: userId,
          scrollController: ScrollController(),
        ),
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
  String? _currentUserId;
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _getCurrentUserInfo();
    _loadFeedbacks();
  }

  Future<void> _getCurrentUserInfo() async {
    try {
      final storage = FlutterSecureStorage();
      _currentUserId = await storage.read(key: 'user_id');
      _currentUserEmail = await storage.read(key: 'email');
    } catch (e) {
      print("Error getting user info: $e");
    }
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
        endpoints.add('${Config.apiUrl}/feedback/user/${widget.userId}');
      }

      if (widget.applicationId != null) {
        endpoints.add(
            '${Config.apiUrl}/feedback/application/${widget.applicationId}');
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

  String _getUserNameForFeedback(app_models.Feedback feedback) {
    if (feedback.fromUser != null) {
      return feedback.fromUser!.name ?? 'Anonymous User';
    } else if (feedback.targetUser != null) {
      return feedback.targetUser!.name ?? 'Anonymous User';
    } else {
      return 'Anonymous User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Ratings & Reviews',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF98C9C5)),
              ),
            )
          : _error != null
              ? _buildErrorDisplay()
              : _feedbacks.isEmpty
                  ? _buildNoFeedbackDisplay()
                  : _buildFeedbackList(),
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
    // Group feedbacks by rating
    Map<int, List<app_models.Feedback>> groupedFeedbacks = {};
    for (var feedback in _feedbacks) {
      groupedFeedbacks.putIfAbsent(feedback.rating, () => []);
      groupedFeedbacks[feedback.rating]!.add(feedback);
    }

    // Sort ratings in descending order
    final sortedRatings = groupedFeedbacks.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF8F9FF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with total reviews and average rating
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  offset: Offset(0, 2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ratings & Reviews (${_feedbacks.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          RatingDisplay(
                            rating: _averageRating,
                            size: 20,
                            showText: false,
                            showValue: false,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF98C9C5),
                        Color(0xFF98C9C5).withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF98C9C5).withOpacity(0.2),
                        offset: Offset(0, 3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _averageRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rating distribution
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rating Distribution',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 12),
                ...List.generate(5, (index) {
                  final rating = 5 - index;
                  final count = groupedFeedbacks[rating]?.length ?? 0;
                  final percentage = _feedbacks.isEmpty
                      ? 0.0
                      : (count / _feedbacks.length * 100);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          '$rating',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(Icons.star, size: 14, color: Color(0xFFFFB800)),
                        SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF98C9C5)),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${count.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          // Feedback sections
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: sortedRatings.length,
              itemBuilder: (context, index) {
                final rating = sortedRatings[index];
                final feedbacks = groupedFeedbacks[rating]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          Text(
                            '$rating Star Reviews',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '(${feedbacks.length})',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...feedbacks.map((feedback) => _buildReviewCard(feedback)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(app_models.Feedback feedback) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(0xFF98C9C5).withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (feedback.feedback != null && feedback.feedback!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Text(
                  feedback.feedback!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFFFAFAFA),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  RatingDisplay(
                    rating: feedback.rating.toDouble(),
                    size: 16,
                    showText: false,
                    showValue: false,
                  ),
                  SizedBox(width: 8),
                  Text(
                    _getUserNameForFeedback(feedback),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
