class FinanceModel {
  final String id;
  final double amount;
  final String description;
  final String date;        // 'YYYY-MM-DD'
  final String type;        // 'daily' (дневной) или 'monthly' (месячный)
  final String incomeSource; // 'salary' (зарплата), 'advance' (аванс) или 'other'
  final int monthIndex;     // 1-12 (для фильтрации по месяцам)

  FinanceModel({
    required this.id,
    required this.amount,
    required this.description,
    required this.date,
    required this.type,
    required this.incomeSource,
    required this.monthIndex,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'description': description,
        'date': date,
        'type': type,
        'income_source': incomeSource,
        'month_index': monthIndex,
      };

  factory FinanceModel.fromJson(Map<String, dynamic> json) => FinanceModel(
        id: json['id'].toString(),
        amount: (json['amount'] as num).toDouble(),
        description: json['description'] ?? '',
        date: json['date'] ?? '',
        type: json['type'] ?? 'daily',
        incomeSource: json['income_source'] ?? 'other',
        monthIndex: json['month_index'] ?? DateTime.now().month,
      );
}
