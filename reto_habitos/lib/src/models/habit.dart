//import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Habit {
  final String id;
  final String name;
  final String? description;
  final int duration;
  final int daysCompleted;
  final int streak;
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.name,
    this.description,
    required this.duration,
    required this.streak,
    required this.daysCompleted,
    required this.createdAt
  });

  Map<String, dynamic> tojson() => {
        'id': id,
        'name': name,
        'description': description,
        'duration': duration,
        'daysCompleted': daysCompleted,
        'streak' : streak,
        'createdAt': Timestamp.fromDate(createdAt),
        
      };

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(

      id: json['id'],
      name: json['name'],
      description: json['description'],
      duration: json['duration'],
      daysCompleted: json['daysCompleted'],
      streak: json['streak'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
 
    );
  }
}
