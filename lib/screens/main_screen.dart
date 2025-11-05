import 'package:flutter/material.dart';
import 'package:medichelp/screens/home_screen.dart';
import 'package:medichelp/screens/analytics_screen.dart';
import 'package:medichelp/screens/profile_screen.dart';
import 'package:medichelp/screens/report_screen.dart';
import 'package:medichelp/screens/entry_form_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreenContent(),
    const AnalyticsScreenContent(),
    const SizedBox(),
    const ReportScreenContent(),
    const ProfileScreenContent(),
  ];

  void _onItemTapped(int index) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      floatingActionButton: _selectedIndex == 0
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
}
