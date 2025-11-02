import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class Medication {
  String name;
  bool taken;
  TimeOfDay time;

  Medication({required this.name, this.taken = false, required this.time});

  Map<String, dynamic> toJson() => {
        'name': name,
        'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        'taken': taken,
      };
}

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
  double _headacheLevel = 5.0;

  final List<Medication> _medications = [
    Medication(name: 'Ибупрофен 400мг', time: const TimeOfDay(hour: 9, minute: 0)),
    Medication(name: 'Витамин D', time: const TimeOfDay(hour: 12, minute: 0)),
  ];
  final List<String> _symptomTags = ['тошнота', 'усталость', 'головокружение'];
  final List<String> _lifestyleTags = [
    'стресс',
    'плохой сон',
    'тренировка',
    'кофе',
    'алкоголь',
    'переедание'
  ];

  final Set<String> _selectedSymptomTags = {};
  final Set<String> _selectedLifestyleTags = {};

  Future<void> _saveEntry() async {
    final String? token = await _storage.read(key: 'jwt_token');

    if (token == null) {
      _showErrorDialog('Ошибка авторизации. Попробуйте войти заново.');
      return;
    }

    final List<Map<String, dynamic>> medsJson =
        _medications.map((med) => med.toJson()).toList();

    final body = json.encode({
      'entryDate': _selectedDate.toIso8601String(),
      'medications': medsJson,
      'headacheLevel': _headacheLevel.toInt(),
      'symptomTags': _selectedSymptomTags.toList(),
      'lifestyleTags': _selectedLifestyleTags.toList(),
      'notes': _notesController.text,
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/entries'),
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
  
  Future<void> _showAddMedicationDialog() async {
    final medNameController = TextEditingController();
    TimeOfDay? selectedTime = TimeOfDay.now();

    final result = await showDialog<Medication>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: Text('Добавить лекарство', style: GoogleFonts.lato()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: medNameController,
                    decoration: const InputDecoration(
                      labelText: 'Название лекарства',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(
                      'Время приема: ${selectedTime?.format(context) ?? "Не выбрано"}',
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedTime ?? TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        dialogSetState(() {
                          selectedTime = pickedTime;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () {
                    if (medNameController.text.isNotEmpty &&
                        selectedTime != null) {
                      final newMed = Medication(
                        name: medNameController.text,
                        time: selectedTime!,
                        taken: false,
                      );
                      Navigator.of(context).pop(newMed);
                    }
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _medications.add(result);
      });
    }
  }

  void _removeMedication(Medication med) {
    setState(() {
      _medications.remove(med);
    });
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
                  color: Colors.black54),
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
          _buildSectionTitle('Прием лекарств'),
          _buildMedicationList(),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Добавить лекарство'),
            onPressed: _showAddMedicationDialog,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF007BFF),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Симптомы'),
          _buildHeadacheSlider(),
          const SizedBox(height: 24),
          _buildSectionTitle('Добавить симптомы'),
          const SizedBox(height: 12),
          _buildChoiceChipGroup(_symptomTags, _selectedSymptomTags),
          const SizedBox(height: 16),
          _buildSymptomTextField(),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.lato(
                fontSize: 18, fontWeight: FontWeight.bold),
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
              color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildMedicationList() {
    if (_medications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Нажмите "+", чтобы добавить лекарства',
            style: GoogleFonts.lato(color: Colors.grey),
          ),
        ),
      );
    }
    return Column(
      children: _medications.map((med) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Switch(
            value: med.taken,
            onChanged: (bool value) {
              setState(() {
                med.taken = value;
              });
            },
            activeColor: const Color(0xFF007BFF),
          ),
          title: Text(med.name, style: GoogleFonts.lato(fontSize: 16)),
          subtitle: Text(med.time.format(context), style: GoogleFonts.lato()),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _removeMedication(med),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeadacheSlider() {
    return Card(
      elevation: 1,
      shadowColor: Colors.grey.shade200,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Уровень головной боли',
                  style:
                      GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${_headacheLevel.toInt()}/10',
                  style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFF007BFF)),
                ),
              ],
            ),
            Slider(
              value: _headacheLevel,
              min: 0,
              max: 10,
              divisions: 10,
              label: _headacheLevel.round().toString(),
              activeColor: const Color(0xFF007BFF),
              onChanged: (double value) {
                setState(() {
                  _headacheLevel = value;
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Нет боли', style: GoogleFonts.lato(color: Colors.grey)),
                Text('Сильная боль',
                    style: GoogleFonts.lato(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomTextField() {
    return TextField(
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
              color: isSelected ? const Color(0xFF007BFF) : Colors.grey.shade700,
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
}