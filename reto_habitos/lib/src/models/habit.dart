//import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Habit {
  final String id;
  final String name;
  final String description;
  final int duration;
  final int daysCompleted;
  final int streak;
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.streak,
    required this.daysCompleted,
    required this.createdAt
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'duration': duration,
        'daysCompleted': daysCompleted,
        'streak' : streak,
        'createdAt': Timestamp.fromDate(createdAt),
        
      };

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(

      id: map['id'],
      name: map['name'],
      description: map['description'],
      duration: map['duration'],
      daysCompleted: map['daysCompleted'],
      streak: map['streak'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
 
    );
  }
}
