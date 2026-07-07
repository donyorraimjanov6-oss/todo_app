class FinanceModel {
  final String id;
  final double amount;
  final String description;
  final String date;

  FinanceModel({
    required this.id,
    required this.amount,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'description': description,
        'date': date,
      };

  factory FinanceModel.fromJson(Map<String, dynamic> json) => FinanceModel(
        id: json['id'].toString(),
        amount: (json['amount'] as num).toDouble(),
        description: json['description'] ?? '',
        date: json['date'] ?? '',
      );
}
