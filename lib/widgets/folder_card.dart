import 'package:flutter/material.dart';
import '../models/folder_model.dart';

class FolderCard extends StatelessWidget {
  final FolderModel folder;
  final int taskCount;
  final bool isSelected; // Подсвечена ли папка сейчас
  final VoidCallback onTap; // Действие при нажатии на овал
  final VoidCallback onDelete; // Действие при удалении

  const FolderCard({
    super.key,
    required this.folder,
    required this.taskCount,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Передаем нажатие
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          // Если папка выбрана, делаем фон более насыщенным
          color: isSelected ? folder.color.withOpacity(0.4) : folder.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: folder.color, 
            width: isSelected ? 3 : 2, // Выделяем рамку выбранной папки
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder, color: folder.color, size: 20),
            const SizedBox(width: 8),
            Text(
              folder.name,
              style: TextStyle(
                color: folder.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: folder.color,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$taskCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: Icon(
                Icons.close,
                color: folder.color,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
