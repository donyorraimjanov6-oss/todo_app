class TaskModel {
  String title;
  bool isDone;

  TaskModel({
    required this.title,
    this.isDone = false, // По умолчанию задача не выполнена
  });
}
