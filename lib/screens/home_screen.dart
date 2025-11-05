// lib/screens/home_screen.dart - использовать ApiConfig

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:medichelp/config/api_config.dart';
import 'dart:convert';

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  String _userName = "...";
  bool _isLoadingPlan = true;
  bool _isLoadingCourse = true;
  bool _isLoadingInsight = true;
  final _storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> _medications = [];

  // Данные прогресса курса
  String _courseName = "";
  int _daysPassed = 0;
  int _totalDays = 0;
  double _progress = 0.0;

  // Инсайды дня
  String _healthFactText = "Загрузка факта...";
  String _motivationText = "";
  bool _hasEntryToday = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadUserName();
    await _loadTodayPlan();
    await _loadCourseProgress();
    await _loadDailyInsight();
  }

  Future<void> _loadUserName() async {
    final name = await _storage.read(key: 'user_name');
    if (mounted) {
      setState(() {
        _userName = name ?? "Пользователь";
      });
    }
  }

  Future<void> _loadTodayPlan() async {
    if (mounted) {
      setState(() {
        _isLoadingPlan = true;
      });
    }

    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.entriesToday),
        headers: ApiConfig.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> medsJson = json.decode(response.body);
        if (mounted) {
          setState(() {
            _medications = medsJson.map((json) {
              return {
                'name': json['name'] ?? 'Без имени',
                'time': json['time'] ?? '00:00',
                'taken': json['taken'] ?? false,
              };
            }).toList();
            _isLoadingPlan = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _medications = [];
            _isLoadingPlan = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPlan = false;
          _medications = [];
        });
      }
    }
  }

  Future<void> _loadCourseProgress() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    setState(() {
      _isLoadingCourse = true;
    });

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.courses),
        headers: ApiConfig.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> courses = json.decode(response.body);

        if (courses.isEmpty) {
          setState(() {
            _courseName = "Нет активных курсов";
            _isLoadingCourse = false;
          });
          return;
        }

        // Берем первый курс
        final course = courses[0];
        final startDate = DateTime.parse(course['startDate']);
        final endDate = course['endDate'] != null
            ? DateTime.parse(course['endDate'])
            : DateTime.now().add(
                const Duration(days: 30),
              ); // Если нет endDate, берем +30 дней

        final now = DateTime.now();
        final totalDays = endDate.difference(startDate).inDays;
        final daysPassed = now.difference(startDate).inDays.clamp(0, totalDays);
        final progress = totalDays > 0 ? daysPassed / totalDays : 0.0;

        setState(() {
          _courseName = course['name'] ?? 'Курс';
          _totalDays = totalDays;
          _daysPassed = daysPassed;
          _progress = progress.clamp(0.0, 1.0);
          _isLoadingCourse = false;
        });
      } else {
        setState(() {
          _courseName = "Ошибка загрузки";
          _isLoadingCourse = false;
        });
      }
    } catch (e) {
      setState(() {
        _courseName = "Ошибка соединения";
        _isLoadingCourse = false;
      });
    }
  }

  Future<void> _loadDailyInsight() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    setState(() {
      _isLoadingInsight = true;
    });

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.insightToday),
        headers: ApiConfig.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        String healthFact = "Нет факта на сегодня";
        String motivation = "Добавьте запись о приеме лекарств, чтобы получить мотивацию.";
        bool hasEntryToday = false;

        if (data is Map<String, dynamic>) {
          healthFact = data['healthFact'] ?? healthFact;
          motivation = data['motivation'] ?? motivation;
          hasEntryToday = data['hasEntryToday'] is bool
              ? data['hasEntryToday'] as bool
              : hasEntryToday;
        }

        setState(() {
          _healthFactText = healthFact;
          _motivationText = motivation;
          _hasEntryToday = hasEntryToday;
          _isLoadingInsight = false;
        });
      } else {
        setState(() {
          _healthFactText = 'Не удалось загрузить подсказки';
          _motivationText = 'Попробуйте обновить страницу позже.';
          _hasEntryToday = false;
          _isLoadingInsight = false;
        });
      }
    } catch (e) {
      setState(() {
        _healthFactText = 'Ошибка загрузки данных';
        _motivationText = 'Проверьте подключение к сети и повторите попытку.';
        _hasEntryToday = false;
        _isLoadingInsight = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPlanCard(),
                  const SizedBox(height: 20),
                  _buildCourseProgressCard(),
                  const SizedBox(height: 20),
                  _buildInsightsCard(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 24, right: 24, bottom: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF15A4C4), Color(0xFF33D4A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Добро пожаловать, $_userName!',
            style: GoogleFonts.lato(
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ваш план на сегодня',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _isLoadingPlan
                ? const Center(child: CircularProgressIndicator())
                : _medications.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'План на сегодня пуст.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: _medications
                        .map((med) => _buildMedicationTile(med))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationTile(Map<String, dynamic> medication) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: medication['taken'],
        onChanged: (bool? value) {
          setState(() {
            medication['taken'] = value!;
          });
        },
        activeColor: const Color(0xFF007BFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      title: Text(medication['name'], style: GoogleFonts.lato()),
      trailing: Text(
        medication['time'],
        style: GoogleFonts.lato(color: Colors.grey),
      ),
    );
  }

  Widget _buildCourseProgressCard() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Color(0xFF33D4A3)),
                const SizedBox(width: 8),
                Text(
                  'Прогресс курса',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _isLoadingCourse
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Курс: $_courseName',
                        style: GoogleFonts.lato(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 12,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF33D4A3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'День $_daysPassed из $_totalDays',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: Color(0xFF007BFF),
            size: 30,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Компас здоровья',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                if (_isLoadingInsight)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else ...[
                  Text(
                    'Интересный факт',
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: const Color(0xFF007BFF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _healthFactText,
                    style: GoogleFonts.lato(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Мотивация на сегодня',
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: const Color(0xFF007BFF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _motivationText,
                    style: GoogleFonts.lato(),
                  ),
                  if (!_hasEntryToday) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Добавьте сегодняшнюю запись, чтобы получить персональные рекомендации.',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
