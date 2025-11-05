// lib/main.dart - обновить роуты для новых экранов

import 'package:flutter/material.dart';
import 'package:medichelp/screens/register_screen.dart';
import 'package:medichelp/screens/login_screen.dart';
import 'package:medichelp/screens/main_screen.dart';
import 'package:medichelp/screens/courses_screen.dart';

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
        useMaterial3: true,
      ),
      home: LoginScreen(),
      routes: {
        '/main': (context) => const MainScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/courses': (context) => const CoursesScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
