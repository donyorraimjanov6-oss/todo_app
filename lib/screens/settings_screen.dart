import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // Импортируем наш глобальный themeService
import 'auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isClearing = false;

  Future<void> _logout() async {
    try {
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      _showSnackbar('Ошибка при выходе из аккаунта', Colors.red);
    }
  }

  Future<void> _clearAllTasks() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isClearing = true);
    try {
      await _supabase.from('tasks').delete().eq('user_id', user.id);
      _showSnackbar('Все задачи успешно удалены!', Colors.green);
    } catch (e) {
      _showSnackbar('Ошибка при удалении задач', Colors.red);
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _confirmClearTasks() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить списки?'),
        content: const Text('Это действие безвозвратно удалит абсолютно все ваши задачи из облака Supabase.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _clearAllTasks();
            },
            child: const Text('Удалить все'),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final userEmail = user?.email ?? 'Гость';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель управления', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(Icons.person, size: 36, color: Colors.blue.shade700),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Активный аккаунт',
                          style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Text('Внешний вид', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),

          // === НОВЫЙ БЛОК: ТУМБЛЕР ТЁМНОЙ ТЕМЫ ===
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListenableBuilder(
              listenable: themeService,
              builder: (context, child) {
                return SwitchListTile(
                  secondary: Icon(
                    themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: themeService.isDarkMode ? Colors.amber : Colors.blue,
                  ),
                  title: const Text('Тёмная тема', style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('Комфортный режим для глаз'),
                  value: themeService.isDarkMode,
                  onChanged: (bool value) {
                    themeService.toggleTheme(value); // Меняем тему
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Text('Настройки данных', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: _isClearing 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.delete_sweep, color: Colors.red),
              title: const Text('Очистить все задачи', style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: const Text('Стереть историю дел из облака'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _isClearing ? null : _confirmClearTasks,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.orange),
              title: const Text('Выйти из аккаунта', style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: const Text('Завершить текущую сессию'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _logout,
            ),
          ),
        ],
      ),
    );
  }
}
