import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:medichelp/screens/entry_form_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _selectedIndex = 3;
  String _userName = "Загрузка...";
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final name = await _storage.read(key: 'user_name');
    if (mounted) {
      setState(() {
        _userName = name ?? 'Пациент';
      });
    }
  }

  void _onItemTapped(int index) {
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
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EntryFormScreen()),
        );
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
    final String currentDate =
        DateFormat('d MMMM y').format(DateTime.now());
    final String weekAgoDate =
        DateFormat('d MMMM').format(DateTime.now().subtract(const Duration(days: 7)));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 100,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Отчет для врача',
              style: GoogleFonts.lato(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Пациент: $_userName',
              style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Colors.black54),
            ),
            Text(
              'Период: $weekAgoDate - $currentDate 2025',
              style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Colors.black54),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black54),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('Соблюдение режима'),
          _buildComplianceCard(),
          const SizedBox(height: 24),
          _buildSectionTitle('Динамика основного симптома'),
          Text(
            'Головная боль (шкала 0-10)',
            style: GoogleFonts.lato(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 16),
          _buildChart(),
          const SizedBox(height: 24),
          _buildSectionTitle('Обнаруженные корреляции (Выводы ИИ)'),
          _buildCorrelations(),
          const SizedBox(height: 24),
          _buildSectionTitle('Список принимаемых препаратов'),
          _buildMedicationTable(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(
              icon: Icon(Icons.analytics), label: 'Аналитика'),
          BottomNavigationBarItem(icon: Icon(Icons.link), label: 'Лекарства'),
          BottomNavigationBarItem(
              icon: Icon(Icons.description), label: 'Отчет'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF007BFF),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.lato(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildComplianceCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Прием лекарств',
                style: GoogleFonts.lato(fontSize: 16),
              ),
              Text(
                '95% вовремя',
                style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF007BFF)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.95,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF007BFF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
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
                interval: 1,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  String text;
                  switch (value.toInt()) {
                    case 0:
                      text = '8.10';
                      break;
                    case 1:
                      text = '9.10';
                      break;
                    case 2:
                      text = '10.10';
                      break;
                    case 3:
                      text = '11.10';
                      break;
                    case 4:
                      text = '12.10';
                      break;
                    case 5:
                      text = '13.10';
                      break;
                    case 6:
                      text = '14.10';
                      break;
                    default:
                      return Container();
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(text,
                        style:
                            GoogleFonts.lato(color: Colors.grey, fontSize: 12)),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
              show: true, border: Border.all(color: Colors.grey.shade300)),
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: 10,
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 8),
                FlSpot(1, 7),
                FlSpot(2, 4),
                FlSpot(3, 5),
                FlSpot(4, 7),
                FlSpot(5, 3),
                FlSpot(6, 4),
              ],
              isCurved: true,
              color: const Color(0xFF007BFF),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrelations() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCorrelationItem(
              'Отмечена возможная связь между приемом Нурофена и снижением интенсивности головной боли в течение 2 часов.'),
          _buildCorrelationItem(
              'Обнаружена корреляция между недостаточным сном и усилением симптомов усталости.'),
          _buildCorrelationItem(
              'Регулярный прием лекарств показывает стабильное улучшение состояния.'),
        ],
      ),
    );
  }

  Widget _buildCorrelationItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(color: Color(0xFF007BFF), fontSize: 18),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.lato(fontSize: 16, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationTable() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Table(
        border: TableBorder(
          horizontalInside: BorderSide(color: Colors.grey.shade300, width: 1),
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
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
              _buildTableHeader('Частота приема'),
            ],
          ),
          _buildTableRow('Ибупрофен', '400мг', '2 раза в день'),
          _buildTableRow('Витамин D', '2000 ME', '1 раз в день'),
          _buildTableRow('Омега-3', '1000мг', '1 раз в день'),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        text,
        style: GoogleFonts.lato(
            fontWeight: FontWeight.bold, color: Colors.grey.shade600),
      ),
    );
  }

  TableRow _buildTableRow(String a, String b, String c) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(a, style: GoogleFonts.lato(fontSize: 16)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(b, style: GoogleFonts.lato(fontSize: 16)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(c, style: GoogleFonts.lato(fontSize: 16)),
        ),
      ],
    );
  }
}