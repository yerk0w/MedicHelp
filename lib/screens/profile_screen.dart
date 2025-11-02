import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:medichelp/screens/edit_profile_screen.dart';
import 'package:medichelp/screens/entry_form_screen.dart';
import 'package:medichelp/screens/login_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 4;
  final _storage = const FlutterSecureStorage();
  String _userName = "Загрузка...";
  String _userEmail = "...";
  Map<String, dynamic>? _medicalCard;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      _logout();
      return;
    }

    try {
      final response = await http
          .get(Uri.parse('http://localhost:5000/api/profile'), headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _userName = data['name'] ?? 'Пользователь';
            _userEmail = data['email'] ?? 'email@example.com';
            _medicalCard = data['medicalCard'];
          });
        }
      } else {
        await _storage.deleteAll();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка сети: $e')));
      }
    }
  }

  Future<void> _logout() async {
    await _storage.deleteAll();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

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

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/analytics');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/report');
        break;
      case 4:
        break;
    }
  }

  void _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditProfileScreen(medicalCard: _medicalCard ?? {}),
      ),
    );

    if (result == true) {
      _loadProfileData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: RefreshIndicator(
        onRefresh: _loadProfileData,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(),
            _buildMedicalCard(),
          ],
        ),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
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
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 40, color: Color(0xFF15A4C4)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userName,
                style: GoogleFonts.lato(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                _userEmail,
                style: GoogleFonts.lato(fontSize: 16, color: Colors.white70),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMedicalCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Медицинская карта",
                style: GoogleFonts.lato(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              OutlinedButton(
                onPressed: _navigateToEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF007BFF),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Редактировать"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
              "Полное имя", _medicalCard?['fullName'] ?? "Не указано"),
          _buildInfoRow(
              "Дата рождения", _medicalCard?['birthDate'] ?? "Не указано"),
          _buildInfoRow(
              "Группа крови", _medicalCard?['bloodType'] ?? "Не указано"),
          _buildInfoRow(
              "Аллергии", _medicalCard?['allergies'] ?? "Не указано"),
          _buildInfoRow("Хронические заболевания",
              _medicalCard?['chronicDiseases'] ?? "Не указано"),
          _buildInfoRow("Контакт для экстренной связи",
              _medicalCard?['emergencyContact'] ?? "Не указано"),
          _buildInfoRow("Номер медицинской страховки",
              _medicalCard?['insuranceNumber'] ?? "Не указано"),
          _buildInfoRow("Дополнительная информация",
              _medicalCard?['additionalInfo'] ?? "Не указано",
              isLast: true),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: Text(
              "Выйти из аккаунта",
              style: GoogleFonts.lato(
                  color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, {bool isLast = false}) {
    final displayValue = (value.isEmpty) ? "Не указано" : value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.lato(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          displayValue,
          style: GoogleFonts.lato(color: Colors.black, fontSize: 16),
        ),
        if (!isLast)
          const Divider(
            height: 32,
            thickness: 0.5,
          ),
      ],
    );
  }
}