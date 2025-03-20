import 'dart:convert';
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

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
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

      // Try all possible endpoint formats
      final List<String> endpoints = [];

      // Add all possible endpoint formats
      if (widget.applicationId != null) {
        endpoints.add(
            '${Config.apiUrl}/feedback/application/${widget.applicationId}');
        endpoints.add(
            '${Config.apiUrl}/feedbacks/application/${widget.applicationId}');
        endpoints.add('${Config.apiUrl}/feedback/${widget.applicationId}');
      }

      if (widget.userId != null) {
        endpoints.add('${Config.apiUrl}/feedback/user/${widget.userId}');
        endpoints.add('${Config.apiUrl}/feedbacks/user/${widget.userId}');
        endpoints.add('${Config.apiUrl}/feedback/received/${widget.userId}');
        endpoints.add('${Config.apiUrl}/feedbacks/received/${widget.userId}');
      }

      List<app_models.Feedback> feedbacks = [];
      bool foundFeedback = false;

      // Try each endpoint until we find feedbacks
      for (final url in endpoints) {
        try {
          print("DEBUG: Trying endpoint: $url");

          final response = await http.get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          print("DEBUG: Response status from $url: ${response.statusCode}");

          if (response.statusCode == 200) {
            print("DEBUG: Response body from $url: ${response.body}");
            try {
              final data = json.decode(response.body);

              if (data['success'] == true) {
                var feedbacksJson = data['data'];

                if (feedbacksJson is List) {
                  // Direct list of feedbacks
                  print("DEBUG: Found list of ${feedbacksJson.length} items");
                  final newFeedbacks = feedbacksJson
                      .map((json) => app_models.Feedback.fromJson(json))
                      .toList();

                  if (newFeedbacks.isNotEmpty) {
                    feedbacks.addAll(newFeedbacks);
                    foundFeedback = true;
                    print(
                        "DEBUG: Added ${newFeedbacks.length} feedbacks from $url");
                  }
                } else if (feedbacksJson is Map) {
                  // Different structure with nested data
                  print(
                      "DEBUG: Found map with keys: ${feedbacksJson.keys.toList()}");

                  if (feedbacksJson.containsKey('received')) {
                    var receivedJson = feedbacksJson['received'];
                    if (receivedJson is List) {
                      final newFeedbacks = receivedJson
                          .map((json) => app_models.Feedback.fromJson(json))
                          .toList();

                      if (newFeedbacks.isNotEmpty) {
                        feedbacks.addAll(newFeedbacks);
                        foundFeedback = true;
                        print(
                            "DEBUG: Added ${newFeedbacks.length} nested feedbacks from $url");
                      }
                    }
                  }
                }
              }
            } catch (e) {
              print("DEBUG: Error parsing response from $url: $e");
            }
          }
        } catch (e) {
          print("DEBUG: Error with endpoint $url: $e");
        }

        // If we found feedbacks, we can stop trying endpoints
        if (foundFeedback) {
          break;
        }
      }

      print("DEBUG: Final feedback count: ${feedbacks.length}");

      // Calculate average rating with all feedbacks
      if (feedbacks.isNotEmpty) {
        double sum = 0;
        for (var feedback in feedbacks) {
          sum += feedback.rating.toDouble();
        }
        _averageRating = sum / feedbacks.length;
        print("DEBUG: Average rating: $_averageRating");
      }

      setState(() {
        _feedbacks = feedbacks;
        _isLoading = false;
      });
    } catch (e) {
      print("DEBUG: Error loading feedbacks: $e");
      setState(() {
        _error = 'An error occurred';
        _isLoading = false;
      });
    }
  }

  // Helper method to get the user name from feedback
  String _getUserNameForFeedback(app_models.Feedback feedback) {
    try {
      // First try to get the name from fromUser
      if (feedback.fromUser != null) {
        final user = feedback.fromUser!;

        // Try to use the user's name if it's not empty
        if (user.name.isNotEmpty) {
          return user.name;
        }

        // Fall back to email if name is empty
        if (user.email.isNotEmpty) {
          return user.email;
        }

        // If both name and email are empty, use the user ID
        if (user.id.isNotEmpty) {
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle indicator
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header with Ratings & Reviews
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button with title
                    Row(
                      children: [
                        // Back button
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        // Title
                        Text(
                          'Ratings & Reviews (${_feedbacks.length})',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RatingDisplay(
                      rating: _averageRating,
                      size: 28,
                      showText: false,
                      showValue: false,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Reviews List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadFeedbacks,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _feedbacks.isEmpty
                        ? const Center(
                            child: Text(
                              'No feedback available',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: widget.scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _feedbacks.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final feedback = _feedbacks[index];
                              return Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Review text
                                    Text(
                                      feedback.feedback ??
                                          'No comment provided',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF1F2937),
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Stars and name
                                    Row(
                                      children: [
                                        RatingDisplay(
                                          rating: feedback.rating.toDouble(),
                                          size: 20,
                                          showText: false,
                                          showValue: false,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _getUserNameForFeedback(feedback),
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
