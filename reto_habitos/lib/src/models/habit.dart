import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class Habit {
  final String id;
  final String name;
  final String category;
  final int suggestedDurationMinutes;
   final DateTime startDate;
  final Color color;

  Habit({
    required this.id,
    required this.name,
    required this.category,
    required this.suggestedDurationMinutes,
    required this.color,
    required this.startDate,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'suggestedDurationMinutes': suggestedDurationMinutes,
        'startDate': Timestamp.fromDate(startDate),
        'color': color.value,
      };

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      suggestedDurationMinutes: map['suggestedDurationMinutes'],
      startDate: (map['startDate'] as Timestamp).toDate(),
      color: Color(map['color']),
    );
  }
}
