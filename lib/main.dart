import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/theme_service.dart'; // Новый импорт
import 'screens/main_navigation_screen.dart';

// Глобальный объект для управления темой на всех экранах
final themeService = ThemeService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://jcpldhrtgrzzzazwepjc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpjcGxkaHJ0Z3J6enphendlcGpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMyODA5MzksImV4cCI6MjA5ODg1NjkzOX0.02Yx-_OXOW0yWH-q11HcWfgifC1qihz-95SRpVBvfvE',
  );

  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    // ListenableBuilder заставляет приложение перестраиваться при смене темы
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Todo App',
          // Настраиваем две темы: светлую и темную
          themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
            useMaterial3: true,
          ),
          home: session != null ? const MainNavigationScreen() : const AuthScreen(),
        );
      },
    );
  }
}
