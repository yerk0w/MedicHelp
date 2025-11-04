import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:medichelp/screens/entry_form_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Medication {
  final String name;
  final String time;
  bool isTaken;

  Medication({required this.name, required this.time, this.isTaken = false});

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      name: json['name'] ?? 'Без имени',
      time: json['time'] ?? '00:00',
      isTaken: json['taken'] ?? false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _userName = "...";
  bool _isLoadingPlan = true;
  final _storage = const FlutterSecureStorage();

  List<Medication> _medications = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadUserName();
    await _loadTodayPlan();
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
        Uri.parse('http://localhost:5001/api/entries/today'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> medsJson = json.decode(response.body);
        if (mounted) {
          setState(() {
            _medications = medsJson
                .map((json) => Medication.fromJson(json))
                .toList();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Ошибка загрузки плана: $e")));
      }
    }
  }

  void _navigateToAddEntry() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EntryFormScreen()),
    ).then((_) {
      _loadTodayPlan();
    });
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    if (index == 2) {
      _navigateToAddEntry();
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/analytics');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/report');
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
      body: RefreshIndicator(
        onRefresh: _loadTodayPlan,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPlanCard(),
                  const SizedBox(height: 20),
                  _buildChartCard(),
                  const SizedBox(height: 20),
                  _buildInsightsCard(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddEntry,
        backgroundColor: const Color(0xFF007BFF),
        child: const Icon(Icons.add, color: Colors.white),
        shape: const CircleBorder(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Аналитика',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.link), label: 'Лекарства'),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Отчет',
          ),
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
                        'План на сегодня пуст. Нажмите "+", чтобы добавить запись.',
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

  Widget _buildMedicationTile(Medication medication) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: medication.isTaken,
        onChanged: (bool? value) {
          setState(() {
            medication.isTaken = value!;
          });
        },
        activeColor: const Color(0xFF007BFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      title: Text(medication.name, style: GoogleFonts.lato()),
      trailing: Text(
        medication.time,
        style: GoogleFonts.lato(color: Colors.grey),
      ),
    );
  }

  Widget _buildChartCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, color: Color(0xFF33D4A3)),
                const SizedBox(width: 8),
                Text(
                  'Динамика симптомов',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Головная боль - 7 дней',
              style: GoogleFonts.lato(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            SizedBox(height: 120, child: LineChart(_mainchartData())),
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
                  'Ваш инсайд дня',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ваше давление в норме последние 3 дня. Отличная работа!',
                  style: GoogleFonts.lato(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _mainchartData() {
    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: 1,
            getTitlesWidget: (value, meta) {
              const style = TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              );
              switch (value.toInt()) {
                case 0:
                  return const Text('Пн', style: style);
                case 1:
                  return const Text('Вт', style: style);
                case 2:
                  return const Text('Ср', style: style);
                case 3:
                  return const Text('Чт', style: style);
                case 4:
                  return const Text('Пт', style: style);
                case 5:
                  return const Text('Сб', style: style);
                case 6:
                  return const Text('Вс', style: style);
              }
              return const Text('', style: style);
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: const [
            FlSpot(0, 3),
            FlSpot(1, 5),
            FlSpot(2, 4),
            FlSpot(3, 6),
            FlSpot(4, 5),
            FlSpot(5, 7),
            FlSpot(6, 6),
          ],
          isCurved: true,
          color: const Color(0xFF33D4A3),
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: const Color(0xFF33D4A3).withOpacity(0.3),
          ),
        ),
      ],
    );
  }
}
