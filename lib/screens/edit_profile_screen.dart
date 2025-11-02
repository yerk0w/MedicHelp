import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> medicalCard;

  const EditProfileScreen({super.key, required this.medicalCard});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _storage = const FlutterSecureStorage();
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
    _fullNameController =
        TextEditingController(text: widget.medicalCard['fullName']);
    _birthDateController =
        TextEditingController(text: widget.medicalCard['birthDate']);
    _bloodTypeController =
        TextEditingController(text: widget.medicalCard['bloodType']);
    _allergiesController =
        TextEditingController(text: widget.medicalCard['allergies']);
    _chronicDiseasesController =
        TextEditingController(text: widget.medicalCard['chronicDiseases']);
    _emergencyContactController =
        TextEditingController(text: widget.medicalCard['emergencyContact']);
    _insuranceNumberController =
        TextEditingController(text: widget.medicalCard['insuranceNumber']);
    _additionalInfoController =
        TextEditingController(text: widget.medicalCard['additionalInfo']);
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

    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      _showErrorDialog('Ошибка авторизации');
      return;
    }

    final body = json.encode({
      'fullName': _fullNameController.text,
      'birthDate': _birthDateController.text,
      'bloodType': _bloodTypeController.text,
      'allergies': _allergiesController.text,
      'chronicDiseases': _chronicDiseasesController.text,
      'emergencyContact': _emergencyContactController.text,
      'insuranceNumber': _insuranceNumberController.text,
      'additionalInfo': _additionalInfoController.text,
    });

    try {
      final response = await http.put(
        Uri.parse('http://localhost:5000/api/profile'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        _showErrorDialog('Не удалось сохранить. ${response.body}');
      }
    } catch (e) {
      _showErrorDialog('Ошибка подключения: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
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
          _buildTextField(_birthDateController, 'Дата рождения',
              hint: 'дд.мм.гггг'),
          _buildTextField(_bloodTypeController, 'Группа крови'),
          _buildTextField(_allergiesController, 'Аллергии', maxLines: 3),
          _buildTextField(_chronicDiseasesController, 'Хронические заболевания',
              maxLines: 3),
          _buildTextField(
              _emergencyContactController, 'Контакт для экстренной связи'),
          _buildTextField(
              _insuranceNumberController, 'Номер медицинской страховки'),
          _buildTextField(_additionalInfoController, 'Дополнительная информация',
              maxLines: 4),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.lato(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Сохранить'),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {String? hint, int maxLines = 1}) {
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
                color: Colors.black54),
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