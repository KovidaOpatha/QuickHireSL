class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? profileImage;
  final String? bio;
  final List<String>? skills;
  final String? location;
  final String? phoneNumber;
  final int? rating;
  final int? completedJobs;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profileImage,
    this.bio,
    this.skills,
    this.location,
    this.phoneNumber,
    this.rating,
    this.completedJobs,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      if (json.isEmpty) {
        return User(
          id: '',
          name: '',
          email: '',
          role: '',
          profileImage: '',
          bio: '',
          skills: null,
          location: '',
          phoneNumber: '',
          rating: 0,
          completedJobs: 0,
        );
      }

      // Parse rating and completedJobs safely
      int? parseRating() {
        if (json['rating'] == null) return 0;
        if (json['rating'] is int) return json['rating'];
        if (json['rating'] is double) return json['rating'].round();
        try {
          return int.parse(json['rating'].toString());
        } catch (e) {
          return 0;
        }
      }

      int? parseCompletedJobs() {
        if (json['completedJobs'] == null) return 0;
        if (json['completedJobs'] is int) return json['completedJobs'];
        if (json['completedJobs'] is double)
          return json['completedJobs'].round();
        try {
          return int.parse(json['completedJobs'].toString());
        } catch (e) {
          return 0;
        }
      }

      return User(
        id: json['_id'] ?? json['id'] ?? '',
        name: _constructName(json),
        email: json['email'] ?? '',
        role: json['role'] ?? 'user',
        profileImage: json['profileImage'] ?? '',
        bio: json['bio'] ?? '',
        skills:
            json['skills'] != null ? List<String>.from(json['skills']) : null,
        location: json['location'] ?? '',
        phoneNumber: json['phoneNumber'] ?? '',
        rating: parseRating(),
        completedJobs: parseCompletedJobs(),
      );
    } catch (e) {
      print('Error parsing user: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  static String _constructName(Map<String, dynamic> json) {
    // First try to get the name directly
    if (json['name'] != null && json['name'].toString().isNotEmpty) {
      return json['name'].toString();
    }

    // If no direct name, try to construct from firstName and lastName
    String firstName = json['firstName']?.toString() ?? '';
    String lastName = json['lastName']?.toString() ?? '';

    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }

    // If still no name, try email as fallback
    if (json['email'] != null && json['email'].toString().isNotEmpty) {
      return json['email']
          .toString()
          .split('@')[0]; // Use part before @ as name
    }

    // Last resort, use ID if available
    if (json['_id'] != null || json['id'] != null) {
      return 'User ${json['_id'] ?? json['id']}';
    }

    return 'Anonymous User';
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'role': role,
      'profileImage': profileImage,
      'bio': bio,
      'skills': skills,
      'location': location,
      'phoneNumber': phoneNumber,
      'rating': rating,
      'completedJobs': completedJobs,
    };
  }
}
