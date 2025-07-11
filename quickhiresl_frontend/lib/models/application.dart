import 'package:quickhiresl_frontend/models/job.dart';
import 'package:quickhiresl_frontend/models/user.dart';

class CompletionDetails {
  final String? requestedBy;
  final DateTime? requestedAt;
  final DateTime? confirmedAt;

  CompletionDetails({
    this.requestedBy,
    this.requestedAt,
    this.confirmedAt,
  });

  factory CompletionDetails.fromJson(Map<String, dynamic> json) {
    return CompletionDetails(
      requestedBy: json['requestedBy'],
      requestedAt: json['requestedAt'] != null ? DateTime.parse(json['requestedAt']) : null,
      confirmedAt: json['confirmedAt'] != null ? DateTime.parse(json['confirmedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestedBy': requestedBy,
      'requestedAt': requestedAt?.toIso8601String(),
      'confirmedAt': confirmedAt?.toIso8601String(),
    };
  }
}

class Application {
  final String id;
  final Job job;
  final User applicant;
  final User jobOwner;
  final String status;
  final String coverLetter;
  final DateTime appliedAt;
  final CompletionDetails? completionDetails;

  Application({
    required this.id,
    required this.job,
    required this.applicant,
    required this.jobOwner,
    required this.status,
    required this.coverLetter,
    required this.appliedAt,
    this.completionDetails,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing application JSON: ${json['_id']}');
      print('Full JSON data: $json');
      print('Completion details from JSON: ${json['completionDetails']}');
      
      // Handle job data
      Job jobData;
      if (json['job'] != null) {
        if (json['job'] is Map<String, dynamic>) {
          jobData = Job.fromJson(json['job']);
        } else {
          print('Warning: job data is not a map: ${json['job']}');
          jobData = Job.fromJson({});
        }
      } else {
        jobData = Job.fromJson({});
      }

      // Handle applicant data
      User applicantData;
      if (json['applicant'] != null) {
        if (json['applicant'] is Map<String, dynamic>) {
          applicantData = User.fromJson(json['applicant']);
        } else {
          print('Warning: applicant data is not a map: ${json['applicant']}');
          applicantData = User.fromJson({});
        }
      } else {
        applicantData = User.fromJson({});
      }

      // Handle job owner data
      User jobOwnerData;
      if (json['jobOwner'] != null) {
        if (json['jobOwner'] is Map<String, dynamic>) {
          jobOwnerData = User.fromJson(json['jobOwner']);
        } else {
          print('Warning: jobOwner data is not a map: ${json['jobOwner']}');
          jobOwnerData = User.fromJson({});
        }
      } else {
        jobOwnerData = User.fromJson({});
      }

      return Application(
        id: json['_id']?.toString() ?? '',
        job: jobData,
        applicant: applicantData,
        jobOwner: jobOwnerData,
        status: json['status']?.toString() ?? 'pending',
        coverLetter: json['coverLetter']?.toString() ?? '',
        appliedAt: json['appliedAt'] != null 
          ? DateTime.parse(json['appliedAt']) 
          : (json['createdAt'] != null 
              ? DateTime.parse(json['createdAt']) 
              : DateTime.now()),
        completionDetails: json['completionDetails'] != null
          ? (() {
              print('Parsing completion details: ${json['completionDetails']}');
              return CompletionDetails.fromJson(json['completionDetails']);
            })()
          : null,
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
      'completionDetails': completionDetails?.toJson(),
    };
  }
}
