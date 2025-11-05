import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AnalyticsScreenContent extends StatefulWidget {
  const AnalyticsScreenContent({super.key});

  @override
  State<AnalyticsScreenContent> createState() => _AnalyticsScreenContentState();
}

class _AnalyticsScreenContentState extends State<AnalyticsScreenContent> {
  final List<bool> _isSelected = [true, false, false];
  final _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  String _aiInsights = "Загрузка выводов...";

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      setState(() {
        _isLoading = false;
        _aiInsights = "Ошибка авторизации. Пожалуйста, войдите заново.";
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5001/api/analytics'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _aiInsights = data['insights'];
          _isLoading = false;
        });
      } else {
        final data = json.decode(response.body);
        setState(() {
          _aiInsights = data['message'] ?? "Ошибка загрузки данных";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _aiInsights = "Ошибка подключения к серверу: $e";
        _isLoading = false;
      });
    }
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
      body: ListView(
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
                Icon(Icons.link, color: Colors.grey.shade600, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Прием лекарств отмечен значком',
                  style: GoogleFonts.lato(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(height: 150, child: LineChart(_buildAnalyticsChartData())),
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
    final List<FlSpot> spots = [
      const FlSpot(8, 7),
      const FlSpot(9, 6),
      const FlSpot(10, 3),
      const FlSpot(11, 4),
      const FlSpot(12, 6.5),
      const FlSpot(14, 3.5),
    ];

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
            interval: 1,
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
      minX: 8,
      maxX: 14,
      minY: 0,
      maxY: 10,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: const Color(0xFF007BFF),
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              if (spot.x == 9 || spot.x == 12) {
                return FlDotCirclePainter(
                  radius: 6,
                  color: Colors.white,
                  strokeWidth: 3,
                  strokeColor: const Color(0xFF007BFF),
                );
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
    String text;
    switch (value.toInt()) {
      case 8:
        text = '8 окт';
        break;
      case 9:
        text = '9 окт';
        break;
      case 10:
        text = '10 окт';
        break;
      case 11:
        text = '11 окт';
        break;
      case 12:
        text = '12 окт';
        break;
      case 14:
        text = '14 окт';
        break;
      default:
        return Container();
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Text(
        text,
        style: GoogleFonts.lato(
          color: Colors.grey.shade600,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
