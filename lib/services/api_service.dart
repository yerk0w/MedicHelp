// lib/services/api_service.dart - создать сервисный слой для API запросов

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:medichelp/config/api_config.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();

  // Получить токен
  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // Сохранить токен
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  // Удалить токен
  static Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  // GET запрос
  static Future<http.Response> get(String url) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Токен не найден');
    }

    return await http.get(
      Uri.parse(url),
      headers: ApiConfig.getAuthHeaders(token),
    );
  }

  // POST запрос
  static Future<http.Response> post(
    String url,
    Map<String, dynamic> body,
  ) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Токен не найден');
    }

    return await http.post(
      Uri.parse(url),
      headers: ApiConfig.getAuthHeaders(token),
      body: json.encode(body),
    );
  }

  // POST запрос без авторизации
  static Future<http.Response> postPublic(
    String url,
    Map<String, dynamic> body,
  ) async {
    return await http.post(
      Uri.parse(url),
      headers: ApiConfig.defaultHeaders,
      body: json.encode(body),
    );
  }

  // PUT запрос
  static Future<http.Response> put(
    String url,
    Map<String, dynamic> body,
  ) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Токен не найден');
    }

    return await http.put(
      Uri.parse(url),
      headers: ApiConfig.getAuthHeaders(token),
      body: json.encode(body),
    );
  }

  // DELETE запрос
  static Future<http.Response> delete(String url) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Токен не найден');
    }

    return await http.delete(
      Uri.parse(url),
      headers: ApiConfig.getAuthHeaders(token),
    );
  }

  // Универсальный обработчик ответов
  static Map<String, dynamic> handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Ошибка сервера');
    }
  }

  // API методы для курсов
  static Future<List<dynamic>> getCourses() async {
    final response = await get(ApiConfig.courses);
    final body = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is List) {
        return body;
      }
      return [];
    } else {
      throw Exception(body['message'] ?? 'Ошибка сервера');
    }
  }

  static Future<Map<String, dynamic>> getCourseById(String courseId) async {
    final response = await get(ApiConfig.courseById(courseId));
    return handleResponse(response);
  }

  static Future<Map<String, dynamic>> createCourse(
    Map<String, dynamic> courseData,
  ) async {
    final response = await post(ApiConfig.courses, courseData);
    return handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateCourse(
    String courseId,
    Map<String, dynamic> courseData,
  ) async {
    final response = await put(ApiConfig.courseById(courseId), courseData);
    return handleResponse(response);
  }

  static Future<void> deleteCourse(String courseId) async {
    final response = await delete(ApiConfig.courseById(courseId));
    handleResponse(response);
  }

  // API методы для записей
  static Future<List<dynamic>> getEntries() async {
    final response = await get(ApiConfig.entries);
    final body = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is List) {
        return body;
      }
      return [];
    } else {
      throw Exception(body['message'] ?? 'Ошибка сервера');
    }
  }

  static Future<Map<String, dynamic>> createEntry(
    Map<String, dynamic> entryData,
  ) async {
    final response = await post(ApiConfig.entries, entryData);
    return handleResponse(response);
  }

  // API методы для профиля
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await get(ApiConfig.profile);
    return handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> profileData,
  ) async {
    final response = await put(ApiConfig.profile, profileData);
    return handleResponse(response);
  }

  // API методы для аналитики
  static Future<Map<String, dynamic>> getAnalytics() async {
    final response = await get(ApiConfig.analytics);
    return handleResponse(response);
  }

  static Future<Map<String, dynamic>> getInsightToday() async {
    final response = await get(ApiConfig.insightToday);
    return handleResponse(response);
  }

  // API методы для отчетов
  static Future<Map<String, dynamic>> getReportByCourse(String courseId) async {
    final response = await get(ApiConfig.reportByCourse(courseId));
    return handleResponse(response);
  }

  // API методы для медикаментов
  static Future<Map<String, dynamic>> addMedication(
    String courseId,
    Map<String, dynamic> medicationData,
  ) async {
    final response = await post(
      ApiConfig.medicationByCourse(courseId),
      medicationData,
    );
    return handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateMedication(
    String courseId,
    String medId,
    Map<String, dynamic> medicationData,
  ) async {
    final response = await put(
      ApiConfig.updateMedication(courseId, medId),
      medicationData,
    );
    return handleResponse(response);
  }

  static Future<void> deleteMedication(String courseId, String medId) async {
    final response = await delete(ApiConfig.updateMedication(courseId, medId));
    handleResponse(response);
  }
}
