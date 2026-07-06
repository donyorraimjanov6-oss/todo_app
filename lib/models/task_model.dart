class TaskModel {
  String title;
  bool isDone;
  String folderName; // К какой папке относится задача

  TaskModel({
    required this.title,
    this.isDone = false,
    required this.folderName, // Обязательное поле
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'isDone': isDone,
        'folderName': folderName,
      };

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        title: json['title'],
        isDone: json['isDone'],
        folderName: json['folderName'] ?? 'Без папки', // Защита от старых данных
      );
}
