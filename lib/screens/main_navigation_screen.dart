import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'finance_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Порядок экранов должен строго совпадать с кнопками внизу!
  final List<Widget> _screens = [
    const HomeScreen(),       // Индекс 0 — Экран Задач
    const FinanceScreen(),    // Индекс 1 — Экран Капитала
    const SettingsScreen(),   // Индекс 2 — Экран Настроек
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens, 
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Принудительно меняем индекс экрана при клике на иконку
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        // Обязательно три иконки, строго в том же порядке!
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline), 
            label: 'Задачи',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined), 
            label: 'Капитал',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined), 
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}
