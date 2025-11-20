import 'package:cloud_firestore/cloud_firestore.dart';

class Habit {
  final String id;
  final String name;
  final String description;
  final int duration;
  final int daysCompleted;
  final int streak;      
  final DateTime createdAt;
  final String category;
  final String? colorHex; 

  Habit({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.daysCompleted,
    required this.streak,       
    required this.createdAt,
    required this.category,
    this.colorHex,
  });

  // Constructor fromJson modificado
  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String? ?? '',
      name: json['name'] as String,
      description: json['description'] as String,
      duration: json['duration'] as int,
      daysCompleted: json['daysCompleted'] as int,
      streak: json['streak'] as int,      
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      category: json['category'] as String? ?? 'Otro',
      colorHex: json['colorHex'] as String?,
    );
  }

  // Método tojson modificado
  Map<String, dynamic> tojson() {
    return {
      //'id': id,
      'name': name,
      'description': description,
      'duration': duration,
      'daysCompleted': daysCompleted,
      'streak': streak,       
      'createdAt': Timestamp.fromDate(createdAt),
      'category': category,
      'colorHex': colorHex,    
    };
  }

  
}