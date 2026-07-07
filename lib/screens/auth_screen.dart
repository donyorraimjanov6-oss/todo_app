import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'main_navigation_screen.dart';


class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _supabase = Supabase.instance.client;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoginMode = true;
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'http://localhost:5000', 
      );
    } on AuthException catch (error) {
      _showSnackbar(error.message, Colors.red);
    } catch (error) {
      _showSnackbar('Ошибка подключения к Google', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAuth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackbar('Заполните все поля', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        await _supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await _supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        _showSnackbar('Регистрация успешна! Войдите в аккаунт.', Colors.green);
        setState(() => _isLoginMode = true);
        setState(() => _isLoading = false);
        return;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    } on AuthException catch (error) {
      _showSnackbar(error.message, Colors.red);
    } catch (error) {
      _showSnackbar('Ошибка авторизации', Colors.red);
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isLoginMode 
                ? [Colors.blue.shade800, Colors.purple.shade700] 
                : [Colors.purple.shade700, Colors.pink.shade700],
          ),
        ),
        // SingleChildScrollView защитит от жёлтой ошибки переполнения экрана
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isLoginMode ? Colors.blue.withOpacity(0.1) : Colors.pink.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isLoginMode ? Colors.blue.withOpacity(0.3) : Colors.pink.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isLoginMode ? Colors.blue.shade400 : Colors.pink.shade400,
                                width: 3,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _isLoginMode ? 0 : 1,
                            duration: const Duration(milliseconds: 500),
                            child: Icon(
                              _isLoginMode ? Icons.check_circle_outline : Icons.playlist_add_check,
                              size: 44,
                              color: _isLoginMode ? Colors.blue.shade700 : Colors.pink.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedCrossFade(
                      firstChild: const Text('Добро пожаловать', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                      secondChild: const Text('Создать аккаунт', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                      crossFadeState: _isLoginMode ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 300),
                    ),
                    const SizedBox(height: 32),

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
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
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
                    const SizedBox(height: 12),

                    // ИСПРАВЛЕНО: Заменили внешнюю картинку Google на красивую внутреннюю иконку G
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        icon: const Icon(Icons.g_mobiledata, size: 34, color: Colors.red),
                        label: const Text(
                          'Войти через Google',
                          style: TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () {
                        setState(() => _isLoginMode = !_isLoginMode);
                      },
                      child: AnimatedCrossFade(
                        firstChild: Text('Ещё нет аккаунта? Регистрация', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                        secondChild: Text('Уже есть аккаунт? Войти', style: TextStyle(color: Colors.pink.shade700, fontWeight: FontWeight.w600)),
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
