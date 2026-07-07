import 'package:flutter/material.dart';
import '../models/folder_model.dart';
import '../models/task_model.dart';
import '../widgets/folder_card.dart';
import 'home_screen_logic.dart';
import 'settings_screen.dart'; // Подключаем экран настроек

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with HomeScreenLogic {
  @override
  void initState() {
    super.initState();
    loadData();
  }

  // Поиск цвета папки для окрашивания задач
  Color _getFolderColor(String folderName) {
    final folder = folders.firstWhere(
      (f) => f.name == folderName,
      orElse: () => FolderModel(name: '', color: Colors.grey),
    );
    return folder.color;
  }

  // Всплывающий календарь на весь месяц
  Future<void> _showFullMonthPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'ВЫБЕРИТЕ ДЕНЬ ИЗ МЕСЯЦА',
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }
  // Диалог создания папки
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
                  addFolder(controller.text, selectedColor);
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

  // Диалог создания новой задачи
  void _showAddTaskDialog() {
    final TextEditingController taskController = TextEditingController();
    String selectedFolder = folders.isNotEmpty ? folders.first.name : 'Без папки';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Задача на $formattedSelectedDate'),
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
                        items: folders.isEmpty
                            ? [const DropdownMenuItem(value: 'Без папки', child: Text('Без папки'))]
                            : folders.map((folder) {
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
                      addTask(taskController.text, selectedFolder);
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
    final List<String> weekDays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    // Фильтрация задач по выбранному дню календаря и выбранной папке
    final List<TaskModel> filteredTasks = tasks.where((task) {
      final matchesDate = task.date == formattedSelectedDate;
      final matchesFolder = selectedFolderName == null || task.folderName == selectedFolderName;
      return matchesDate && matchesFolder;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои Задачи', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        
              
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Зажмите день для выбора месяца',
            onPressed: _showFullMonthPicker,
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ЛЕНТА КАЛЕНДАРЯ НА 7 ДНЕЙ
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Text(
              'Расписание (зажмите день для обзора месяца)',
              style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            height: 80,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 7,
              itemBuilder: (context, index) {
                final dayDate = DateTime.now().add(Duration(days: index));
                final isCurrentSelected = dayDate.day == selectedDate.day && 
                                         dayDate.month == selectedDate.month;
                
                return GestureDetector(
                  onTap: () {
                    setState(() { selectedDate = dayDate; }); // Выбор дня
                  },
                  onLongPress: _showFullMonthPicker, // Месяц при удержании
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 55,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCurrentSelected ? Colors.blue : Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCurrentSelected ? Colors.blue : Colors.blue.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          weekDays[dayDate.weekday - 1],
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold,
                            color: isCurrentSelected ? Colors.white : Colors.grey.shade700
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dayDate.day}',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            color: isCurrentSelected ? Colors.white : Colors.black
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // БЛОК ОВАЛЬНЫХ ПАПОК СВЕРХУ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
            child: folders.isEmpty
                ? const Center(child: Text('Нет папок. Добавьте первую!'))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: folders.length,
                    itemBuilder: (context, index) {
                      final folder = folders[index];
                      final isSelected = selectedFolderName == folder.name;
                      return FolderCard(
                        folder: folder,
                        taskCount: getUncompletedCount(folder.name),
                        isSelected: isSelected,
                        onTap: () {
                          setState(() { selectedFolderName = isSelected ? null : folder.name; });
                        },
                        onDelete: () => deleteFolder(index),
                      );
                    },
                  ),
          ),

          // ЗАГОЛОВОК СПИСКА ЗАДАЧ
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedFolderName == null ? 'Задачи на день' : 'Категория: $selectedFolderName',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (selectedFolderName != null)
                  TextButton(
                    onPressed: () { setState(() { selectedFolderName = null; }); },
                    child: const Text('Показать все'),
                  ),
              ],
            ),
          ),
          
          // СПИСОК КАРТОЧЕК ЗАДАЧ
          Expanded(
            child: filteredTasks.isEmpty
                ? const Center(
                    child: Text('На этот день задач нет', style: TextStyle(color: Colors.grey)),
                  )
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
                            onChanged: (bool? value) { toggleTaskStatus(task); },
                            secondary: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => deleteTask(task),
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
      // НИЖНИЙ ПЛЮС ДЛЯ ЗАДАЧ
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        tooltip: 'Добавить задачу',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
