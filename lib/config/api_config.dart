// lib/config/api_config.dart - добавить новые эндпоинты

import 'dart:io';

class ApiConfig {
  // Базовый URL API сервера
  static String get baseUrl {
    // Определяем URL в зависимости от платформы
    if (Platform.isAndroid) {
      // Для Android эмулятора используем специальный адрес
      return 'http://10.0.2.2:5001';
    } else if (Platform.isIOS || Platform.isMacOS) {
      // Для iOS симулятора и macOS можно использовать localhost
      return 'http://localhost:5001';
    } else {
      // Для других платформ используем localhost
      return 'http://localhost:5001';
    }
  }

  // API endpoints
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

  // Динамические endpoints
  static String courseById(String courseId) => '$baseUrl/api/courses/$courseId';
  static String reportByCourse(String courseId) =>
      '$baseUrl/api/report/$courseId';
  static String medicationByCourse(String courseId) =>
      '$baseUrl/api/courses/$courseId/medications';
  static String updateMedication(String courseId, String medId) =>
      '$baseUrl/api/courses/$courseId/medications/$medId';

  // Таймауты для запросов
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Headers по умолчанию
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json; charset=UTF-8',
  };

  // Функция для получения заголовков с токеном
  static Map<String, String> getAuthHeaders(String token) {
    return {...defaultHeaders, 'Authorization': 'Bearer $token'};
  }
}
