class Salary {
  final int value;
  final String currency;

  Salary({
    required this.value,
    this.currency = 'LKR',
  });

  factory Salary.fromJson(Map<String, dynamic> json) {
    // Handle both old format and new format
    if (json is int || json is double) {
      return Salary(
        value: (json as num).toInt(),
      );
    }
    
    if (json['min'] != null && json['max'] != null) {
      // For backward compatibility with old data format
      return Salary(
        value: json['min'] ?? 0,
        currency: json['currency'] ?? 'LKR',
      );
    }
    
    return Salary(
      value: json['value'] ?? 0,
      currency: json['currency'] ?? 'LKR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'currency': currency,
    };
  }
}

class TimeSlot {
  final String startTime;
  final String endTime;

  TimeSlot({
    required this.startTime,
    required this.endTime,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}

class AvailableDate {
  final DateTime date;
  final bool isFullDay;
  final List<TimeSlot> timeSlots;

  AvailableDate({
    required this.date,
    required this.isFullDay,
    required this.timeSlots,
  });

  factory AvailableDate.fromJson(Map<String, dynamic> json) {
    return AvailableDate(
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      isFullDay: json['isFullDay'] ?? false,
      timeSlots: (json['timeSlots'] as List<dynamic>?)
              ?.map((slot) => TimeSlot.fromJson(slot))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'isFullDay': isFullDay,
      'timeSlots': timeSlots.map((slot) => slot.toJson()).toList(),
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
  final String category;
  final List<AvailableDate> availableDates;

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
    this.category = '',
    this.availableDates = const [],
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
          salary: Salary(value: 0),
          employmentType: '',
          experienceLevel: '',
          postedBy: '',
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          category: '',
          availableDates: [],
        );
      }

      // Parse available dates if they exist
      List<AvailableDate> availableDates = [];
      if (json['availableDates'] != null) {
        availableDates = (json['availableDates'] as List<dynamic>)
            .map((dateData) => AvailableDate.fromJson(dateData))
            .toList();
      }

      // Handle salary - could be a number or an object
      Salary salary;
      if (json['salary'] is int || json['salary'] is double) {
        salary = Salary(value: (json['salary'] as num).toInt());
      } else {
        salary = Salary.fromJson(json['salary'] ?? {'value': 0, 'currency': 'LKR'});
      }

      return Job(
        id: json['_id'] ?? json['id'] ?? '',
        title: json['title'] ?? '',
        company: json['company'] ?? '',
        location: json['location'] ?? '',
        description: json['description'] ?? '',
        requirements: List<String>.from(json['requirements'] ?? []),
        salary: salary,
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
        category: json['category'] ?? '',
        availableDates: availableDates,
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
      'category': category,
      'availableDates': availableDates.map((date) => date.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'Job{id: $id, title: $title, company: $company, location: $location, '
        'employmentType: $employmentType, experienceLevel: $experienceLevel}';
  }
}
