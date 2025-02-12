class Job {
  final String? id;
  final String title;
  final String company;
  final String location;
  final String description;
  final List<String> requirements;
  final Map<String, dynamic> salary;
  final String employmentType;
  final String experienceLevel;
  final String? postedBy;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Job({
    this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.description,
    required this.requirements,
    required this.salary,
    required this.employmentType,
    required this.experienceLevel,
    this.postedBy,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    try {
      return Job(
        // Handle both '_id' and 'id' cases
        id: json['_id']?.toString() ?? json['id']?.toString(),
        title: json['title'] as String,
        company: json['company'] as String,
        location: json['location'] as String,
        description: json['description'] as String,
        requirements: (json['requirements'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        salary: Map<String, dynamic>.from(json['salary'] ?? {
          'min': 0,
          'max': 0,
          'currency': 'LKR'
        }),
        employmentType: json['employmentType'] as String,
        experienceLevel: json['experienceLevel'] as String,
        postedBy: json['postedBy'] is Map
            ? json['postedBy']['_id']?.toString()
            : json['postedBy']?.toString(),
        status: json['status'] as String? ?? 'active',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'].toString())
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'].toString())
            : null,
      );
    } catch (e) {
      print('Error parsing Job from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'title': title,
      'company': company,
      'location': location,
      'description': description,
      'requirements': requirements,
      'salary': salary,
      'employmentType': employmentType,
      'experienceLevel': experienceLevel,
      if (postedBy != null) 'postedBy': postedBy,
      'status': status,
    };
  }

  @override
  String toString() {
    return 'Job{id: $id, title: $title, company: $company, location: $location, '
        'employmentType: $employmentType, experienceLevel: $experienceLevel}';
  }
}
