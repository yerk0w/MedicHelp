

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:medichelp/services/api_service.dart';
import 'package:medichelp/models/course_model.dart';

class ReportScreenContent extends StatefulWidget {
  const ReportScreenContent({super.key});

  @override
  State<ReportScreenContent> createState() => _ReportScreenContentState();
}

class _ReportScreenContentState extends State<ReportScreenContent> {
  List<Course> _courses = [];
  bool _isLoadingCourses = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoadingCourses = true;
    });

    try {
      final coursesJson = await ApiService.getCourses();
      setState(() {
        _courses = coursesJson.map((c) => Course.fromJson(c)).toList();
        _isLoadingCourses = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCourses = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки курсов: $e')));
      }
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
      body: RefreshIndicator(
        onRefresh: _loadCourses,
        child: _isLoadingCourses
            ? const Center(child: CircularProgressIndicator())
            : _courses.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Нет курсов для отчетов',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Создайте курс лечения в профиле',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
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
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _openCourseReport(course.id, course.name),
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
                  Icons.analytics_outlined,
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
                      course.name,
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Симптом: ${course.mainSymptom}',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${DateFormat('dd.MM.yyyy').format(course.startDate)} - ${course.endDate != null ? DateFormat('dd.MM.yyyy').format(course.endDate!) : "активен"}',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


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
  bool _isLoading = true;
  Map<String, dynamic>? _reportData;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await ApiService.getReportByCourse(widget.courseId);
      setState(() {
        _reportData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки отчета: $e';
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReport,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(fontSize: 16, color: Colors.red),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadReport,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Попробовать снова'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007BFF),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadReport,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildComplianceCard(),
                  const SizedBox(height: 24),
                  _buildDynamicsSection(),
                  const SizedBox(height: 24),
                  _buildAIInsightsSection(),
                  const SizedBox(height: 24),
                  _buildMedicationsTable(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    final totalEntries = _reportData?['statistics']?['totalEntries'] ?? 0;
    final compliance = _reportData?['statistics']?['compliancePercent'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildMiniCard(
            'Записей',
            totalEntries.toString(),
            Icons.edit_note,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniCard(
            'Соблюдение',
            '$compliance%',
            Icons.check_circle_outline,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
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
            Row(
              children: [
                Icon(
                  Icons.medication,
                  color: const Color(0xFF007BFF),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Соблюдение режима',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
                    color: compliance >= 80
                        ? Colors.green
                        : compliance >= 60
                        ? Colors.orange
                        : Colors.red,
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
                valueColor: AlwaysStoppedAnimation<Color>(
                  compliance >= 80
                      ? Colors.green
                      : compliance >= 60
                      ? Colors.orange
                      : Colors.red,
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
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: const Color(0xFF007BFF),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Динамика симптома',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Недостаточно данных',
                            style: GoogleFonts.lato(color: Colors.grey),
                          ),
                        ],
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
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 2,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
            dashArray: [5, 5],
          );
        },
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 2,
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
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: const Color(0xFF007BFF).withOpacity(0.1),
          ),
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

      if (correlations.isNotEmpty) {
        insightsText = 'Корреляции:\n';
        for (var corr in correlations) {
          insightsText += '• $corr\n';
        }
      }
      if (recommendations.isNotEmpty) {
        if (insightsText.isNotEmpty) insightsText += '\n';
        insightsText += 'Рекомендации:\n$recommendations';
      }
    } else if (aiSummary is String) {
      insightsText = aiSummary;
    }

    if (insightsText.isEmpty) {
      insightsText = 'Анализ недоступен. Добавьте больше записей.';
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
                Icon(
                  Icons.psychology_outlined,
                  color: Colors.purple.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Анализ от ИИ',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                insightsText,
                style: GoogleFonts.lato(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.black87,
                ),
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
            Row(
              children: [
                Icon(
                  Icons.medication_liquid,
                  color: const Color(0xFF007BFF),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Препараты курса',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...medications.map((med) {
              final schedule = (med['schedule'] as List).join(', ');
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007BFF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.medication,
                          color: Color(0xFF007BFF),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med['name'],
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              med['dosage'],
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              schedule,
                              style: GoogleFonts.lato(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
