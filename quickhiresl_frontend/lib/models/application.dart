import 'package:quickhiresl_frontend/models/job.dart';
import 'package:quickhiresl_frontend/models/user.dart';

class Application {
  final String id;
  final Job job;
  final User applicant;
  final User jobOwner;
  final String status;
  final String coverLetter;
  final DateTime appliedAt;

  Application({
    required this.id,
    required this.job,
    required this.applicant,
    required this.jobOwner,
    required this.status,
    required this.coverLetter,
    required this.appliedAt,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    try {
      return Application(
        id: json['_id'] ?? '',
        job: json['job'] != null 
          ? (json['job'] is Map<String, dynamic> 
              ? Job.fromJson(json['job']) 
              : Job.fromJson(json['job'].toJson()))
          : Job.fromJson({}),
        applicant: json['applicant'] != null 
          ? (json['applicant'] is Map<String, dynamic> 
              ? User.fromJson(json['applicant']) 
              : User.fromJson(json['applicant'].toJson()))
          : User.fromJson({}),
        jobOwner: json['jobOwner'] != null 
          ? (json['jobOwner'] is Map<String, dynamic> 
              ? User.fromJson(json['jobOwner']) 
              : User.fromJson(json['jobOwner'].toJson()))
          : User.fromJson({}),
        status: json['status'] ?? 'pending',
        coverLetter: json['coverLetter'] ?? '',
        appliedAt: json['appliedAt'] != null 
          ? DateTime.parse(json['appliedAt']) 
          : (json['createdAt'] != null 
              ? DateTime.parse(json['createdAt']) 
              : DateTime.now()),
      );
    } catch (e) {
      print('Error parsing application: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'job': job.toJson(),
      'applicant': applicant.toJson(),
      'jobOwner': jobOwner.toJson(),
      'status': status,
      'coverLetter': coverLetter,
      'appliedAt': appliedAt.toIso8601String(),
    };
  }
}
