

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:medichelp/config/api_config.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();


  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }


  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }


  static Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_name');
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'user_role');
    await _storage.delete(key: 'user_id');
  }


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


  static Map<String, dynamic> handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Ошибка сервера');
    }
  }


  static Future<List<dynamic>> getCourses({String? patientId}) async {
    final String url = patientId != null && patientId.isNotEmpty
        ? ApiConfig.coursesForPatient(patientId)
        : ApiConfig.courses;
    final response = await get(url);
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
    Map<String, dynamic> courseData, {
    String? patientId,
  }) async {
    final payload = Map<String, dynamic>.from(courseData);
    if (patientId != null && patientId.isNotEmpty) {
      payload['patientId'] = patientId;
    }
    final response = await post(ApiConfig.courses, payload);
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


  static Future<Map<String, dynamic>> getAnalytics() async {
    final response = await get(ApiConfig.analytics);
    return handleResponse(response);
  }

  static Future<Map<String, dynamic>> getInsightToday() async {
    final response = await get(ApiConfig.insightToday);
    return handleResponse(response);
  }

  static Future<List<dynamic>> getDoctorPatients() async {
    final response = await get(ApiConfig.patients);
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

  static Future<Map<String, dynamic>> getPatientProfileById(
    String patientId,
  ) async {
    final response = await get(ApiConfig.patientById(patientId));
    return handleResponse(response);
  }

  static Future<Map<String, dynamic>> createPatient(
    Map<String, dynamic> patientData,
  ) async {
    final response = await post(ApiConfig.patients, patientData);
    return handleResponse(response);
  }


  static Future<Map<String, dynamic>> getReportByCourse(String courseId) async {
    final response = await get(ApiConfig.reportByCourse(courseId));
    return handleResponse(response);
  }


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

  static Future<Map<String, dynamic>> getChatMessages({
    String? patientId,
  }) async {
    final uri = patientId != null && patientId.isNotEmpty
        ? '${ApiConfig.chat}?patientId=$patientId'
        : ApiConfig.chat;
    final response = await get(uri);
    return handleResponse(response);
  }

  static Future<Map<String, dynamic>> sendChatMessage(
    String message, {
    String? patientId,
  }) async {
    final payload = <String, dynamic>{'message': message};
    if (patientId != null && patientId.isNotEmpty) {
      payload['patientId'] = patientId;
    }
    final response = await post(ApiConfig.chat, payload);
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
