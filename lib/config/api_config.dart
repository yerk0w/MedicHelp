

import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {

  static String get baseUrl {

    if (kIsWeb) {
      return 'http://localhost:5001';
    }






    if (kIsWeb) {
      return 'http://localhost:5001';
    }

    return 'http://localhost:5001';
  }


  static String get register => '$baseUrl/api/register';
  static String get login => '$baseUrl/api/login';
  static String get forgotPassword => '$baseUrl/api/forgot-password';
  static String get resetPassword => '$baseUrl/api/reset-password';
  static String get entries => '$baseUrl/api/entries';
  static String get entriesToday => '$baseUrl/api/entries/today';
  static String get profile => '$baseUrl/api/profile';
  static String get analytics => '$baseUrl/api/analytics';
  static String get courses => '$baseUrl/api/courses';
  static String get insightToday => '$baseUrl/api/insight/today';
  static String get patients => '$baseUrl/api/patients';


  static String courseById(String courseId) => '$baseUrl/api/courses/$courseId';
  static String reportByCourse(String courseId) =>
      '$baseUrl/api/report/$courseId';
  static String medicationByCourse(String courseId) =>
      '$baseUrl/api/courses/$courseId/medications';
  static String updateMedication(String courseId, String medId) =>
      '$baseUrl/api/courses/$courseId/medications/$medId';


  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);


  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json; charset=UTF-8',
  };


  static Map<String, String> getAuthHeaders(String token) {
    return {...defaultHeaders, 'Authorization': 'Bearer $token'};
  }
}
