import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:reto_habitos/src/models/habit.dart';

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
  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'timeSpentSeconds': timeSpentSeconds,
      'isCompleted': isCompleted,
    };
  }

  // Construye desde documento Firestore
  static DayProgress fromDoc(String id, Map<String, dynamic> data) {
    return DayProgress(
      id: id,
      date: (data['date'] as Timestamp).toDate(),
      timeSpentSeconds: data['timeSpentSeconds'] ?? 0,
      isCompleted: data['isCompleted'] ?? false,
    );
  }
}
