class Salary {
  final int min;
  final int max;
  final String currency;

  Salary({
    required this.min,
    required this.max,
    this.currency = 'LKR',
  });

  factory Salary.fromJson(Map<String, dynamic> json) {
    return Salary(
      min: json['min'] ?? 0,
      max: json['max'] ?? 0,
      currency: json['currency'] ?? 'LKR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
      'currency': currency,
    };
  }
}

class Job {
  final String? id;
  final String title;
  final String company;
  final String location;
  final String description;
  final List<String> requirements;
  final Salary salary;
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
      if (json.isEmpty) {
        return Job(
          id: '',
          title: '',
          company: '',
          location: '',
          description: '',
          requirements: [],
          salary: Salary(min: 0, max: 0),
          employmentType: '',
          experienceLevel: '',
          postedBy: '',
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      return Job(
        id: json['_id'] ?? json['id'] ?? '',
        title: json['title'] ?? '',
        company: json['company'] ?? '',
        location: json['location'] ?? '',
        description: json['description'] ?? '',
        requirements: List<String>.from(json['requirements'] ?? []),
        salary: Salary.fromJson(
            json['salary'] ?? {'min': 0, 'max': 0, 'currency': 'LKR'}),
        employmentType: json['employmentType'] ?? '',
        experienceLevel: json['experienceLevel'] ?? '',
        postedBy: json['postedBy'] is Map
            ? json['postedBy']['_id']?.toString()
            : json['postedBy']?.toString() ?? '',
        status: json['status'] ?? 'active',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : DateTime.now(),
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
      'salary': salary.toJson(),
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
