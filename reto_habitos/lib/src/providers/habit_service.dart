import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit.dart';
import '../providers/day_progress.dart';

class HabitService {
  // Asegúrate de definir _db si usas la notación _db.collection, o usa habitsRef.
  // Aquí asumo que usaremos habitsRef.
  final CollectionReference habitsRef =
      FirebaseFirestore.instance.collection('habits');

  // Si no tienes esta referencia, agrégala:
  // final FirebaseFirestore _db = FirebaseFirestore.instance;


  Future<void> addHabit(Habit habit) async {
    await habitsRef.doc(habit.id).set(habit.tojson());
  }

  Stream<List<Habit>> getHabitsStream() {
    return habitsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((d) => Habit.fromJson(d.data() as Map<String, dynamic>))
          .toList();
    });
  }
    
  Stream<int> getCompletedDaysCountStream(String habitId) {
    return habitsRef
        .doc(habitId)
        .collection('progress')
        .where('isCompleted', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
  
  Stream<Map<String, int>> getGlobalProgressSummary() {
    // ... (lógica del resumen global) ...
    return getHabitsStream().map((habits) {
      int totalCompleted = 0;
      int totalPossible = habits.length * 30; // 30 días por reto

      for (var habit in habits) {
        totalCompleted += habit.daysCompleted;
      }
      
      return {
        'completed': totalCompleted,
        'possible': totalPossible,
      };
    });
  }

  Future<void> completeToday(Habit habit) async {
    final today = DateTime.now();
    final dayIndex = today.difference(habit.createdAt).inDays + 1;
    final todayId = "day-$dayIndex";

    final progress = DayProgress(
      id: todayId,
      date: today,
      timeSpentSeconds: habit.duration * 60,
      isCompleted: true,
    );

    await habitsRef
        .doc(habit.id)
        .collection('progress')
        .doc(todayId)
        .set(progress.toMap());
  }
  
  // =======================================================
  // 🚀 MÉTODOS AÑADIDOS PARA LA PANTALLA DE DETALLE (Grid)
  // =======================================================

  // 1. Obtener Stream de Fechas Completadas
  Stream<List<DateTime>> getCompletedDatesStream(String habitId) {
    return habitsRef.doc(habitId).collection('completed_dates').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // Asume que el documento 'completed_dates' tiene un campo 'date' de tipo Timestamp
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('date')) {
            return (data['date'] as Timestamp).toDate(); 
        }
        // Si no existe, devolver una fecha segura o manejar el error
        // En un escenario real, esto no debería ocurrir si el toggle funciona bien.
        return DateTime(1900); 
      }).where((date) => date.year > 1900).toList(); // Filtramos fechas inválidas
    });
  }

  // 2. Marcar/Desmarcar un Día (Función central de la cuadrícula)
  Future<void> toggleDayCompletion(String habitId, DateTime date, bool isCompleted) async {
    // Usamos el formato de fecha (YYYY-MM-DD) como ID de documento para la fecha
    final dateKey = date.toIso8601String().substring(0, 10);
    final dateRef = habitsRef.doc(habitId).collection('completed_dates').doc(dateKey);

    if (isCompleted) {
      // Si ya estaba completado (isCompleted == true), lo eliminamos (desmarcar)
      await dateRef.delete();
    } else {
      // Si no estaba completado (isCompleted == false), lo añadimos (marcar)
      // Guardamos la fecha con la hora a medianoche (00:00:00)
      final dateToSave = DateTime(date.year, date.month, date.day);
      await dateRef.set({'date': Timestamp.fromDate(dateToSave)});
    }
    
  
  }
  
  // Stream para obtener un solo hábito por ID
  Stream<Habit?> getHabitStream(String habitId) {
    return habitsRef.doc(habitId).snapshots().map((snapshot) {
        if (!snapshot.exists) return null;
        return Habit.fromJson(snapshot.data() as Map<String, dynamic>);
    });
  }

}