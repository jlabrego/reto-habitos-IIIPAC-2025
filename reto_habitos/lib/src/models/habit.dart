import 'package:flutter/material.dart';

class Habit {
  final String id;
  final String name;
  final String category;
  final int suggestedDurationMinutes;
  final Color color;

  Habit({
    required this.id,
    required this.name,
    required this.category,
    required this.suggestedDurationMinutes,
    required this.color,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'suggestedDurationMinutes': suggestedDurationMinutes,
        'color': color.value,
      };

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      suggestedDurationMinutes: map['suggestedDurationMinutes'],
      color: Color(map['color']),
    );
  }
}
