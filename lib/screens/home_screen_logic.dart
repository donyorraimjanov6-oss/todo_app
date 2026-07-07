import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/folder_model.dart';
import '../models/task_model.dart';

mixin HomeScreenLogic<T extends StatefulWidget> on State<T> {
  List<FolderModel> folders = [];
  List<TaskModel> tasks = [];
  String? selectedFolderName;
  DateTime selectedDate = DateTime.now();

  final _supabase = Supabase.instance.client;

  String get formattedSelectedDate => selectedDate.toString().split(' ')[0];

    // СВЕРХНАДЁЖНАЯ ЗАГРУЗКА ДАННЫХ
    Future<void> loadData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Сначала скачиваем данные в локальные временные переменные
      final foldersData = await _supabase.from('folders').select().eq('user_id', user.id);
      final tasksData = await _supabase.from('tasks').select().eq('user_id', user.id);

      if (!mounted) return;

      // 2. И только ПОСЛЕ успешного скачивания обновляем интерфейс экрана
      setState(() {
        folders = (foldersData as List).map((item) => FolderModel.fromJson(item)).toList();
        tasks = (tasksData as List).map((item) => TaskModel.fromJson(item)).toList();

        if (folders.isEmpty) {
          _createDefaultFolders();
        }
      });
    } catch (e) {
      debugPrint('Ошибка сети Supabase RLS: $e');
    }
  }
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
    return tasks.where((task) => 
      task.folderName == folderName && 
      !task.isDone && 
      task.date == formattedSelectedDate
    ).length;
  }
  // Добавление папки с привязкой к user_id
  void addFolder(String name, Color color) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final newFolder = FolderModel(name: name, color: color);
    setState(() { folders.add(newFolder); });

    final folderJson = newFolder.toJson();
    folderJson['user_id'] = user.id;

    await _supabase.from('folders').insert(folderJson);
  }

  // Удаление папки
  void deleteFolder(int index) async {
    final folderName = folders[index].name;
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    if (selectedFolderName == folderName) selectedFolderName = null;

    setState(() {
      folders.removeAt(index);
      tasks.removeWhere((task) => task.folderName == folderName);
    });

    await _supabase.from('folders').delete().eq('name', folderName).eq('user_id', user.id);
    await _supabase.from('tasks').delete().eq('folder_name', folderName).eq('user_id', user.id);
  }

  // Добавление задачи с привязкой к user_id
  void addTask(String title, String folderName) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final newTask = TaskModel(title: title, folderName: folderName, date: formattedSelectedDate);
    setState(() { tasks.add(newTask); });

    final taskJson = newTask.toJson();
    taskJson['user_id'] = user.id;

    await _supabase.from('tasks').insert(taskJson);
  }

  // Изменение статуса галочки
  void toggleTaskStatus(TaskModel task) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() { task.isDone = !task.isDone; });
    await _supabase.from('tasks').update({'is_done': task.isDone}).eq('title', task.title).eq('user_id', user.id);
  }

  // Удаление задачи (ИСПРАВЛЕНО!)
  void deleteTask(TaskModel task) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() {
      tasks.remove(task); // Локально удаляем задачу из списка
    });

    // Удаляем задачу из облака Supabase строго по её названию и ID владельца
    await _supabase.from('tasks').delete().eq('title', task.title).eq('user_id', user.id);
  }
}
