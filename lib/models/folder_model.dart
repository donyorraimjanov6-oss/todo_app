import 'package:flutter/material.dart';

class FolderModel {
  final String name;
  final Color color;

  FolderModel({
    required this.name,
    required this.color,
  });

  // Конвертируем в Map для сохранения в JSON
  Map<String, dynamic> toJson() => {
        'name': name,
        'color': color.value, // Сохраняем цвет как число (int)
      };

  // Восстанавливаем объект из Map
  factory FolderModel.fromJson(Map<String, dynamic> json) => FolderModel(
        name: json['name'],
        color: Color(json['color']), // Восстанавливаем цвет из числа
      );
}
