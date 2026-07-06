import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/folder_model.dart';
import '../models/task_model.dart';
import '../widgets/folder_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<FolderModel> _folders = [];
  List<TaskModel> _tasks = [];
  String? _selectedFolderName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Загрузка данных из памяти телефона при старте
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? foldersJson = prefs.getString('user_folders');
    final String? tasksJson = prefs.getString('user_tasks');

    setState(() {
      if (foldersJson != null) {
        final List<dynamic> decoded = jsonDecode(foldersJson);
        _folders = decoded.map((item) => FolderModel.fromJson(item)).toList();
      } else {
        _folders = [
          FolderModel(name: 'Работа', color: Colors.blue),
          FolderModel(name: 'Личное', color: Colors.green),
          FolderModel(name: 'Учеба', color: Colors.orange),
          FolderModel(name: 'Спорт', color: Colors.purple),
        ];
      }

      if (tasksJson != null) {
        final List<dynamic> decoded = jsonDecode(tasksJson);
        _tasks = decoded.map((item) => TaskModel.fromJson(item)).toList();
      }
    });
  }

  // Сохранение изменений в память
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final String foldersJson = jsonEncode(_folders.map((f) => f.toJson()).toList());
    final String tasksJson = jsonEncode(_tasks.map((t) => t.toJson()).toList());

    await prefs.setString('user_folders', foldersJson);
    await prefs.setString('user_tasks', tasksJson);
  }

  int _getUncompletedCount(String folderName) {
    return _tasks.where((task) => task.folderName == folderName && !task.isDone).length;
  }

  Color _getFolderColor(String folderName) {
    final folder = _folders.firstWhere(
      (f) => f.name == folderName,
      orElse: () => FolderModel(name: '', color: Colors.grey),
    );
    return folder.color;
  }

  void _addFolder(String name, Color color) {
    setState(() { _folders.add(FolderModel(name: name, color: color)); });
    _saveData();
  }

  void _deleteFolder(int index) {
    if (_selectedFolderName == _folders[index].name) _selectedFolderName = null;
    setState(() { _folders.removeAt(index); });
    _saveData();
  }

  void _addTask(String title, String folderName) {
    setState(() { _tasks.add(TaskModel(title: title, folderName: folderName)); });
    _saveData();
  }

  void _toggleTaskStatus(TaskModel task) {
    setState(() { task.isDone = !task.isDone; });
    _saveData();
  }

  void _deleteTask(TaskModel task) {
    setState(() { _tasks.remove(task); });
    _saveData();
  }
  // Всплывающее окно для новой папки
  void _showAddFolderDialog() {
    final TextEditingController controller = TextEditingController();
    Color selectedColor = Colors.red;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Создать папку'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Название папки'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _colorPickerCircle(Colors.red, (color) => selectedColor = color),
                  _colorPickerCircle(Colors.pink, (color) => selectedColor = color),
                  _colorPickerCircle(Colors.cyan, (color) => selectedColor = color),
                  _colorPickerCircle(Colors.amber, (color) => selectedColor = color),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  _addFolder(controller.text, selectedColor);
                  Navigator.pop(context);
                }
              },
              child: const Text('Создать'),
            ),
          ],
        );
      },
    );
  }

  Widget _colorPickerCircle(Color color, Function(Color) onSelect) {
    return GestureDetector(
      onTap: () => onSelect(color),
      child: CircleAvatar(backgroundColor: color, radius: 15),
    );
  }

  // Всплывающее окно для новой задачи
  void _showAddTaskDialog() {
    final TextEditingController taskController = TextEditingController();
    String selectedFolder = _folders.isNotEmpty ? _folders.first.name : 'Без папки';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Добавить новую задачу'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: taskController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Что нужно сделать?'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Выберите папку:'),
                      DropdownButton<String>(
                        value: selectedFolder,
                        items: _folders.isEmpty
                            ? [const DropdownMenuItem(value: 'Без папки', child: Text('Без папки'))]
                            : _folders.map((folder) {
                                return DropdownMenuItem<String>(
                                  value: folder.name,
                                  child: Text(folder.name),
                                );
                              }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setDialogState(() { selectedFolder = newValue; });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
                ElevatedButton(
                  onPressed: () {
                    if (taskController.text.isNotEmpty) {
                      _addTask(taskController.text, selectedFolder);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Добавить'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    // Фильтрация списка задач на лету
    final List<TaskModel> filteredTasks = _selectedFolderName == null
        ? _tasks
        : _tasks.where((task) => task.folderName == _selectedFolderName).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Мои Задачи'), centerTitle: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Блок папок сверху
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Папки', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _showAddFolderDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Папка'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 60,
            child: _folders.isEmpty
                ? const Center(child: Text('Нет папок. Добавьте первую!'))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _folders.length,
                    itemBuilder: (context, index) {
                      final folder = _folders[index];
                      final isSelected = _selectedFolderName == folder.name;
                      return FolderCard(
                        folder: folder,
                        taskCount: _getUncompletedCount(folder.name),
                        isSelected: isSelected,
                        onTap: () {
                          setState(() { _selectedFolderName = isSelected ? null : folder.name; });
                        },
                        onDelete: () => _deleteFolder(index),
                      );
                    },
                  ),
          ),
          // Блок заголовка задач
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedFolderName == null ? 'Все задачи' : 'Задачи: $_selectedFolderName',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (_selectedFolderName != null)
                  TextButton(
                    onPressed: () { setState(() { _selectedFolderName = null; }); },
                    child: const Text('Показать все'),
                  ),
              ],
            ),
          ),
          // Список цветных задач
          Expanded(
            child: filteredTasks.isEmpty
                ? const Center(child: Text('В этой категории нет задач', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      final taskColor = _getFolderColor(task.folderName);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: taskColor.withOpacity(0.5), width: 1.5),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: taskColor.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CheckboxListTile(
                            activeColor: taskColor,
                            checkColor: Colors.white,
                            title: Text(
                              task.title,
                              style: TextStyle(
                                decoration: task.isDone ? TextDecoration.lineThrough : TextDecoration.none,
                                color: task.isDone ? Colors.grey : taskColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('Папка: ${task.folderName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            value: task.isDone,
                            onChanged: (bool? value) { _toggleTaskStatus(task); },
                            secondary: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deleteTask(task),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      // Нижний плюс
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        tooltip: 'Добавить задачу',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}