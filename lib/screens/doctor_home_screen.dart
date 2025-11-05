import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medichelp/models/patient_model.dart';
import 'package:medichelp/services/api_service.dart';
import 'package:medichelp/screens/doctor_patient_detail_screen.dart';
import 'package:medichelp/screens/chat_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final List<PatientSummary> _patients = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rawPatients = await ApiService.getDoctorPatients();
      final fetched = rawPatients
          .map((patient) => PatientSummary.fromJson(
                patient as Map<String, dynamic>,
              ))
          .toList();
      setState(() {
        _patients
          ..clear()
          ..addAll(fetched);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Не удалось загрузить пациентов: $e';
      });
    }
  }

  Future<void> _showAddPatientDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading = false;
    String? tempPassword;

    await showDialog(
      context: context,
      barrierDismissible: !isLoading,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> handleSubmit() async {
              if (nameController.text.trim().isEmpty ||
                  emailController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Укажите имя и email пациента'),
                  ),
                );
                return;
              }
              setStateDialog(() {
                isLoading = true;
              });
              try {
                final payload = {
                  'name': nameController.text.trim(),
                  'email': emailController.text.trim(),
                };
                if (passwordController.text.trim().isNotEmpty) {
                  payload['temporaryPassword'] =
                      passwordController.text.trim();
                }
                final response = await ApiService.createPatient(payload);
                tempPassword = response['temporaryPassword'] as String?;
                if (mounted) {
                  Navigator.of(context).pop(true);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
                setStateDialog(() {
                  isLoading = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('Новый пациент'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Имя'),
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Временный пароль (опционально)',
                      ),
                      enabled: !isLoading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : handleSubmit,
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Добавить'),
                ),
              ],
            );
          },
        );
      },
    ).then((value) {
      if (value == true) {
        _loadPatients();
        if (tempPassword != null && mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Пациент добавлен'),
              content: Text(
                'Передайте пациенту временный пароль: $tempPassword\n'
                'Пациент сможет сменить пароль через функцию «Забыли пароль».',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Ок'),
                ),
              ],
            ),
          );
        }
      }
    });
  }

  void _openChat(PatientSummary patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          patientId: patient.id,
          isDoctorView: true,
          title: patient.name,
        ),
      ),
    );
  }

  void _openPatientDetail(PatientSummary patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorPatientDetailScreen(patient: patient),
      ),
    ).then((value) {
      if (value == true) {
        _loadPatients();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeCourses = _patients.fold<int>(
      0,
      (sum, patient) => sum + patient.activeCourses,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text(
          'Мои пациенты',
          style: GoogleFonts.lato(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPatientDialog,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Новый пациент'),
        backgroundColor: const Color(0xFF007BFF),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPatients,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lato(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      _buildSummaryCard(activeCourses),
                      const SizedBox(height: 16),
                      if (_patients.isEmpty)
                        _buildEmptyState()
                      else
                        ..._patients.map(_buildPatientCard),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSummaryCard(int activeCourses) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF33D4A3).withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: const Icon(
              Icons.monitor_heart,
              color: Color(0xFF33D4A3),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Под наблюдением: ${_patients.length}',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Активных курсов лечения: $activeCourses',
                  style: GoogleFonts.lato(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline, color: Colors.grey.shade400, size: 60),
          const SizedBox(height: 16),
          Text(
            'Здесь появятся пациенты клиники',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте пациента, чтобы назначить курс лечения и отслеживать его прогресс.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(color: Colors.black54, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(PatientSummary patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF007BFF).withOpacity(0.1),
                child: Text(
                  patient.name.isNotEmpty
                      ? patient.name.characters.first.toUpperCase()
                      : '?',
                  style: GoogleFonts.lato(
                    color: const Color(0xFF007BFF),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      patient.email,
                      style: GoogleFonts.lato(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildInfoChip(
                icon: Icons.history,
                label: 'Последняя запись',
                value: patient.lastEntryDate != null
                    ? _formatDate(patient.lastEntryDate!)
                    : 'нет данных',
              ),
              _buildInfoChip(
                icon: Icons.assignment,
                label: 'Всего курсов',
                value: patient.totalCourses.toString(),
              ),
              _buildInfoChip(
                icon: Icons.local_hospital,
                label: 'Активные курсы',
                value: patient.activeCourses.toString(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openPatientDetail(patient),
                  icon: const Icon(Icons.insights, size: 20),
                  label: const Text('Детали'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007BFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openChat(patient),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Чат'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF007BFF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF007BFF)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.lato(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.lato(color: Colors.grey.shade900),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }
}
