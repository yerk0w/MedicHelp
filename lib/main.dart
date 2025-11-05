// lib/main.dart - добавить локализацию и улучшить инициализацию

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:medichelp/screens/register_screen.dart';
import 'package:medichelp/screens/login_screen.dart';
import 'package:medichelp/screens/main_screen.dart';
import 'package:medichelp/services/api_service.dart';
import 'package:medichelp/screens/courses_screen.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);

  runApp(const HealthCompassApp());
}

class HealthCompassApp extends StatelessWidget {
  const HealthCompassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Compass',
      debugShowCheckedModeBanner: false,

      // Локализация
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru', 'RU'), Locale('en', 'US')],
      locale: const Locale('ru', 'RU'),

      // Тема
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
        useMaterial3: true,

        // Цветовая схема
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007BFF),
          primary: const Color(0xFF007BFF),
          secondary: const Color(0xFF33D4A3),
          surface: Colors.white,
        ),

        // Стиль AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF4F6F8),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Стиль карточек
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),

        // Стиль кнопок
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007BFF),
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Стиль текстовых полей
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF007BFF), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),

        // Стиль прогресс-баров
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFF007BFF),
          linearTrackColor: Color(0xFFE0E0E0),
        ),
      ),

      // Навигация
      home: const SplashScreen(),
      routes: {
        '/main': (context) => const MainScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/courses': (context) => const CoursesScreen(),
      },
    );
  }
}

// Экран загрузки с проверкой авторизации
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Небольшая задержка для показа splash screen
    await Future.delayed(const Duration(seconds: 1));

    // Проверяем наличие токена
    final token = await ApiService.getToken();

    if (mounted) {
      if (token != null && token.isNotEmpty) {
        // Если токен есть - переходим на главный экран
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        // Если токена нет - на экран входа
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF15A4C4), Color(0xFF33D4A3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.show_chart,
                  color: Color(0xFF15A4C4),
                  size: 80,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Health Compass',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ваш личный помощник здоровья',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
