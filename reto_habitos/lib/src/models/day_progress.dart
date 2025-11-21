import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DayProgress {
  final String id;              // Ej: "day-1", "day-2"
  final DateTime date;          // Fecha del día
  final int timeSpentSeconds;   // Tiempo acumulado en segundos
  final bool isCompleted;       // Si se cumplió la meta diaria

  DayProgress({
    required this.id,
    required this.date,
    required this.timeSpentSeconds,
    required this.isCompleted,
  });

  // Convierte a Map para guardar en Firestore
  Map<String, dynamic> toJson() {
    return {
      'date': Timestamp.fromDate(date),
      'timeSpentSeconds': timeSpentSeconds,
      'Completed': isCompleted,
    };
  }

  // Construye desde documento Firestore
    factory DayProgress.fromJson(String id, Map<String, dynamic> data) {
    return DayProgress(
      id: id,
      date: (data['date'] as Timestamp).toDate(),
      timeSpentSeconds: data['timeSpentSeconds'] ?? 0,
      isCompleted: data['Completed'] ?? false,
    );
  }
}
