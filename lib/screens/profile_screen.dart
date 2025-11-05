

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medichelp/screens/edit_profile_screen.dart';
import 'package:medichelp/screens/login_screen.dart';
import 'package:medichelp/screens/courses_screen.dart';
import 'package:medichelp/services/api_service.dart';
import 'package:medichelp/models/course_model.dart';

class ProfileScreenContent extends StatefulWidget {
  const ProfileScreenContent({super.key});

  @override
  State<ProfileScreenContent> createState() => _ProfileScreenContentState();
}

class _ProfileScreenContentState extends State<ProfileScreenContent> {
  String _userName = "Загрузка...";
  String _userEmail = "...";
  MedicalCard? _medicalCard;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profileData = await ApiService.getProfile();
      final profile = UserProfile.fromJson(profileData);

      if (mounted) {
        setState(() {
          _userName = profile.name;
          _userEmail = profile.email;
          _medicalCard = profile.medicalCard;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });


        if (e.toString().contains('401') || e.toString().contains('Токен')) {
          _logout();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка загрузки профиля: $e')),
          );
        }
      }
    }
  }

  Future<void> _logout() async {
    await ApiService.deleteToken();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _navigateToEdit() async {
    if (_medicalCard == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(medicalCard: _medicalCard!),
      ),
    );

    if (result == true) {
      _loadProfileData();
    }
  }

  void _navigateToCourses() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CoursesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: RefreshIndicator(
        onRefresh: _loadProfileData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildHeader(),
                  _buildActionButtons(),
                  _buildMedicalCard(),
                ],
              ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: GoogleFonts.lato(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _userEmail,
                  style: GoogleFonts.lato(fontSize: 16, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _navigateToCourses,
              icon: const Icon(Icons.medical_services, size: 20),
              label: const Text('Курсы лечения'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007BFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalCard() {
    if (_medicalCard == null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                'Ошибка загрузки данных',
                style: GoogleFonts.lato(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                width: 120, 
                child: OutlinedButton(
                  onPressed: _navigateToEdit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF007BFF),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ), 
                  ),
                  child: const Text(
                    "Редактировать",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow("Полное имя", _medicalCard!.fullName),
          _buildInfoRow("Дата рождения", _medicalCard!.birthDate),
          _buildInfoRow("Группа крови", _medicalCard!.bloodType),
          _buildInfoRow("Аллергии", _medicalCard!.allergies),
          _buildInfoRow(
            "Хронические заболевания",
            _medicalCard!.chronicDiseases,
          ),
          _buildInfoRow(
            "Контакт для экстренной связи",
            _medicalCard!.emergencyContact,
          ),
          _buildInfoRow(
            "Номер медицинской страховки",
            _medicalCard!.insuranceNumber,
          ),
          _buildInfoRow(
            "Дополнительная информация",
            _medicalCard!.additionalInfo,
            isLast: true,
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: Text(
              "Выйти из аккаунта",
              style: GoogleFonts.lato(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, {bool isLast = false}) {
    final displayValue = value.isEmpty ? "Не указано" : value;
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
        if (!isLast) const Divider(height: 32, thickness: 0.5),
      ],
    );
  }
}
