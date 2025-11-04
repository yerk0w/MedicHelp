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
  
  // Таймауты для запросов
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Headers по умолчанию
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json; charset=UTF-8',
  };
  
  // Функция для получения заголовков с токеном
  static Map<String, String> getAuthHeaders(String token) {
    return {
      ...defaultHeaders,
      'Authorization': 'Bearer $token',
    };
  }
}