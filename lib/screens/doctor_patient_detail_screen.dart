import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medichelp/models/course_model.dart';
import 'package:medichelp/models/patient_model.dart';
import 'package:medichelp/screens/chat_screen.dart';
import 'package:medichelp/services/api_service.dart';

class DoctorPatientDetailScreen extends StatefulWidget {
  final PatientSummary patient;

  const DoctorPatientDetailScreen({super.key, required this.patient});

  @override
  State<DoctorPatientDetailScreen> createState() =>
      _DoctorPatientDetailScreenState();
}

class _DoctorPatientDetailScreenState extends State<DoctorPatientDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  PatientProfile? _profile;
  List<Course> _courses = [];
  final Map<String, List<Medication>> _courseMedications = {};
  final Set<String> _loadingMedications = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profileFuture =
          ApiService.getPatientProfileById(widget.patient.id);
      final coursesFuture =
          ApiService.getCourses(patientId: widget.patient.id);

      final results = await Future.wait([profileFuture, coursesFuture]);

      final profileData = results[0] as Map<String, dynamic>;
      final coursesData = results[1] as List<dynamic>;

      final parsedCourses = coursesData
          .map((courseJson) => Course.fromJson(courseJson as Map<String, dynamic>))
          .toList();

      setState(() {
        _profile = PatientProfile.fromJson(profileData);
        _courses = parsedCourses;
        _courseMedications.clear();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Не удалось загрузить данные пациента: $e';
      });
    }
  }

  Future<void> _ensureMedicationsLoaded(String courseId) async {
    if (_courseMedications.containsKey(courseId) ||
        _loadingMedications.contains(courseId)) {
      return;
    }

    _loadingMedications.add(courseId);
    try {
      final data = await ApiService.getCourseById(courseId);
      final medicationsJson = data['medications'] as List<dynamic>;
      final meds = medicationsJson
          .map(
            (json) => Medication.fromJson(json as Map<String, dynamic>),
          )
          .toList();
      setState(() {
        _courseMedications[courseId] = meds;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки лекарств: $e')),
        );
      }
    } finally {
      _loadingMedications.remove(courseId);
    }
  }

  Future<void> _showCreateCourseDialog() async {
    final nameController = TextEditingController();
    final symptomController = TextEditingController();
    DateTime? startDate = DateTime.now();
    DateTime? endDate;
    final List<_MedicationDraft> medications = [];
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> addMedicationDraft() async {
              final medDraft = await showDialog<_MedicationDraft>(
                context: context,
                builder: (context) {
                  final medNameController = TextEditingController();
                  final medDosageController = TextEditingController();
                  final medScheduleController = TextEditingController();
                  bool isMedSaving = false;

                  return StatefulBuilder(
                    builder: (context, setMedState) {
                      Future<void> handleSave() async {
                        if (medNameController.text.trim().isEmpty ||
                            medDosageController.text.trim().isEmpty ||
                            medScheduleController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Заполните все поля лекарства'),
                            ),
                          );
                          return;
                        }
                        setMedState(() {
                          isMedSaving = true;
                        });
                        Navigator.of(context).pop(
                          _MedicationDraft(
                            name: medNameController.text.trim(),
                            dosage: medDosageController.text.trim(),
                            scheduleRaw: medScheduleController.text.trim(),
                          ),
                        );
                      }

                      return AlertDialog(
                        title: const Text('Добавить лекарство'),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: medNameController,
                                decoration: const InputDecoration(labelText: 'Название'),
                                enabled: !isMedSaving,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: medDosageController,
                                decoration: const InputDecoration(labelText: 'Дозировка'),
                                enabled: !isMedSaving,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: medScheduleController,
                                decoration: const InputDecoration(
                                  labelText: 'Расписание (через запятую)',
                                  hintText: 'Утро, Вечер',
                                ),
                                enabled: !isMedSaving,
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: isMedSaving ? null : () => Navigator.pop(context),
                            child: const Text('Отмена'),
                          ),
                          ElevatedButton(
                            onPressed: isMedSaving ? null : handleSave,
                            child: isMedSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Сохранить'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );

              if (medDraft != null) {
                setDialogState(() {
                  medications.add(medDraft);
                });
              }
            }

            Future<void> pickDate(bool isStart) async {
              final initial = isStart
                  ? startDate ?? DateTime.now()
                  : endDate ?? DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setDialogState(() {
                  if (isStart) {
                    startDate = picked;
                  } else {
                    endDate = picked;
                  }
                });
              }
            }

            Future<void> handleSave() async {
              if (nameController.text.trim().isEmpty ||
                  symptomController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Заполните название и основной симптом'),
                  ),
                );
                return;
              }
              setDialogState(() {
                isSaving = true;
              });
              try {
                final courseData = {
                  'name': nameController.text.trim(),
                  'mainSymptom': symptomController.text.trim(),
                  'startDate': startDate?.toIso8601String(),
                  'endDate': endDate?.toIso8601String(),
                };
                final newCourse = await ApiService.createCourse(
                  courseData,
                  patientId: widget.patient.id,
                );
                final dynamic createdId = newCourse['_id'] ??
                    newCourse['id'] ??
                    newCourse['courseId'];
                final courseId = createdId?.toString();

                for (final med in medications) {
                  final schedule = med.scheduleRaw
                      .split(',')
                      .map((part) => part.trim())
                      .where((part) => part.isNotEmpty)
                      .toList();
                  if (courseId != null) {
                    await ApiService.addMedication(courseId, {
                      'name': med.name,
                      'dosage': med.dosage,
                      'schedule': schedule,
                    });
                  }
                }

                if (mounted) {
                  Navigator.of(context).pop(true);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка при сохранении курса: $e')),
                  );
                }
                setDialogState(() {
                  isSaving = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('Назначить курс лечения'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Название'),
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: symptomController,
                      decoration:
                          const InputDecoration(labelText: 'Основной симптом'),
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving ? null : () => pickDate(true),
                            child: Text(
                              startDate != null
                                  ? 'Начало: ${_formatDate(startDate!)}'
                                  : 'Дата начала',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving ? null : () => pickDate(false),
                            child: Text(
                              endDate != null
                                  ? 'Конец: ${_formatDate(endDate!)}'
                                  : 'Дата окончания',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Лекарства',
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (medications.isEmpty)
                      Text(
                        'Добавьте одно или несколько лекарств.',
                        style: GoogleFonts.lato(color: Colors.black54),
                      )
                    else
                      Column(
                        children: medications
                            .map(
                              (med) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  med.name,
                                  style: GoogleFonts.lato(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${med.dosage}\n${med.scheduleRaw}',
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: isSaving ? null : addMedicationDraft,
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить лекарство'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : handleSave,
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    ).then((value) {
      if (value == true) {
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Курс успешно назначен')),
          );
        }
      }
    });
  }

  Future<void> _showAddMedicationDialog(String courseId) async {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final scheduleController = TextEditingController();
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> handleSave() async {
              if (nameController.text.trim().isEmpty ||
                  dosageController.text.trim().isEmpty ||
                  scheduleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Заполните все поля лекарства'),
                  ),
                );
                return;
              }
              setDialogState(() {
                isSaving = true;
              });
              try {
                final schedule = scheduleController.text
                    .split(',')
                    .map((value) => value.trim())
                    .where((value) => value.isNotEmpty)
                    .toList();
                await ApiService.addMedication(courseId, {
                  'name': nameController.text.trim(),
                  'dosage': dosageController.text.trim(),
                  'schedule': schedule,
                });
                if (mounted) {
                  Navigator.of(context).pop(true);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
                setDialogState(() {
                  isSaving = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('Добавить лекарство'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Название'),
                    enabled: !isSaving,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dosageController,
                    decoration: const InputDecoration(labelText: 'Дозировка'),
                    enabled: !isSaving,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: scheduleController,
                    decoration: const InputDecoration(
                      labelText: 'Расписание (через запятую)',
                      hintText: 'Утро, День, Вечер',
                    ),
                    enabled: !isSaving,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : handleSave,
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    ).then((value) {
      if (value == true) {
        _courseMedications.remove(courseId);
        _ensureMedicationsLoaded(courseId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Лекарство добавлено')),
          );
        }
      }
    });
  }

  Future<void> _deleteCourse(String courseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить курс'),
        content: const Text(
          'Вы уверены, что хотите удалить курс лечения? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ApiService.deleteCourse(courseId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Курс удален')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: $e')),
        );
      }
    }
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          patientId: widget.patient.id,
          isDoctorView: true,
          title: widget.patient.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text(
          widget.patient.name,
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openChat,
            icon: const Icon(Icons.chat_bubble_outline),
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateCourseDialog,
        icon: const Icon(Icons.assignment_add, color: Colors.white),
        label: const Text('Назначить курс'),
        backgroundColor: const Color(0xFF007BFF),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(color: Colors.red),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    children: [
                      _buildPatientInfoCard(),
                      const SizedBox(height: 16),
                      if (_profile?.medicalCard.isNotEmpty ?? false)
                        _buildMedicalCardBlock(),
                      const SizedBox(height: 16),
                      _buildCoursesSection(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Контактная информация',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.email_outlined, widget.patient.email),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.history,
            widget.patient.lastEntryDate != null
                ? 'Последняя запись: ${_formatDate(widget.patient.lastEntryDate!)}'
                : 'Еще нет записей о самочувствии',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.medication,
            'Активных курсов: ${widget.patient.activeCourses}',
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalCardBlock() {
    final card = _profile?.medicalCard ?? {};

    final entries = card.entries
        .where(
          (entry) =>
              entry.value is String &&
              (entry.value as String).trim().isNotEmpty,
        )
        .toList();

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Медицинская карта',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildInfoRow(
                Icons.info_outline,
                '${_beautifyKey(entry.key)}: ${entry.value}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesSection() {
    if (_courses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(Icons.assignment_outlined,
                size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Назначенных курсов пока нет',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Назначьте курс, чтобы контролировать лечение пациента и отслеживать прием лекарств.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(color: Colors.black54, height: 1.4),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _courses.map(_buildCourseCard).toList(),
    );
  }

  Widget _buildCourseCard(Course course) {
    final isActive = course.endDate == null ||
        course.endDate!.isAfter(DateTime.now().subtract(const Duration(days: 1)));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        onExpansionChanged: (expanded) {
          if (expanded) {
            _ensureMedicationsLoaded(course.id);
          }
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Text(
          course.name,
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            course.mainSymptom,
            style: GoogleFonts.lato(color: Colors.black54),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF33D4A3).withOpacity(0.15)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isActive ? 'Активен' : 'Завершен',
            style: GoogleFonts.lato(
              color: isActive ? const Color(0xFF0F8F64) : Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                  Icons.calendar_today,
                  'Старт: ${_formatDate(course.startDate)}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoRow(
                  Icons.event,
                  'Окончание: ${course.endDate != null ? _formatDate(course.endDate!) : 'не указано'}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Лекарства',
            style: GoogleFonts.lato(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          if (_loadingMedications.contains(course.id))
            const Center(child: CircularProgressIndicator())
          else if (!(_courseMedications[course.id]?.isNotEmpty ?? false))
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Лекарства не добавлены',
                style: GoogleFonts.lato(color: Colors.black54),
              ),
            )
          else
            Column(
              children: _courseMedications[course.id]!
                  .map(
                    (med) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.medication_outlined),
                      title: Text(
                        med.name,
                        style: GoogleFonts.lato(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${med.dosage}\n${med.schedule.join(', ')}',
                        style: GoogleFonts.lato(height: 1.4),
                      ),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAddMedicationDialog(course.id),
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить лекарство'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _deleteCourse(course.id),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Удалить курс'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.lato(color: Colors.black87),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  String _beautifyKey(String key) {
    switch (key) {
      case 'fullName':
        return 'ФИО';
      case 'birthDate':
        return 'Дата рождения';
      case 'bloodType':
        return 'Группа крови';
      case 'allergies':
        return 'Аллергии';
      case 'chronicDiseases':
        return 'Хронические заболевания';
      case 'emergencyContact':
        return 'Контакт для экстренной связи';
      case 'insuranceNumber':
        return 'Полис';
      case 'additionalInfo':
        return 'Дополнительно';
      default:
        return key;
    }
  }
}

class _MedicationDraft {
  final String name;
  final String dosage;
  final String scheduleRaw;

  _MedicationDraft({
    required this.name,
    required this.dosage,
    required this.scheduleRaw,
  });
}
