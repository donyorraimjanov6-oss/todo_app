import 'package:flutter/material.dart';
import '../models/folder_model.dart';

class FolderCard extends StatelessWidget {
  final FolderModel folder;
  final VoidCallback onDelete;

  const FolderCard({
    super.key,
    required this.folder,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: folder.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30), // Делает контейнер овальным
        border: Border.all(color: folder.color, width: 2),
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
    );
  }
}
