import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:medichelp/screens/analytics_screen.dart';
import 'package:medichelp/screens/doctor_home_screen.dart';
import 'package:medichelp/screens/profile_screen.dart';
import 'package:medichelp/screens/report_screen.dart';
import 'package:medichelp/screens/entry_form_screen.dart';
import 'package:medichelp/screens/home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isDoctor = false;
  late List<Widget> _screens;
  late List<BottomNavigationBarItem> _navItems;
  final _storage = const FlutterSecureStorage();

  void _onItemTapped(int index) {
    if (!_isDoctor && index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EntryFormScreen()),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _initScreens();
  }

  Future<void> _initScreens() async {
    final role = await _storage.read(key: 'user_role') ?? 'patient';
    setState(() {
      _isDoctor = role == 'doctor';
      if (_isDoctor) {
        _screens = const [
          DoctorHomeScreen(),
          ProfileScreenContent(),
        ];
        _navItems = const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Пациенты'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ];
      } else {
        _screens = const [
          HomeScreenContent(),
          AnalyticsScreenContent(),
          SizedBox(),
          ReportScreenContent(),
          ProfileScreenContent(),
        ];
        _navItems = const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Аналитика'),
          BottomNavigationBarItem(icon: Icon(Icons.link), label: 'Лекарства'),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Отчет'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ];
      }
      _selectedIndex = 0;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      floatingActionButton: !_isDoctor && _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EntryFormScreen(),
                  ),
                );
              },
              backgroundColor: const Color(0xFF007BFF),
              child: const Icon(Icons.add, color: Colors.white),
              shape: const CircleBorder(),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        items: _navItems,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF007BFF),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }
}
