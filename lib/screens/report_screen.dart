import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:medichelp/screens/entry_form_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReportScreenContent extends StatefulWidget {
  const ReportScreenContent({super.key});

  @override
  State<ReportScreenContent> createState() => _ReportScreenContentState();
}

class _ReportScreenContentState extends State<ReportScreenContent> {
  int _selectedIndex = 3;
  final _storage = const FlutterSecureStorage();

  List<Map<String, dynamic>> _courses = [];
  bool _isLoadingCourses = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    setState(() {
      _isLoadingCourses = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5001/api/courses'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _courses = data
              .map(
                (c) => {
                  'id': c['_id'],
                  'name': c['name'],
                  'mainSymptom': c['mainSymptom'],
                  'startDate': c['startDate'],
                  'endDate': c['endDate'],
                },
              )
              .toList();
          _isLoadingCourses = false;
        });
      } else {
        setState(() {
          _isLoadingCourses = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingCourses = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка загрузки курсов: $e')));
    }
  }

  void _openCourseReport(String courseId, String courseName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseReportDetailScreen(
          courseId: courseId,
          courseName: courseName,
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EntryFormScreen()),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/analytics');
        break;
      case 3:
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Отчеты по курсам',
          style: GoogleFonts.lato(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color(0xFFF4F6F8),
        elevation: 0,
      ),
      body: _isLoadingCourses
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Нет доступных курсов.\nСоздайте курс, чтобы увидеть отчет.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _courses.length,
              itemBuilder: (context, index) {
                final course = _courses[index];
                return _buildCourseCard(course);
              },
            ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final startDate = DateTime.parse(course['startDate']);
    final endDate = course['endDate'] != null
        ? DateTime.parse(course['endDate'])
        : null;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _openCourseReport(course['id'], course['name']),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF007BFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medical_services,
                  color: Color(0xFF007BFF),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['name'],
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Симптом: ${course['mainSymptom']}',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Период: ${DateFormat('dd.MM.yyyy').format(startDate)} - ${endDate != null ? DateFormat('dd.MM.yyyy').format(endDate) : "активен"}',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// Экран детального отчета по курсу
class CourseReportDetailScreen extends StatefulWidget {
  final String courseId;
  final String courseName;

  const CourseReportDetailScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<CourseReportDetailScreen> createState() =>
      _CourseReportDetailScreenState();
}

class _CourseReportDetailScreenState extends State<CourseReportDetailScreen> {
  final _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  Map<String, dynamic>? _reportData;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5001/api/report/${widget.courseId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _reportData = data;
          _isLoading = false;
        });
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          _errorMessage = errorData['message'] ?? 'Ошибка загрузки отчета';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка подключения: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Отчет: ${widget.courseName}',
          style: GoogleFonts.lato(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(fontSize: 16, color: Colors.red),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildComplianceCard(),
                const SizedBox(height: 24),
                _buildDynamicsSection(),
                const SizedBox(height: 24),
                _buildAIInsightsSection(),
                const SizedBox(height: 24),
                _buildMedicationsTable(),
              ],
            ),
    );
  }

  Widget _buildComplianceCard() {
    final compliance = _reportData?['statistics']?['compliancePercent'] ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Соблюдение режима',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Прием лекарств', style: GoogleFonts.lato(fontSize: 16)),
                Text(
                  '$compliance% вовремя',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF007BFF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: compliance / 100,
                minHeight: 12,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF007BFF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicsSection() {
    final symptomLevels =
        _reportData?['statistics']?['symptomLevels'] as List? ?? [];
    final courseName = _reportData?['course']?['mainSymptom'] ?? 'Симптом';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Динамика основного симптома',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              courseName,
              style: GoogleFonts.lato(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: symptomLevels.isEmpty
                  ? Center(
                      child: Text(
                        'Недостаточно данных',
                        style: GoogleFonts.lato(color: Colors.grey),
                      ),
                    )
                  : LineChart(_buildSymptomChart(symptomLevels)),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildSymptomChart(List<dynamic> symptomLevels) {
    final spots = <FlSpot>[];
    for (int i = 0; i < symptomLevels.length; i++) {
      final level = symptomLevels[i]['level'] ?? 0;
      spots.add(FlSpot(i.toDouble(), level.toDouble()));
    }

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 3,
            reservedSize: 28,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: GoogleFonts.lato(color: Colors.grey, fontSize: 12),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: symptomLevels.length > 5 ? 2 : 1,
            reservedSize: 32,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < symptomLevels.length) {
                final date = symptomLevels[index]['date'] ?? '';
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(
                    date,
                    style: GoogleFonts.lato(color: Colors.grey, fontSize: 10),
                  ),
                );
              }
              return Container();
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade300),
      ),
      minY: 0,
      maxY: 10,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: const Color(0xFF007BFF),
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: false),
        ),
      ],
    );
  }

  Widget _buildAIInsightsSection() {
    final aiSummary = _reportData?['aiSummary'];
    String insightsText = '';

    if (aiSummary is Map) {
      final correlations = aiSummary['correlations'] as List? ?? [];
      final recommendations = aiSummary['recommendations'] ?? '';

      insightsText = 'Корреляции:\n';
      for (var corr in correlations) {
        insightsText += '• $corr\n';
      }
      if (recommendations.isNotEmpty) {
        insightsText += '\nРекомендации:\n$recommendations';
      }
    } else if (aiSummary is String) {
      insightsText = aiSummary;
    } else {
      insightsText = 'Анализ недоступен';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Color(0xFF007BFF)),
                const SizedBox(width: 8),
                Text(
                  'Выводы ИИ-Аналитика',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              insightsText,
              style: GoogleFonts.lato(
                fontSize: 15,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationsTable() {
    final medications =
        _reportData?['statistics']?['medicationsList'] as List? ?? [];

    if (medications.isEmpty) {
      return Container();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Список принимаемых препаратов',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  children: [
                    _buildTableHeader('Препарат'),
                    _buildTableHeader('Дозировка'),
                    _buildTableHeader('Частота'),
                  ],
                ),
                ...medications.map((med) {
                  final schedule = (med['schedule'] as List).join(', ');
                  return _buildTableRow(med['name'], med['dosage'], schedule);
                }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        text,
        style: GoogleFonts.lato(
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  TableRow _buildTableRow(String name, String dosage, String schedule) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(name, style: GoogleFonts.lato(fontSize: 15)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(dosage, style: GoogleFonts.lato(fontSize: 15)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(schedule, style: GoogleFonts.lato(fontSize: 15)),
        ),
      ],
    );
  }
}
