// lib/screens/entry_form_screen.dart - рефакторинг с использованием ApiService

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medichelp/services/api_service.dart';
import 'package:medichelp/models/course_model.dart';

class EntryFormScreen extends StatefulWidget {
  const EntryFormScreen({super.key});

  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  final _notesController = TextEditingController();
  final _symptomController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  List<Course> _courses = [];
  String? _selectedCourseId;
  List<Medication> _courseMedications = [];
  Map<String, bool> _medicationsTaken = {};

  List<String> _symptoms = [];
  double _headacheLevel = 0;
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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoadingCourses = true;
    });

    try {
      final coursesJson = await ApiService.getCourses();
      setState(() {
        _courses = coursesJson.map((c) => Course.fromJson(c)).toList();
        _isLoadingCourses = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCourses = false;
      });
      _showErrorDialog('Ошибка загрузки курсов: $e');
    }
  }

  Future<void> _loadCourseMedications(String courseId) async {
    setState(() {
      _isLoadingMedications = true;
    });

    try {
      final courseData = await ApiService.getCourseById(courseId);
      final List<dynamic> medications = courseData['medications'];

      setState(() {
        _courseMedications = medications
            .map((m) => Medication.fromJson(m))
            .toList();

        _medicationsTaken.clear();
        for (var med in _courseMedications) {
          _medicationsTaken[med.id] = false;
        }

        _isLoadingMedications = false;
      });
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

    setState(() {
      _isSaving = true;
    });

    try {
      final medicationsTaken = _medicationsTaken.entries
          .map(
            (entry) => {
              'medId': entry.key,
              'status': entry.value ? 'taken' : 'skipped',
            },
          )
          .toList();

      final entryData = {
        'entryDate': _selectedDate.toIso8601String(),
        'courseId': _selectedCourseId,
        'medicationsTaken': medicationsTaken,
        'symptoms': _symptoms,
        'symptomTags': _symptoms,
        'headacheLevel': _headacheLevel.toInt(),
        'lifestyleTags': _selectedLifestyleTags.toList(),
        'notes': _notesController.text,
      };

      await ApiService.createEntry(entryData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Запись успешно сохранена'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorDialog('Ошибка сохранения: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
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
              DateFormat('d MMMM y, HH:mm', 'ru').format(_selectedDate),
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

          _buildSectionTitle('Уровень головной боли'),
          const SizedBox(height: 12),
          _buildHeadacheLevelSlider(),
          const SizedBox(height: 24),

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
          onPressed: _isSaving ? null : _saveEntry,
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
          child: _isSaving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Сохранить запись'),
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
          child: Column(
            children: [
              Icon(Icons.info_outline, color: Colors.grey.shade400, size: 48),
              const SizedBox(height: 8),
              Text(
                'Нет доступных курсов',
                style: GoogleFonts.lato(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Создайте курс в настройках',
                style: GoogleFonts.lato(color: Colors.grey.shade600),
              ),
            ],
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
          value: course.id,
          child: Text(
            '${course.name} (${course.mainSymptom})',
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
        final schedule = med.schedule.join(', ');

        return CheckboxListTile(
          title: Text(
            '${med.name} (${med.dosage})',
            style: GoogleFonts.lato(fontSize: 16),
          ),
          subtitle: Text(
            'Расписание: $schedule',
            style: GoogleFonts.lato(fontSize: 14, color: Colors.grey),
          ),
          value: _medicationsTaken[med.id] ?? false,
          onChanged: (bool? value) {
            setState(() {
              _medicationsTaken[med.id] = value ?? false;
            });
          },
          activeColor: const Color(0xFF007BFF),
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  Widget _buildHeadacheLevelSlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Уровень: ${_headacheLevel.toInt()}/10',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF007BFF),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _headacheLevel < 4
                    ? Colors.green.shade100
                    : _headacheLevel < 7
                    ? Colors.orange.shade100
                    : Colors.red.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _headacheLevel < 4
                    ? 'Легкая'
                    : _headacheLevel < 7
                    ? 'Средняя'
                    : 'Сильная',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _headacheLevel < 4
                      ? Colors.green.shade800
                      : _headacheLevel < 7
                      ? Colors.orange.shade800
                      : Colors.red.shade800,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: _headacheLevel,
          min: 0,
          max: 10,
          divisions: 10,
          label: _headacheLevel.toInt().toString(),
          onChanged: (value) {
            setState(() {
              _headacheLevel = value;
            });
          },
          activeColor: const Color(0xFF007BFF),
        ),
      ],
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
            onSubmitted: (_) => _addSymptom(),
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
