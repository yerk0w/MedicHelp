class PatientSummary {
  final String id;
  final String name;
  final String email;
  final DateTime? lastEntryDate;
  final int totalCourses;
  final int activeCourses;

  PatientSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.lastEntryDate,
    required this.totalCourses,
    required this.activeCourses,
  });

  factory PatientSummary.fromJson(Map<String, dynamic> json) {
    return PatientSummary(
      id: json['id'] ?? json['_id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      lastEntryDate: json['lastEntryDate'] != null
          ? DateTime.parse(json['lastEntryDate'])
          : null,
      totalCourses: json['totalCourses'] ?? 0,
      activeCourses: json['activeCourses'] ?? 0,
    );
  }
}

class PatientProfile {
  final String id;
  final String name;
  final String email;
  final DateTime? registeredAt;
  final Map<String, dynamic> medicalCard;

  PatientProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.registeredAt,
    required this.medicalCard,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      id: json['id'] ?? json['_id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      registeredAt: json['registeredAt'] != null
          ? DateTime.parse(json['registeredAt'])
          : null,
      medicalCard: json['medicalCard'] is Map<String, dynamic>
          ? json['medicalCard'] as Map<String, dynamic>
          : <String, dynamic>{},
    );
  }
}
