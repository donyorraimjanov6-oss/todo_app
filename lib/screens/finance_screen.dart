import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/finance_model.dart';
import '../services/notification_service.dart'; // Импорт службы уведомлений

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final _supabase = Supabase.instance.client;
  final List<FinanceModel> _allIncomes = [];
  bool _isLoading = true;
  String? _currentMode; 
  
  int _selectedMonth = DateTime.now().month;
  DateTime _selectedDailyDate = DateTime.now();

  bool _showSalary = true;
  bool _showAdvance = true;
  String _selectedStrategy = '50/30/20';

  // === ТЕГИ ДЛЯ СХЕМЫ 50/30/20 ===
  String _tag50_1 = 'Жизнь (50%)'; String _tag50_2 = 'Долги (30%)'; String _tag50_3 = 'Инвест (20%)';
  final List<String> _list50_1 = ['Жизнь (50%)', 'Аренда & Еда', 'Обязательное', 'Быт & Счета'];
  final List<String> _list50_2 = ['Долги (30%)', 'Кредиты', 'Ипотека', 'Крупная цель', 'Автомобиль'];
  final List<String> _list50_3 = ['Инвест (20%)', 'Копилка', 'Подушка Б.', 'Акции / Крипта'];

  // === ТЕГИ ДЛЯ МЕТОДА 4 КОНВЕРТОВ ===
  String _tagConv1 = 'Копилка (10%)'; String _tagConv2 = 'На 1 неделю'; String _tagConv3 = 'Всего 4 конверта';
  final List<String> _listConv1 = ['Копилка (10%)', 'НЗ фонд', 'Инвестиции', 'Депозит'];
  final List<String> _listConv2 = ['На 1 неделю', 'Бюджет на 7 дней', 'Карманные'];
  final List<String> _listConv3 = ['Всего 4 конверта', 'Остаток на месяц', 'Сумма в конверты'];

  // === ТЕГИ ДЛЯ СХЕМЫ 60/10*4 ===
  String _tag60_1 = 'Главное (60%)'; String _tag60_2 = 'Пенсия (10%)'; String _tag60_3 = 'Покупки (10%)'; String _tag60_4 = 'Развлечения (10%)'; String _tag60_5 = 'Благо (10%)';
  final List<String> _list60_1 = ['Главное (60%)', 'Базовые траты', 'Основные расходы'];
  final List<String> _list60_2 = ['Пенсия (10%)', 'Капитал', 'Будущее', 'Капитал на старость'];
  final List<String> _list60_3 = ['Покупки (10%)', 'Фонд одежды', 'Техника', 'Целевые накопления'];
  final List<String> _list60_4 = ['Развлечения (10%)', 'Кафе & Кино', 'Отдых & Хобби', 'Подарки'];
  final List<String> _list60_5 = ['Благо (10%)', 'Помощь близким', 'Благотворительность', 'Подарки друзьям'];

  // === ТЕГИ ДЛЯ СХЕМЫ ПЛАТИ СЕБЕ ===
  String _tagPay1 = 'Себе (15%)'; String _tagPay2 = 'Остальные траты (85%)';
  final List<String> _listPay1 = ['Себе (15%)', 'Мой капитал', 'Плачу себе сначала', 'Сбережения'];
  final List<String> _listPay2 = ['Остальные траты (85%)', 'Свободный бюджет', 'На жизнь'];

  // === ТЕГИ ДЛЯ НУЛЕВОГО БЮДЖЕТА ===
  String _tagZero1 = 'Продукты'; String _tagZero2 = 'Жилье'; String _tagZero3 = 'Свободно (0 ₽)';
  final List<String> _listZero1 = ['Продукты', 'Супермаркеты', 'Еда вне дома', 'Питание'];
  final List<String> _listZero2 = ['Жилье', 'Коммуналка', 'Ипотека / Аренда', 'Ремонт'];
  final List<String> _listZero3 = ['Свободно (0 ₽)', 'Прочие расходы', 'Карманные деньги'];

  @override
  void initState() {
    super.initState();
    _loadLocalFinanceData(); 
  }

  String _getFormattedDate(DateTime dt) => dt.toString().split(' ')[0];
  // Загружаем данные из внутренней памяти смартфона
  Future<void> _loadLocalFinanceData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? localData = prefs.getString('local_finances');
    if (!mounted) return;
    setState(() {
      _allIncomes.clear();
      if (localData != null) {
        final List<dynamic> decoded = jsonDecode(localData);
        _allIncomes.addAll(decoded.map((item) => FinanceModel.fromJson(item)).toList());
      }
      _isLoading = false;
    });
  }

  // Записываем обновленный список в память телефона
  Future<void> _saveLocalFinanceData() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_allIncomes.map((i) => i.toJson()).toList());
    await prefs.setString('local_finances', encoded);
  }

  // Добавление новой записи в локальный массив + отложенный пуш
  Future<void> _addIncome({
    required double amount,
    required String description,
    required String type,
    required String source,
    required String date,
  }) async {
    final parsedDate = DateTime.parse(date);
    final newIncome = FinanceModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(), 
      amount: amount,
      description: description,
      date: date,
      type: type,
      incomeSource: source,
      monthIndex: parsedDate.month,
    );
    setState(() { _allIncomes.insert(0, newIncome); });
    await _saveLocalFinanceData();

    // Запускаем отложенное пуш-уведомление строго через 5 секунд!
    NotificationService.showScheduledNotification(
      id: 2,
      title: '⏳ Бюджет обновлен!',
      body: 'Внесено $amount ₽. Проверьте схемы распределения.',
      secondsDelay: 5,
    );
  }

  // Локальное удаление строки
  Future<void> _deleteIncome(String id) async {
    setState(() { _allIncomes.removeWhere((item) => item.id == id); });
    await _saveLocalFinanceData();
  }
  // Диалоговое окно для смены тегов на карточке из фиксированного списка
  void _showChangeTagDialog(String currentTag, List<String> allowedTags, Function(String) onSelected) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите название тега'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: allowedTags.map((tag) {
            return RadioListTile<String>(
              title: Text(tag),
              value: tag,
              groupValue: currentTag,
              onChanged: (val) {
                if (val != null) {
                  setState(() { onSelected(val); });
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // Окно для ввода суммы, зарплаты или аванса
  void _showAddIncomeDialog() {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String monthlySource = 'salary'; 

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(_currentMode == 'daily' ? 'Доход на ${_getFormattedDate(_selectedDailyDate)}' : 'Добавить месячный доход'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Сумма (₽)'),
                ),
                const SizedBox(height: 12),
                if (_currentMode == 'daily')
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Источник (например, Фриланс)'),
                  ),
                if (_currentMode == 'monthly') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Тип выплаты:'),
                      DropdownButton<String>(
                        value: monthlySource,
                        items: const [
                          DropdownMenuItem(value: 'salary', child: Text('Зарплата')),
                          DropdownMenuItem(value: 'advance', child: Text('Аванс')),
                        ],
                        onChanged: (val) { if (val != null) setDialogState(() => monthlySource = val); },
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
              ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text) ?? 0;
                  if (amount > 0) {
                    _addIncome(
                      amount: amount,
                      description: _currentMode == 'daily' ? descController.text : (monthlySource == 'salary' ? 'Зарплата' : 'Аванс'),
                      type: _currentMode!,
                      source: _currentMode == 'daily' ? 'other' : monthlySource,
                      date: _currentMode == 'daily' ? _getFormattedDate(_selectedDailyDate) : _getFormattedDate(DateTime.now()),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Добавить'),
              ),
            ],
          );
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final List<String> monthsNames = ['Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'];

    if (_currentMode == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Мой Капитал', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Выберите тип учета доходов:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(minimumSize: const Size(250, 60), backgroundColor: Colors.blue, foregroundColor: Colors.white),
                icon: const Icon(Icons.calendar_today),
                label: const Text('Дневной доход (с календарем)', style: TextStyle(fontSize: 16)),
                onPressed: () => setState(() => _currentMode = 'daily'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(minimumSize: const Size(250, 60), backgroundColor: Colors.green, foregroundColor: Colors.white),
                icon: const Icon(Icons.payments),
                label: const Text('Месячный доход (ЗП / Аванс)', style: TextStyle(fontSize: 16)),
                onPressed: () => setState(() => _currentMode = 'monthly'),
              ),
            ],
          ),
        ),
      );
    }

    List<FinanceModel> filteredList = [];
    double totalCalculatedSum = 0.0;

    if (_currentMode == 'daily') {
      filteredList = _allIncomes.where((i) => i.type == 'daily' && i.date == _getFormattedDate(_selectedDailyDate)).toList();
      for (var item in filteredList) { totalCalculatedSum += item.amount; }
    } else {
      filteredList = _allIncomes.where((i) {
        if (i.type != 'monthly' || i.monthIndex != _selectedMonth) return false;
        if (i.incomeSource == 'salary' && !_showSalary) return false;
        if (i.incomeSource == 'advance' && !_showAdvance) return false;
        return true;
      }).toList();
      for (var item in filteredList) { totalCalculatedSum += item.amount; }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentMode == 'daily' ? 'Дневной учет' : 'Месячный учет', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _currentMode = null), 
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ЛЕНТА ИЗ 12 МЕСЯЦЕВ (Включается для месячного режима)
                if (_currentMode == 'monthly') ...[
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final monthNum = index + 1;
                        final isSelected = _selectedMonth == monthNum;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedMonth = monthNum),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue : Colors.blue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                monthsNames[index],
                                style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FilterChip(
                          label: const Text('Зарплата'),
                          selected: _showSalary,
                          onSelected: (val) => setState(() => _showSalary = val),
                        ),
                        FilterChip(
                          label: const Text('Аванс'),
                          selected: _showAdvance,
                          onSelected: (val) => setState(() => _showAdvance = val),
                        ),
                      ],
                    ),
                  ),
                ],

                // ПОЛНОЦЕННЫЙ РАСКРЫВАЮЩИЙСЯ КАЛЕНДАРЬ (Для дневного режима)
                if (_currentMode == 'daily') ...[
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.blue.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.calendar_month, color: Colors.blue),
                      title: Text('Выбранный день: ${_getFormattedDate(_selectedDailyDate)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Нажмите для раскрытия календаря'),
                      trailing: const Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.blue),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDailyDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          helpText: 'ВЫБЕРИТЕ ДЕНЬ УЧЕТА',
                        );
                        if (picked != null) setState(() { _selectedDailyDate = picked; });
                      },
                    ),
                  ),
                ],
                Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(_currentMode == 'daily' ? 'Доход за выбранный день' : 'Капитал за месяц', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${totalCalculatedSum.toStringAsFixed(0)} ₽', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 30, color: Colors.green),
                              onPressed: _showAddIncomeDialog, 
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Схема бюджета:', style: TextStyle(fontWeight: FontWeight.bold)),
                            DropdownButton<String>(
                              value: _selectedStrategy,
                              items: const [
                                DropdownMenuItem(value: '50/30/20', child: Text('Схема 50/30/20')),
                                DropdownMenuItem(value: '4 Конверта', child: Text('Метод 4 конвертов')),
                                DropdownMenuItem(value: '60/10*4', child: Text('Схема 60/10/10/10/10')),
                                DropdownMenuItem(value: 'Плати себе', child: Text('Сначала плати себе')),
                                DropdownMenuItem(value: 'Нулевой', child: Text('Нулевой бюджет')),
                              ],
                              onChanged: (val) { if (val != null) setState(() { _selectedStrategy = val; }); },
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        
                        _buildCalculatedBudget(totalCalculatedSum),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: filteredList.isEmpty
                      ? const Center(child: Text('Нет записей доходов по выбранным фильтрам', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            return ListTile(
                              leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.arrow_upward, color: Colors.green)),
                              title: Text(item.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(item.date),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('+ ${item.amount.toStringAsFixed(0)} ₽', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _deleteIncome(item.id)),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    ); 
  }

  Widget _buildCalculatedBudget(double total) {
    if (_selectedStrategy == '50/30/20') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildClickableStat(_tag50_1, total * 0.5, Colors.blue, () {
            _showChangeTagDialog(_tag50_1, _list50_1, (nv) => _tag50_1 = nv);
          }),
          _buildClickableStat(_tag50_2, total * 0.3, Colors.orange, () {
            _showChangeTagDialog(_tag50_2, _list50_2, (nv) => _tag50_2 = nv);
          }),
          _buildClickableStat(_tag50_3, total * 0.2, Colors.purple, () {
            _showChangeTagDialog(_tag50_3, _list50_3, (nv) => _tag50_3 = nv);
          }),
        ],
      );
    } else if (_selectedStrategy == '4 Конверта') {
      double invest = total * 0.10; double rest = total - invest;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildClickableStat(_tagConv1, invest, Colors.purple, () {
            _showChangeTagDialog(_tagConv1, _listConv1, (nv) => _tagConv1 = nv);
          }),
          _buildClickableStat(_tagConv2, rest / 4, Colors.blue, () {
            _showChangeTagDialog(_tagConv2, _listConv2, (nv) => _tagConv2 = nv);
          }),
          _buildClickableStat(_tagConv3, rest, Colors.green, () {
            _showChangeTagDialog(_tagConv3, _listConv3, (nv) => _tagConv3 = nv);
          }),
        ],
      );
    } else if (_selectedStrategy == '60/10*4') {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildClickableStat(_tag60_1, total * 0.6, Colors.blue, () { _showChangeTagDialog(_tag60_1, _list60_1, (nv) => _tag60_1 = nv); }),
              _buildClickableStat(_tag60_2, total * 0.1, Colors.purple, () { _showChangeTagDialog(_tag60_2, _list60_2, (nv) => _tag60_2 = nv); }),
              _buildClickableStat(_tag60_3, total * 0.1, Colors.orange, () { _showChangeTagDialog(_tag60_3, _list60_3, (nv) => _tag60_3 = nv); }),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildClickableStat(_tag60_4, total * 0.1, Colors.pink, () { _showChangeTagDialog(_tag60_4, _list60_4, (nv) => _tag60_4 = nv); }),
              _buildClickableStat(_tag60_5, total * 0.1, Colors.teal, () { _showChangeTagDialog(_tag60_5, _list60_5, (nv) => _tag60_5 = nv); }),
            ],
          )
        ],
      );
    } else if (_selectedStrategy == 'Плати себе') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildClickableStat(_tagPay1, total * 0.15, Colors.purple, () { _showChangeTagDialog(_tagPay1, _listPay1, (nv) => _tagPay1 = nv); }),
          _buildClickableStat(_tagPay2, total * 0.85, Colors.blue, () { _showChangeTagDialog(_tagPay2, _listPay2, (nv) => _tagPay2 = nv); }),
        ],
      );
    } else if (_selectedStrategy == 'Нулевой') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildClickableStat(_tagZero1, total * 0.4, Colors.blue, () { _showChangeTagDialog(_tagZero1, _listZero1, (nv) => _tagZero1 = nv); }),
          _buildClickableStat(_tagZero2, total * 0.4, Colors.teal, () { _showChangeTagDialog(_tagZero2, _listZero2, (nv) => _tagZero2 = nv); }),
          _buildClickableStat(_tagZero3, total * 0.2, Colors.grey, () { _showChangeTagDialog(_tagZero3, _listZero3, (nv) => _tagZero3 = nv); }),
        ],
      );
    }
    return const SizedBox(); 
  }

  Widget _buildClickableStat(String label, double value, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, decoration: TextDecoration.underline)),
                const SizedBox(width: 2),
                const Icon(Icons.edit, size: 10, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 4),
            Text('${value.toStringAsFixed(0)} ₽', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
