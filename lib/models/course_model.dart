

class Course {
  final String id;
  final String name;
  final String mainSymptom;
  final DateTime startDate;
  final DateTime? endDate;

  Course({
    required this.id,
    required this.name,
    required this.mainSymptom,
    required this.startDate,
    this.endDate,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      mainSymptom: json['mainSymptom'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mainSymptom': mainSymptom,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }
}

class Medication {
  final String id;
  final String name;
  final String dosage;
  final List<String> schedule;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.schedule,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      dosage: json['dosage'],
      schedule: List<String>.from(json['schedule']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'dosage': dosage, 'schedule': schedule};
  }
}

class HealthEntry {
  final String id;
  final DateTime entryDate;
  final String? courseId;
  final List<MedicationTaken> medicationsTaken;
  final List<String> symptoms;
  final List<String> symptomTags;
  final int headacheLevel;
  final List<String> lifestyleTags;
  final String notes;

  HealthEntry({
    required this.id,
    required this.entryDate,
    this.courseId,
    required this.medicationsTaken,
    required this.symptoms,
    required this.symptomTags,
    required this.headacheLevel,
    required this.lifestyleTags,
    required this.notes,
  });

  factory HealthEntry.fromJson(Map<String, dynamic> json) {
    return HealthEntry(
      id: json['_id'] ?? json['id'],
      entryDate: DateTime.parse(json['entryDate']),
      courseId: json['courseId'],
      medicationsTaken:
          (json['medicationsTaken'] as List?)
              ?.map((m) => MedicationTaken.fromJson(m))
              .toList() ??
          [],
      symptoms: List<String>.from(json['symptoms'] ?? []),
      symptomTags: List<String>.from(json['symptomTags'] ?? []),
      headacheLevel: json['headacheLevel'] ?? 0,
      lifestyleTags: List<String>.from(json['lifestyleTags'] ?? []),
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entryDate': entryDate.toIso8601String(),
      'courseId': courseId,
      'medicationsTaken': medicationsTaken.map((m) => m.toJson()).toList(),
      'symptoms': symptoms,
      'symptomTags': symptomTags,
      'headacheLevel': headacheLevel,
      'lifestyleTags': lifestyleTags,
      'notes': notes,
    };
  }
}

class MedicationTaken {
  final String medId;
  final String status;

  MedicationTaken({required this.medId, required this.status});

  factory MedicationTaken.fromJson(Map<String, dynamic> json) {
    return MedicationTaken(medId: json['medId'], status: json['status']);
  }

  Map<String, dynamic> toJson() {
    return {'medId': medId, 'status': status};
  }
}

class UserProfile {
  final String name;
  final String email;
  final MedicalCard medicalCard;

  UserProfile({
    required this.name,
    required this.email,
    required this.medicalCard,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'],
      email: json['email'],
      medicalCard: MedicalCard.fromJson(json['medicalCard'] ?? {}),
    );
  }
}

class MedicalCard {
  final String fullName;
  final String birthDate;
  final String bloodType;
  final String allergies;
  final String chronicDiseases;
  final String emergencyContact;
  final String insuranceNumber;
  final String additionalInfo;

  MedicalCard({
    required this.fullName,
    required this.birthDate,
    required this.bloodType,
    required this.allergies,
    required this.chronicDiseases,
    required this.emergencyContact,
    required this.insuranceNumber,
    required this.additionalInfo,
  });

  factory MedicalCard.fromJson(Map<String, dynamic> json) {
    return MedicalCard(
      fullName: json['fullName'] ?? '',
      birthDate: json['birthDate'] ?? '',
      bloodType: json['bloodType'] ?? '',
      allergies: json['allergies'] ?? '',
      chronicDiseases: json['chronicDiseases'] ?? '',
      emergencyContact: json['emergencyContact'] ?? '',
      insuranceNumber: json['insuranceNumber'] ?? '',
      additionalInfo: json['additionalInfo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'birthDate': birthDate,
      'bloodType': bloodType,
      'allergies': allergies,
      'chronicDiseases': chronicDiseases,
      'emergencyContact': emergencyContact,
      'insuranceNumber': insuranceNumber,
      'additionalInfo': additionalInfo,
    };
  }
}
