// lib/screens/edit_profile_screen.dart - рефакторинг с использованием ApiService

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medichelp/services/api_service.dart';
import 'package:medichelp/models/course_model.dart';

class EditProfileScreen extends StatefulWidget {
  final MedicalCard medicalCard;

  const EditProfileScreen({super.key, required this.medicalCard});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _birthDateController;
  late TextEditingController _bloodTypeController;
  late TextEditingController _allergiesController;
  late TextEditingController _chronicDiseasesController;
  late TextEditingController _emergencyContactController;
  late TextEditingController _insuranceNumberController;
  late TextEditingController _additionalInfoController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: widget.medicalCard.fullName,
    );
    _birthDateController = TextEditingController(
      text: widget.medicalCard.birthDate,
    );
    _bloodTypeController = TextEditingController(
      text: widget.medicalCard.bloodType,
    );
    _allergiesController = TextEditingController(
      text: widget.medicalCard.allergies,
    );
    _chronicDiseasesController = TextEditingController(
      text: widget.medicalCard.chronicDiseases,
    );
    _emergencyContactController = TextEditingController(
      text: widget.medicalCard.emergencyContact,
    );
    _insuranceNumberController = TextEditingController(
      text: widget.medicalCard.insuranceNumber,
    );
    _additionalInfoController = TextEditingController(
      text: widget.medicalCard.additionalInfo,
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _birthDateController.dispose();
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    _chronicDiseasesController.dispose();
    _emergencyContactController.dispose();
    _insuranceNumberController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profileData = {
        'fullName': _fullNameController.text,
        'birthDate': _birthDateController.text,
        'bloodType': _bloodTypeController.text,
        'allergies': _allergiesController.text,
        'chronicDiseases': _chronicDiseasesController.text,
        'emergencyContact': _emergencyContactController.text,
        'insuranceNumber': _insuranceNumberController.text,
        'additionalInfo': _additionalInfoController.text,
      };

      await ApiService.updateProfile(profileData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Профиль успешно обновлен'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text(
          'Редактировать профиль',
          style: GoogleFonts.lato(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFF4F6F8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildTextField(_fullNameController, 'Полное имя'),
          _buildTextField(
            _birthDateController,
            'Дата рождения',
            hint: 'дд.мм.гггг',
          ),
          _buildTextField(_bloodTypeController, 'Группа крови'),
          _buildTextField(_allergiesController, 'Аллергии', maxLines: 3),
          _buildTextField(
            _chronicDiseasesController,
            'Хронические заболевания',
            maxLines: 3,
          ),
          _buildTextField(
            _emergencyContactController,
            'Контакт для экстренной связи',
          ),
          _buildTextField(
            _insuranceNumberController,
            'Номер медицинской страховки',
          ),
          _buildTextField(
            _additionalInfoController,
            'Дополнительная информация',
            maxLines: 4,
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007BFF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Сохранить'),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    String? hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
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
                borderSide: const BorderSide(color: Color(0xFF007BFF)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
