import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _supabase = Supabase.instance.client;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoginMode = true; // Переключатель: true - Вход, false - Регистрация
  bool _isLoading = false;

  // Функция для входа или регистрации через Supabase Auth
  Future<void> _handleAuth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackbar('Заполните все поля', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        // Логика Входа
        await _supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // Логика Регистрации
        await _supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        _showSnackbar('Регистрация успешна! Проверьте вашу почту.', Colors.green);
        setState(() => _isLoginMode = true);
        setState(() => _isLoading = false);
        return;
      }

      // Если вход успешен, переходим на главный экран задач
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on AuthException catch (error) {
      _showSnackbar(error.message, Colors.red);
    } catch (error) {
      _showSnackbar('Произошла непредвиденная ошибка', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Красивый анимируемый фоновый градиент
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isLoginMode 
                ? [Colors.blue.shade800, Colors.purple.shade700] 
                : [Colors.purple.shade700, Colors.pink.shade700],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                width: 400,
                // Высота карточки мягко подстраивается под контент при смене режима
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Иконка с плавной анимацией поворота/масштаба
                    AnimatedRotation(
                      turns: _isLoginMode ? 0 : 0.5,
                      duration: const Duration(milliseconds: 500),
                      child: Icon(
                        _isLoginMode ? Icons.lock_outline : Icons.person_add_outlined,
                        size: 64,
                        color: _isLoginMode ? Colors.blue.shade700 : Colors.pink.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Плавная анимация текста заголовка
                    AnimatedCrossFade(
                      firstChild: const Text(
                        'Добро пожаловать',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      secondChild: const Text(
                        'Создать аккаунт',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      crossFadeState: _isLoginMode ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 300),
                    ),
                    const SizedBox(height: 32),

                    // Поля ввода
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        prefixIcon: const Icon(Icons.lock_open_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Главная кнопка с индикатором загрузки
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleAuth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLoginMode ? Colors.blue.shade700 : Colors.pink.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : AnimatedCrossFade(
                                firstChild: const Text('Войти', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                secondChild: const Text('Зарегистрироваться', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                crossFadeState: _isLoginMode ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                                duration: const Duration(milliseconds: 200),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Переключатель режимов Вход / Регистрация
                    TextButton(
                      onPressed: () {
                        setState(() => _isLoginMode = !_isLoginMode);
                      },
                      child: AnimatedCrossFade(
                        firstChild: Text(
                          'Ещё нет аккаунта? Регистрация',
                          style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600),
                        ),
                        secondChild: Text(
                          'Уже есть аккаунт? Войти',
                          style: TextStyle(color: Colors.pink.shade700, fontWeight: FontWeight.w600),
                        ),
                        crossFadeState: _isLoginMode ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 300),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
