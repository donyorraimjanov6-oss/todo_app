class TaskModel {
  String title;
  bool isDone;
  String folderName;
  String date; // Новое поле: дата задачи в формате '2026-07-06'

  TaskModel({
    required this.title,
    this.isDone = false,
    required this.folderName,
    required this.date, // Сделайте обязательным
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'isDone': isDone,
        'folderName': folderName,
        'date': date,
      };

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        title: json['title'],
        isDone: json['isDone'],
        folderName: json['folderName'] ?? 'Без папки',
        date: json['date'] ?? DateTime.now().toString().split(' ')[0], // Защита от старых данных
      );
}
