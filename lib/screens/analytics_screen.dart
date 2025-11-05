

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:medichelp/services/api_service.dart';
import 'package:medichelp/models/course_model.dart';

class AnalyticsScreenContent extends StatefulWidget {
  const AnalyticsScreenContent({super.key});

  @override
  State<AnalyticsScreenContent> createState() => _AnalyticsScreenContentState();
}

class _AnalyticsScreenContentState extends State<AnalyticsScreenContent> {
  final List<bool> _isSelected = [true, false, false];

  bool _isLoading = true;
  bool _isLoadingEntries = true;
  String _aiInsights = "Загрузка выводов...";
  List<HealthEntry> _entries = [];
  List<FlSpot> _chartSpots = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_fetchAnalytics(), _fetchEntries()]);
  }

  Future<void> _fetchAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await ApiService.getAnalytics();
      setState(() {
        _aiInsights = data['insights'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _aiInsights = "Ошибка загрузки: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchEntries() async {
    setState(() {
      _isLoadingEntries = true;
    });

    try {
      final entriesJson = await ApiService.getEntries();


      final now = DateTime.now();
      final daysToShow = _getDaysToShow();
      final cutoffDate = now.subtract(Duration(days: daysToShow));

      final recentEntries = entriesJson.where((entry) {
        final entryDate = DateTime.parse(entry['entryDate']);
        return entryDate.isAfter(cutoffDate);
      }).toList();


      recentEntries.sort((a, b) {
        final dateA = DateTime.parse(a['entryDate']);
        final dateB = DateTime.parse(b['entryDate']);
        return dateA.compareTo(dateB);
      });


      final spots = <FlSpot>[];
      final entries = <HealthEntry>[];

      for (int i = 0; i < recentEntries.length; i++) {
        final entry = HealthEntry.fromJson(recentEntries[i]);
        entries.add(entry);
        spots.add(FlSpot(i.toDouble(), entry.headacheLevel.toDouble()));
      }

      setState(() {
        _entries = entries;
        _chartSpots = spots;
        _isLoadingEntries = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingEntries = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки записей: $e')));
      }
    }
  }

  int _getDaysToShow() {
    if (_isSelected[0]) return 7;
    if (_isSelected[1]) return 30;
    return 365;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Аналитика и выводы',
          style: GoogleFonts.lato(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color(0xFFF4F6F8),
        elevation: 0,
        toolbarHeight: 80,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _buildTimeToggles(),
            const SizedBox(height: 20),
            _buildChartCard(),
            const SizedBox(height: 20),
            _buildInsightsHeader(),
            _buildAInsightsCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeToggles() {
    return Center(
      child: ToggleButtons(
        isSelected: _isSelected,
        onPressed: (int index) {
          setState(() {
            for (int i = 0; i < _isSelected.length; i++) {
              _isSelected[i] = i == index;
            }
          });
          _fetchEntries();
        },
        borderRadius: BorderRadius.circular(8.0),
        selectedColor: Colors.white,
        color: const Color(0xFF007BFF),
        fillColor: const Color(0xFF007BFF),
        constraints: const BoxConstraints(minHeight: 40.0),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Неделя',
              style: GoogleFonts.lato(fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Месяц',
              style: GoogleFonts.lato(fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Все время',
              style: GoogleFonts.lato(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
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
              'Головная боль',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.circle, color: const Color(0xFF007BFF), size: 12),
                const SizedBox(width: 4),
                Text(
                  'Синий круг - прием лекарств',
                  style: GoogleFonts.lato(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 150,
              child: _isLoadingEntries
                  ? const Center(child: CircularProgressIndicator())
                  : _chartSpots.isEmpty
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
                            'Нет данных для отображения',
                            style: GoogleFonts.lato(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : LineChart(_buildAnalyticsChartData()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0),
      child: Text(
        'Ключевые выводы от ИИ',
        style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAInsightsCard() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.purple.shade100,
              child: Icon(
                Icons.lightbulb_outline,
                color: Colors.purple.shade800,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Text(
                      _aiInsights,
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildAnalyticsChartData() {
    if (_chartSpots.isEmpty) {
      return LineChartData();
    }

    final maxX = _chartSpots.length - 1.0;
    final minX = 0.0;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 3,
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
            interval: 3,
            reservedSize: 28,
            getTitlesWidget: _leftTitleWidgets,
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: _chartSpots.length > 5 ? 2 : 1,
            reservedSize: 32,
            getTitlesWidget: _bottomTitleWidgets,
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: minX,
      maxX: maxX,
      minY: 0,
      maxY: 10,
      lineBarsData: [
        LineChartBarData(
          spots: _chartSpots,
          isCurved: true,
          color: const Color(0xFF007BFF),
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {

              if (index < _entries.length) {
                final hasMedication = _entries[index].medicationsTaken.any(
                  (m) => m.status == 'taken',
                );

                if (hasMedication) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: const Color(0xFF007BFF),
                  );
                }
              }
              return FlDotCirclePainter(
                radius: 4,
                color: const Color(0xFF007BFF),
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: const Color(0xFF007BFF).withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    if (value == 0 || value == 10) return Container();
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Text(
        value.toInt().toString(),
        style: GoogleFonts.lato(color: Colors.grey.shade600, fontSize: 12),
      ),
    );
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= _entries.length) return Container();

    final date = _entries[index].entryDate;
    final dateStr = '${date.day} ${_getMonthName(date.month)}';

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Text(
        dateStr,
        style: GoogleFonts.lato(
          color: Colors.grey.shade600,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'янв',
      'фев',
      'мар',
      'апр',
      'май',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек',
    ];
    return months[month - 1];
  }
}
