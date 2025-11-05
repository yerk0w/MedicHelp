import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:medichelp/screens/main_screen.dart';
import 'package:medichelp/config/api_config.dart'; // ДОБАВЛЕНО

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _storage = const FlutterSecureStorage();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    final String email = _emailController.text;
    final String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog('Пожалуйста, заполните все поля.');
      return;
    }

    // ИСПРАВЛЕНО: используем ApiConfig вместо хардкода
    final String apiUrl = ApiConfig.login;

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({'email': email, 'password': password}),
      );
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        await _storage.write(key: 'jwt_token', value: responseData['token']);
        await _storage.write(key: 'user_name', value: responseData['name']);
        await _storage.write(key: 'user_email', value: email);
        await _storage.write(
          key: 'user_role',
          value: responseData['role'] ?? 'patient',
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        _showErrorDialog(responseData['message'] ?? 'Неверные данные');
      }
    } catch (e) {
      _showErrorDialog('Ошибка подключения к серверу: $e');
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('ОК'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController resetEmailController = TextEditingController();
    final TextEditingController resetCodeController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    bool isLoading = false;
    int _currentStep = 0; // 0 - для email, 1 - для кода и нового пароля
    String userEmail = ''; // Сохраним email для Шага 2

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // ИСПОЛЬЗУЕМ StateSetter ДЛЯ ОБНОВЛЕНИЯ ДИАЛОГА
        return StatefulBuilder(
          builder: (context, StateSetter setDialogState) {
            // --- Виджет для Шага 0 (Ввод Email) ---
            Widget _buildStep0() {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Введите email адрес, указанный при регистрации',
                    style: GoogleFonts.lato(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: resetEmailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'example@gmail.com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                  ),
                ],
              );
            }

            // --- Виджет для Шага 1 (Ввод Кода и Нового Пароля) ---
            Widget _buildStep1() {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Мы отправили код на $userEmail. Введите его и ваш новый пароль.',
                    style: GoogleFonts.lato(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: resetCodeController,
                    decoration: InputDecoration(
                      labelText: 'Код из письма',
                      hintText: '123456',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.pin_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Новый пароль',
                      hintText: '••••••••',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                    ),
                    obscureText: true,
                    enabled: !isLoading,
                  ),
                ],
              );
            }

            // --- Логика нажатия на главную кнопку ---
            void _handleSubmit() async {
              // Валидация
              if (_currentStep == 0) {
                userEmail = resetEmailController.text.trim();
                if (userEmail.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Пожалуйста, введите email'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
              } else {
                final code = resetCodeController.text.trim();
                final newPassword = newPasswordController.text.trim();
                if (code.isEmpty || newPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Пожалуйста, введите код и новый пароль'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
              }

              // ИСПОЛЬЗУЕМ 'setDialogState'
              setDialogState(() {
                isLoading = true;
              });

              try {
                if (_currentStep == 0) {
                  // --- ШАГ 0: Отправка Email ---
                  final response = await http.post(
                    Uri.parse(ApiConfig.forgotPassword),
                    headers: ApiConfig.defaultHeaders,
                    body: json.encode({'email': userEmail}),
                  );

                  if (response.statusCode == 200) {
                    // УСПЕХ! ПЕРЕХОДИМ НА ШАГ 1
                    setDialogState(() {
                      _currentStep = 1;
                      isLoading = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Инструкции отправлены на $userEmail',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    // Ошибка на Шаге 0
                    final data = json.decode(response.body);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          data['message'] ?? 'Ошибка',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    // ИСПРАВЛЕНО: Выключаем загрузку при ошибке
                    setDialogState(() {
                      isLoading = false;
                    });
                  }
                } else {
                  // --- ШАГ 1: Отправка Кода и Нового Пароля ---
                  final code = resetCodeController.text.trim();
                  final newPassword = newPasswordController.text.trim();

                  final response = await http.post(
                    Uri.parse(ApiConfig.resetPassword),
                    headers: ApiConfig.defaultHeaders,
                    body: json.encode({
                      'email': userEmail,
                      'code': code,
                      'newPassword': newPassword,
                    }),
                  );

                  if (response.statusCode == 200) {
                    // ВСЕ ГОТОВО!
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Пароль успешно сброшен! Теперь вы можете войти.',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 4),
                      ),
                    );
                    // Не нужен setDialogState, так как диалог закрывается
                  } else {
                    // Ошибка на Шаге 1
                    final data = json.decode(response.body);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          data['message'] ?? 'Неверный код или другая ошибка',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    // ИСПРАВЛЕНО: Выключаем загрузку при ошибке
                    setDialogState(() {
                      isLoading = false;
                    });
                  }
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка сети: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
                // ИСПРАВЛЕНО: Выключаем загрузку при ошибке
                setDialogState(() {
                  isLoading = false;
                });
              }
              // ИСПРАВЛЕНО: Блок 'finally' УДАЛЕН,
              // так как 'isLoading = false' теперь обрабатывается
              // в каждом блоке 'if/else' и 'catch'
            }

            // --- Сборка самого AlertDialog ---
            return AlertDialog(
              title: Text(
                'Восстановление пароля',
                style: GoogleFonts.lato(fontWeight: FontWeight.bold),
              ),
              content: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _currentStep == 0 ? _buildStep0() : _buildStep1(),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(
                    'Отмена',
                    style: TextStyle(
                      color: isLoading ? Colors.grey : Colors.grey[700],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: isLoading ? null : _handleSubmit,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _currentStep == 0 ? 'Отправить' : 'Сбросить пароль',
                          style: const TextStyle(color: Color(0xFF007BFF)),
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    resetEmailController.dispose();
    resetCodeController.dispose();
    newPasswordController.dispose();
  }

  InputDecoration _buildInputDecoration(
    String label,
    String hint, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38),
      filled: true,
      fillColor: const Color(0xFFF0F0F0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      suffixIcon: suffixIcon,
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF15A4C4), Color(0xFF33D4A3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildBackgroundDecoration(),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            children: <Widget>[
              const SizedBox(height: 50.0),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.show_chart,
                      color: Color(0xFF15A4C4),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'MedicHelp',
                    style: GoogleFonts.lato(
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ваш личный помощник здоровья',
                    style: GoogleFonts.lato(
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40.0),
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Вход',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        textStyle: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    TextField(
                      controller: _emailController,
                      decoration: _buildInputDecoration(
                        'Email',
                        'erkhan@gmail.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: _buildInputDecoration(
                        'Пароль',
                        '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: const Text(
                          'Забыли пароль?',
                          style: TextStyle(color: Color(0xFF007BFF)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007BFF),
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      onPressed: _loginUser,
                      child: const Text(
                        'Войти',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    const Text(
                      'Пациенты получают доступ от врача и могут использовать «Забыли пароль» для первого входа.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12.0),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/register');
                      },
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(color: Colors.black54, fontSize: 16),
                          children: [
                            TextSpan(text: 'Нужна учетная запись врача? '),
                            TextSpan(
                              text: 'Регистрация врача',
                              style: TextStyle(
                                color: Color(0xFF007BFF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Продолжая, вы соглашаетесь с условиями использования',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
