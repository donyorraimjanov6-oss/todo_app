import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  // 1. Гарантируем инициализацию виджетов перед асинхронным кодом
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Инициализируем Supabase строго здесь, в функции main()!
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
    // Безопасно получаем сессию текущего пользователя
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Todo App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Если пользователь вошел — открываем HomeScreen, иначе AuthScreen
      home: session != null ? const HomeScreen() : const AuthScreen(),
    );
  }
}
