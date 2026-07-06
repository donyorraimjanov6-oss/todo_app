import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Подключаем облако
import '../models/folder_model.dart';
import '../models/task_model.dart';

mixin HomeScreenLogic<T extends StatefulWidget> on State<T> {
  List<FolderModel> folders = [];
  List<TaskModel> tasks = [];
  String? selectedFolderName;

  // Создаем ссылку на клиент Supabase
  final _supabase = Supabase.instance.client;

  // ЗАГРУЗКА ДАННЫХ ИЗ ОБЛАКА SUPABASE
  Future<void> loadData() async {
    try {
      // Читаем папки и задачи параллельно
      final foldersData = await _supabase.from('folders').select();
      final tasksData = await _supabase.from('tasks').select();

      setState(() {
        // Конвертируем данные из облака в наши модели Flutter
        folders = (foldersData as List).map((item) => FolderModel.fromJson(item)).toList();
        tasks = (tasksData as List).map((item) => TaskModel.fromJson(item)).toList();

        // Если папок в облаке вообще нет (первый запуск), создаем стандартные
        if (folders.isEmpty) {
          _createDefaultFolders();
        }
      });
    } catch (e) {
      debugPrint('Ошибка загрузки данных из Supabase: $e');
    }
  }

  // Создание дефолтных папок, если база пуста
  void _createDefaultFolders() {
    final defaultFolders = [
      FolderModel(name: 'Работа', color: Colors.blue),
      FolderModel(name: 'Личное', color: Colors.green),
      FolderModel(name: 'Учеба', color: Colors.orange),
      FolderModel(name: 'Спорт', color: Colors.purple),
    ];
    for (var folder in defaultFolders) {
      addFolder(folder.name, folder.color);
    }
  }

  int getUncompletedCount(String folderName) {
    return tasks.where((task) => task.folderName == folderName && !task.isDone).length;
  }

  // ДОБАВЛЕНИЕ ПАПКИ В ОБЛАКО
  void addFolder(String name, Color color) async {
    final newFolder = FolderModel(name: name, color: color);
    setState(() {
      folders.add(newFolder);
    });

    // Отправляем запись в таблицу 'folders'
    await _supabase.from('folders').insert(newFolder.toJson());
  }

  // УДАЛЕНИЕ ПАПКИ ИЗ ОБЛАКА
  void deleteFolder(int index) async {
    final folderName = folders[index].name;
    if (selectedFolderName == folderName) {
      selectedFolderName = null;
    }

    setState(() {
      folders.removeAt(index);
      // Каскадно удаляем локальные задачи, привязанные к этой папке
      tasks.removeWhere((task) => task.folderName == folderName);
    });

    // Удаляем из облака саму папку и все её задачи по имени папки
    await _supabase.from('folders').delete().eq('name', folderName);
    await _supabase.from('tasks').delete().eq('folder_name', folderName);
  }

  // ДОБАВЛЕНИЕ ЗАДАЧИ В ОБЛАКО
  void addTask(String title, String folderName) async {
    final newTask = TaskModel(title: title, folderName: folderName);
    setState(() {
      tasks.add(newTask);
    });

    // Отправляем запись в таблицу 'tasks'
    await _supabase.from('tasks').insert(newTask.toJson());
  }

  // ИЗМЕНЕНИЕ СТАТУСА (ГАЛОЧКИ) В ОБЛАКЕ
  void toggleTaskStatus(TaskModel task) async {
    setState(() {
      task.isDone = !task.isDone;
    });

    // Обновляем статус задачи в облаке по её названию
    await _supabase.from('tasks').update({'is_done': task.isDone}).eq('title', task.title);
  }

  // УДАЛЕНИЕ ЗАДАЧИ ИЗ ОБЛАКА
  void deleteTask(TaskModel task) async {
    setState(() {
      tasks.remove(task);
    });

    // Удаляем из таблицы 'tasks' по названию задачи
    await _supabase.from('tasks').delete().eq('title', task.title);
  }
}
