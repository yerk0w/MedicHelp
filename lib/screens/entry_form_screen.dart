import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class EntryFormScreen extends StatefulWidget {
  const EntryFormScreen({super.key});

  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  final _storage = const FlutterSecureStorage();
  final _notesController = TextEditingController();
  final _symptomController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _courses = [];
  String? _selectedCourseId;
  List<Map<String, dynamic>> _courseMedications = [];
  Map<String, bool> _medicationsTaken = {};

  List<String> _symptoms = [];
  final List<String> _lifestyleTags = [
    'стресс',
    'плохой сон',
    'тренировка',
    'кофе',
    'алкоголь',
    'переедание',
  ];
  final Set<String> _selectedLifestyleTags = {};

  bool _isLoadingCourses = true;
  bool _isLoadingMedications = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    setState(() {
      _isLoadingCourses = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5001/api/courses'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _courses = data
              .map(
                (c) => {
                  'id': c['_id'],
                  'name': c['name'],
                  'mainSymptom': c['mainSymptom'],
                },
              )
              .toList();
          _isLoadingCourses = false;
        });
      } else {
        setState(() {
          _isLoadingCourses = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingCourses = false;
      });
      _showErrorDialog('Ошибка загрузки курсов: $e');
    }
  }

  Future<void> _loadCourseMedications(String courseId) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    setState(() {
      _isLoadingMedications = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5001/api/courses/$courseId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> medications = data['medications'];

        setState(() {
          _courseMedications = medications
              .map(
                (m) => {
                  'id': m['_id'],
                  'name': m['name'],
                  'dosage': m['dosage'],
                  'schedule': m['schedule'],
                },
              )
              .toList();

          _medicationsTaken.clear();
          for (var med in _courseMedications) {
            _medicationsTaken[med['id']] = false;
          }

          _isLoadingMedications = false;
        });
      } else {
        setState(() {
          _isLoadingMedications = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMedications = false;
      });
      _showErrorDialog('Ошибка загрузки лекарств: $e');
    }
  }

  void _addSymptom() {
    if (_symptomController.text.trim().isEmpty) return;

    setState(() {
      _symptoms.add(_symptomController.text.trim());
      _symptomController.clear();
    });
  }

  void _removeSymptom(String symptom) {
    setState(() {
      _symptoms.remove(symptom);
    });
  }

  Future<void> _saveEntry() async {
    if (_selectedCourseId == null) {
      _showErrorDialog('Выберите курс лечения');
      return;
    }

    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      _showErrorDialog('Ошибка авторизации');
      return;
    }

    final medicationsTaken = _medicationsTaken.entries
        .map(
          (entry) => {
            'medId': entry.key,
            'status': entry.value ? 'taken' : 'skipped',
          },
        )
        .toList();

    final body = json.encode({
      'entryDate': _selectedDate.toIso8601String(),
      'courseId': _selectedCourseId,
      'medicationsTaken': medicationsTaken,
      'symptoms': _symptoms,
      'lifestyleTags': _selectedLifestyleTags.toList(),
      'notes': _notesController.text,
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5001/api/entries'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 201) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        final responseData = json.decode(response.body);
        _showErrorDialog(responseData['message'] ?? 'Ошибка сервера');
      }
    } catch (e) {
      _showErrorDialog('Ошибка подключения: $e');
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Новая запись',
              style: GoogleFonts.lato(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              DateFormat('d MMMM y, HH:mm').format(_selectedDate),
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('Курс лечения'),
          _buildCourseDropdown(),
          const SizedBox(height: 24),

          if (_selectedCourseId != null) ...[
            _buildSectionTitle('Прием лекарств'),
            _buildMedicationsList(),
            const SizedBox(height: 24),
          ],

          _buildSectionTitle('Симптомы'),
          const SizedBox(height: 12),
          _buildSymptomInput(),
          const SizedBox(height: 12),
          _buildSymptomsChips(),
          const SizedBox(height: 24),

          _buildSectionTitle('Образ жизни'),
          const SizedBox(height: 12),
          _buildChoiceChipGroup(_lifestyleTags, _selectedLifestyleTags),
          const SizedBox(height: 24),

          _buildSectionTitle('Дополнительные заметки'),
          const SizedBox(height: 12),
          _buildNotesTextField(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ElevatedButton(
          onPressed: _saveEntry,
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
          child: const Text('Сохранить запись'),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: GoogleFonts.lato(
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildCourseDropdown() {
    if (_isLoadingCourses) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_courses.isEmpty) {
      return Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Нет доступных курсов. Создайте курс в настройках.',
            style: GoogleFonts.lato(color: Colors.grey),
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedCourseId,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      hint: Text('Выберите курс', style: GoogleFonts.lato()),
      items: _courses.map((course) {
        return DropdownMenuItem<String>(
          value: course['id'],
          child: Text(
            '${course['name']} (${course['mainSymptom']})',
            style: GoogleFonts.lato(),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedCourseId = newValue;
          });
          _loadCourseMedications(newValue);
        }
      },
    );
  }

  Widget _buildMedicationsList() {
    if (_isLoadingMedications) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_courseMedications.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          'В этом курсе нет лекарств',
          style: GoogleFonts.lato(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: _courseMedications.map((med) {
        final medId = med['id'];
        final schedule = (med['schedule'] as List).join(', ');

        return CheckboxListTile(
          title: Text(
            '${med['name']} (${med['dosage']})',
            style: GoogleFonts.lato(fontSize: 16),
          ),
          subtitle: Text(
            'Расписание: $schedule',
            style: GoogleFonts.lato(fontSize: 14, color: Colors.grey),
          ),
          value: _medicationsTaken[medId] ?? false,
          onChanged: (bool? value) {
            setState(() {
              _medicationsTaken[medId] = value ?? false;
            });
          },
          activeColor: const Color(0xFF007BFF),
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  Widget _buildSymptomInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _symptomController,
            decoration: InputDecoration(
              hintText: 'Введите симптом...',
              hintStyle: GoogleFonts.lato(color: Colors.grey.shade500),
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
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _addSymptom,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007BFF),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text('Добавить', style: GoogleFonts.lato(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildSymptomsChips() {
    if (_symptoms.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Нет добавленных симптомов',
          style: GoogleFonts.lato(color: Colors.grey),
        ),
      );
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: _symptoms.map((symptom) {
        return Chip(
          label: Text(symptom, style: GoogleFonts.lato()),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () => _removeSymptom(symptom),
          backgroundColor: const Color(0xFF007BFF).withOpacity(0.1),
          deleteIconColor: const Color(0xFF007BFF),
        );
      }).toList(),
    );
  }

  Widget _buildNotesTextField() {
    return TextField(
      controller: _notesController,
      decoration: InputDecoration(
        hintText: 'Добавьте детали о вашем самочувствии...',
        hintStyle: GoogleFonts.lato(color: Colors.grey.shade500),
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
      maxLines: 4,
    );
  }

  Widget _buildChoiceChipGroup(List<String> tags, Set<String> selectedTags) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: tags.map((tag) {
        final isSelected = selectedTags.contains(tag);
        return ChoiceChip(
          label: Text(
            '#$tag',
            style: GoogleFonts.lato(
              color: isSelected
                  ? const Color(0xFF007BFF)
                  : Colors.grey.shade700,
            ),
          ),
          selected: isSelected,
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                selectedTags.add(tag);
              } else {
                selectedTags.remove(tag);
              }
            });
          },
          backgroundColor: Colors.white,
          selectedColor: const Color(0xFF007BFF).withOpacity(0.1),
          shape: StadiumBorder(
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFF007BFF).withOpacity(0.5)
                  : Colors.grey.shade300,
            ),
          ),
          elevation: 0,
          pressElevation: 0,
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _symptomController.dispose();
    super.dispose();
  }
}
