import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/finance_model.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final _supabase = Supabase.instance.client;
  final List<FinanceModel> _incomes = [];
  bool _isLoading = true;
  double _totalIncome = 0.0;
  
  String _selectedStrategy = '50/30/20';

  // === ТЕГИ ДЛЯ СХЕМЫ 50/30/20 ===
  String _tag50_1 = 'Жизнь (50%)';
  String _tag50_2 = 'Долги (30%)';
  String _tag50_3 = 'Инвест (20%)';
  final List<String> _list50_1 = ['Жизнь (50%)', 'Аренда & Еда', 'Обязательное', 'Быт & Счета'];
  final List<String> _list50_2 = ['Долги (30%)', 'Кредиты', 'Ипотека', 'Крупная цель', 'Автомобиль'];
  final List<String> _list50_3 = ['Инвест (20%)', 'Копилка', 'Подушка Б.', 'Акции / Крипта'];

  // === ТЕГИ ДЛЯ МЕТОДА 4 КОНВЕРТОВ ===
  String _tagConv1 = 'Копилка (10%)';
  String _tagConv2 = 'На 1 неделю';
  String _tagConv3 = 'Всего 4 конверта';
  final List<String> _listConv1 = ['Копилка (10%)', 'НЗ фонд', 'Инвестиции', 'Депозит'];
  final List<String> _listConv2 = ['На 1 неделю', 'Бюджет на 7 дней', 'Карманные'];
  final List<String> _listConv3 = ['Всего 4 конверта', 'Остаток на месяц', 'Сумма в конверты'];

  // === ТЕГИ ДЛЯ СХЕМЫ 60/10*4 ===
  String _tag60_1 = 'Главное (60%)';
  String _tag60_2 = 'Пенсия (10%)';
  String _tag60_3 = 'Покупки (10%)';
  String _tag60_4 = 'Развлечения (10%)';
  String _tag60_5 = 'Благо (10%)';
  final List<String> _list60_1 = ['Главное (60%)', 'Базовые траты', 'Основные расходы'];
  final List<String> _list60_2 = ['Пенсия (10%)', 'Капитал', 'Будущее', 'Капитал на старость'];
  final List<String> _list60_3 = ['Покупки (10%)', 'Фонд одежды', 'Техника', 'Целевые накопления'];
  final List<String> _list60_4 = ['Развлечения (10%)', 'Кафе & Кино', 'Отдых & Хобби', 'Подарки'];
  final List<String> _list60_5 = ['Благо (10%)', 'Помощь близким', 'Благотворительность', 'Подарки друзьям'];

  // === ТЕГИ ДЛЯ СХЕМЫ ПЛАТИ СЕБЕ ===
  String _tagPay1 = 'Себе (15%)';
  String _tagPay2 = 'Остальные траты (85%)';
  final List<String> _listPay1 = ['Себе (15%)', 'Мой капитал', 'Плачу себе сначала', 'Сбережения'];
  final List<String> _listPay2 = ['Остальные траты (85%)', 'Свободный бюджет', 'На жизнь'];

  // === ТЕГИ ДЛЯ НУЛЕВОГО БЮДЖЕТА ===
  String _tagZero1 = 'Продукты';
  String _tagZero2 = 'Жилье';
  String _tagZero3 = 'Свободно (0 ₽)';
  final List<String> _listZero1 = ['Продукты', 'Супермаркеты', 'Еда вне дома', 'Питание'];
  final List<String> _listZero2 = ['Жилье', 'Коммуналка', 'Ипотека / Аренда', 'Ремонт'];
  final List<String> _listZero3 = ['Свободно (0 ₽)', 'Прочие расходы', 'Карманные деньги'];

  @override
  void initState() {
    super.initState();
    _loadFinanceData();
  }

  Future<void> _loadFinanceData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _supabase.from('finances').select().eq('user_id', user.id).order('date', ascending: false);
      if (!mounted) return;

      setState(() {
        _incomes.clear();
        _totalIncome = 0.0;
        for (var item in data) {
          final income = FinanceModel.fromJson(item);
          _incomes.add(income);
          _totalIncome += income.amount;
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки финансов: $e');
    }
  }

  Future<void> _addIncome(double amount, String description) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final newIncome = FinanceModel(
      id: '',
      amount: amount,
      description: description,
      date: DateTime.now().toString().split(' ')[0], // Исправленная ошибка строки
    );

    final json = newIncome.toJson();
    json['user_id'] = user.id;

    await _supabase.from('finances').insert(json);
    _loadFinanceData(); 
  }

  Future<void> _deleteIncome(String id) async {
    await _supabase.from('finances').delete().eq('id', id);
    _loadFinanceData();
  }

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
              onChanged: (String? value) {
                if (value != null) {
                  setState(() { onSelected(value); });
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAddIncomeDialog() {
    final amountController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить доход'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Сумма дохода (руб.)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Источник (например, Зарплата)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0 && descController.text.isNotEmpty) {
                _addIncome(amount, descController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой Капитал', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text('Общий капитал', style: TextStyle(fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text('${_totalIncome.toStringAsFixed(0)} ₽', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
                        const SizedBox(height: 16),
                        
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
                              onChanged: (String? value) {
                                if (value != null) {
                                  setState(() { _selectedStrategy = value; });
                                }
                              },
                            ),
                          ],
                        ),
                        const Divider(height: 30),
                        
                        _buildCalculatedBudget(),
                      ],
                    ),
                  ),
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('История доходов', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                
                Expanded(
                  child: _incomes.isEmpty
                      ? const Center(child: Text('Вы ещё не добавили ни одного дохода', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: _incomes.length,
                          itemBuilder: (context, index) {
                            final item = _incomes[index];
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFE8F5E9),
                                child: Icon(Icons.arrow_upward, color: Colors.green),
                              ),
                              title: Text(item.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(item.date),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('+ ${item.amount.toStringAsFixed(0)} ₽', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () => _deleteIncome(item.id),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddIncomeDialog,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_card),
      ),
    );
  }

  Widget _buildCalculatedBudget() {
    if (_selectedStrategy == '50/30/20') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildClickableStat(_tag50_1, _totalIncome * 0.5, Colors.blue, () {
            _showChangeTagDialog(_tag50_1, _list50_1, (newVal) => _tag50_1 = newVal);
          }),
          _buildClickableStat(_tag50_2, _totalIncome * 0.3, Colors.orange, () {
            _showChangeTagDialog(_tag50_2, _list50_2, (newVal) => _tag50_2 = newVal);
          }),
          _buildClickableStat(_tag50_3, _totalIncome * 0.2, Colors.purple, () {
            _showChangeTagDialog(_tag50_3, _list50_3, (newVal) => _tag50_3 = newVal);
          }),
        ],
      );
    } else if (_selectedStrategy == '4 Конверта') {
      double invest = _totalIncome * 0.10;
      double rest = _totalIncome - invest;
      double perEnvelope = rest / 4;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildClickableStat(_tagConv1, invest, Colors.purple, () {
            _showChangeTagDialog(_tagConv1, _listConv1, (newVal) => _tagConv1 = newVal);
          }),
          _buildClickableStat(_tagConv2, perEnvelope, Colors.blue, () {
            _showChangeTagDialog(_tagConv2, _listConv2, (newVal) => _tagConv2 = newVal);
          }),
          _buildClickableStat(_tagConv3, rest, Colors.green, () {
            _showChangeTagDialog(_tagConv3, _listConv3, (newVal) => _tagConv3 = newVal);
          }),
        ],
      );
    } else if (_selectedStrategy == '60/10*4') {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildClickableStat(_tag60_1, _totalIncome * 0.6, Colors.blue, () {
                _showChangeTagDialog(_tag60_1, _list60_1, (newVal) => _tag60_1 = newVal);
              }),
              _buildClickableStat(_tag60_2, _totalIncome * 0.1, Colors.purple, () {
                _showChangeTagDialog(_tag60_2, _list60_2, (newVal) => _tag60_2 = newVal);
              }),
              _buildClickableStat(_tag60_3, _totalIncome * 0.1, Colors.orange, () {
                _showChangeTagDialog(_tag60_3, _list60_3, (newVal) => _tag60_3 = newVal);
              }),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildClickableStat(_tag60_4, _totalIncome * 0.1, Colors.pink, () {
                _showChangeTagDialog(_tag60_4, _list60_4, (newVal) => _tag60_4 = newVal);
              }),
              _buildClickableStat(_tag60_5, _totalIncome * 0.1, Colors.teal, () {
                _showChangeTagDialog(_tag60_5, _list60_5, (newVal) => _tag60_5 = newVal);
              }),
            ],
          )
        ],
      );
    } else if (_selectedStrategy == 'Плати себе') {
      double payMyself = _totalIncome * 0.15;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildClickableStat(_tagPay1, payMyself, Colors.purple, () {
            _showChangeTagDialog(_tagPay1, _listPay1, (newVal) => _tagPay1 = newVal);
          }),
          _buildClickableStat(_tagPay2, _totalIncome * 0.85, Colors.blue, () {
            _showChangeTagDialog(_tagPay2, _listPay2, (newVal) => _tagPay2 = newVal);
          }),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildClickableStat(_tagZero1, _totalIncome * 0.4, Colors.blue, () {
            _showChangeTagDialog(_tagZero1, _listZero1, (newVal) => _tagZero1 = newVal);
          }),
          _buildClickableStat(_tagZero2, _totalIncome * 0.4, Colors.teal, () {
            _showChangeTagDialog(_tagZero2, _listZero2, (newVal) => _tagZero2 = newVal);
          }),
          _buildClickableStat(_tagZero3, _totalIncome * 0.2, Colors.grey, () {
            _showChangeTagDialog(_tagZero3, _listZero3, (newVal) => _tagZero3 = newVal);
          }),
        ],
      );
    }
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
