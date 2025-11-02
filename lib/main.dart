import 'package:flutter/material.dart';
import 'package:medichelp/screens/register_screen.dart';
import 'package:medichelp/screens/login_screen.dart';
import 'package:medichelp/screens/home_screen.dart';
import 'package:medichelp/screens/profile_screen.dart';
import 'package:medichelp/screens/analytics_screen.dart';
import 'package:medichelp/screens/entry_form_screen.dart';
import 'package:medichelp/screens/report_screen.dart';

void main() {
  runApp(const HealthCompassApp());
}

class HealthCompassApp extends StatelessWidget {
  const HealthCompassApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Compass',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF15A4C4),
      ),
      home: RegisterScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/profile': (context) => ProfileScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/entry_form': (context) => const EntryFormScreen(),
        '/report': (context) => const ReportScreen(),
      },
    );
  }
}