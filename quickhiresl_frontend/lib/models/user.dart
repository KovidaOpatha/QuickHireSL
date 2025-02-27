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
        );
      }

      return User(
        id: json['_id'] ?? json['id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        role: json['role'] ?? 'user',
        profileImage: json['profileImage'] ?? '',
        bio: json['bio'] ?? '',
        skills: json['skills'] != null 
          ? List<String>.from(json['skills'])
          : null,
        location: json['location'] ?? '',
        phoneNumber: json['phoneNumber'] ?? '',
      );
    } catch (e) {
      print('Error parsing user: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'profileImage': profileImage,
      'bio': bio,
      'skills': skills,
      'location': location,
      'phoneNumber': phoneNumber,
    };
  }
}
