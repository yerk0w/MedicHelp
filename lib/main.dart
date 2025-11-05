import 'package:flutter/material.dart';
import 'package:medichelp/screens/register_screen.dart';
import 'package:medichelp/screens/login_screen.dart';
import 'package:medichelp/screens/main_screen.dart';

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
      home: LoginScreen(),
      routes: {
        '/main': (context) => const MainScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
      },
    );
  }
}
