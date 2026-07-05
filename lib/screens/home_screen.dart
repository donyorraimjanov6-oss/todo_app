import 'package:flutter/material.dart';
import '../models/folder_model.dart';
import '../models/task_model.dart'; // Новый импорт
import '../widgets/folder_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<FolderModel> _folders = [
    FolderModel(name: 'Работа', color: Colors.blue),
    FolderModel(name: 'Личное', color: Colors.green),
    FolderModel(name: 'Учеба', color: Colors.orange),
    FolderModel(name: 'Спорт', color: Colors.purple),
  ];

  // Новый динамический список для хранения задач
  final List<TaskModel> _tasks = [];

  void _addFolder(String name, Color color) {
    setState(() {
      _folders.add(FolderModel(name: name, color: color));
    });
  }

  void _deleteFolder(int index) {
    setState(() {
      _folders.removeAt(index);
    });
  }

  // Новая функция для добавления задачи в список
  void _addTask(String title) {
    setState(() {
      _tasks.add(TaskModel(title: title));
    });
  }

  // Новая функция для переключения статуса галочки
  void _toggleTaskStatus(int index) {
    setState(() {
      _tasks[index].isDone = !_tasks[index].isDone;
    });
  }

  // Новая функция для удаления задачи (по желанию, долгим нажатием)
  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }

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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
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

  // Обновленное диалоговое окно добавления задачи с контроллером текста
  void _showAddTaskDialog() {
    final TextEditingController taskController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Добавить новую задачу'),
          content: TextField(
            controller: taskController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Что нужно сделать?'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                if (taskController.text.isNotEmpty) {
                  _addTask(taskController.text); // Сохраняем задачу
                  Navigator.pop(context);
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои Задачи'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Папки',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
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
                      return FolderCard(
                        folder: _folders[index],
                        onDelete: () => _deleteFolder(index),
                      );
                    },
                  ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Задачи',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          // Обновленный интерактивный список созданных задач
          Expanded(
            child: _tasks.isEmpty
                ? const Center(
                    child: Text(
                      'Список задач пуст',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return CheckboxListTile(
                        title: Text(
                          task.title,
                          style: TextStyle(
                            // Если задача выполнена, текст зачеркивается
                            decoration: task.isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: task.isDone ? Colors.grey : Colors.black,
                          ),
                        ),
                        value: task.isDone,
                        onChanged: (bool? value) {
                          _toggleTaskStatus(index); // Переключаем статус выполнения
                        },
                        secondary: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteTask(index), // Кнопка удаления задачи
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        tooltip: 'Добавить задачу',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
