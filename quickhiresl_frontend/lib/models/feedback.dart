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
      id: json['_id'] ?? json['id'],
      rating: json['rating'] is int
          ? json['rating']
          : int.tryParse(json['rating'].toString()) ?? 5,
      feedback: json['feedback'],
      applicationId: json['applicationId'] ?? json['application'] ?? 'unknown',
      fromUser: json['fromUser'] != null
          ? User.fromJson(json['fromUser'])
          : json['from'] != null
              ? User.fromJson(json['from'])
              : null,
      targetUser: json['targetUser'] != null
          ? User.fromJson(json['targetUser'])
          : json['to'] != null
              ? User.fromJson(json['to'])
              : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'])
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
