import 'package:quickhiresl_frontend/models/user.dart';

class Feedback {
  final String? id;
  final int rating;
  final String? feedback;
  final String applicationId;
  final User? fromUser;
  final User? targetUser;
  final DateTime createdAt;

  Feedback({
    this.id,
    required this.rating,
    this.feedback,
    required this.applicationId,
    this.fromUser,
    this.targetUser,
    required this.createdAt,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['_id'],
      rating: json['rating'],
      feedback: json['feedback'],
      applicationId: json['applicationId'],
      fromUser:
          json['fromUser'] != null ? User.fromJson(json['fromUser']) : null,
      targetUser:
          json['targetUser'] != null ? User.fromJson(json['targetUser']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'rating': rating,
      'feedback': feedback,
      'applicationId': applicationId,
      'fromUser': fromUser?.id,
      'targetUser': targetUser?.id,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
