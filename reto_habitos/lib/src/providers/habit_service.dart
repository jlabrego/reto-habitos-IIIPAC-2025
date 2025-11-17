import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit.dart';
import '../providers/day_progress.dart';

class HabitService {
  final CollectionReference habitsRef =
      FirebaseFirestore.instance.collection('habits');

  /// Crea un nuevo hábito en Firestore
  Future<void> addHabit(Habit habit) async {
    await habitsRef.doc(habit.id).set(habit.toMap());
  }

  /// Devuelve un stream de lista de hábitos convertidos al modelo Habit
  Stream<List<Habit>> getHabitsStream() {
    return habitsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Habit.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

Stream<int> getCompletedDaysCountStream(String habitId) {
return habitsRef
.doc(habitId)
 .collection('progress')
// Filtra solo los documentos donde 'isCompleted' sea true
 .where('isCompleted', isEqualTo: true)
 .snapshots()
.map((snapshot) => snapshot.docs.length); // Devuelve el conteo de documentos
}
  /// Obtiene un hábito por ID
  Future<Habit?> getHabitById(String id) async {
    final doc = await habitsRef.doc(id).get();
    if (!doc.exists) return null;
    return Habit.fromMap(doc.data() as Map<String, dynamic>);
  }

  /// Actualiza un hábito existente
  Future<void> updateHabit(Habit habit) async {
    await habitsRef.doc(habit.id).update(habit.toMap());
  }

  /// Elimina un hábito
  Future<void> deleteHabit(String id) async {
    await habitsRef.doc(id).delete();
  }

  /// Obtiene el progreso del día actual como stream
  Stream<DayProgress?> getTodayProgressStream(Habit habit) {
 final today = DateTime.now();
 final daysSinceStart = today.difference(habit.createdAt).inDays + 1;
 final todayId = 'day-$daysSinceStart';

return habitsRef
 .doc(habit.id)
.collection('progress')
 .doc(todayId)
 .snapshots()
  .map((doc) =>
 doc.exists ? DayProgress.fromDoc(doc.id, doc.data()!) : null);
}

  /// Guarda el progreso de un día
  Future<void> saveDayProgress(String habitId, DayProgress progress) async {
    await habitsRef
        .doc(habitId)
        .collection('progress')
        .doc(progress.id)
        .set(progress.toMap());
  }

  /// Devuelve stream de todo el progreso del hábito (para la cuadrícula de 30 días)
  Stream<List<DayProgress>> getProgressStream(Habit habit) {
    return habitsRef
        .doc(habit.id)
        .collection('progress')
        .snapshots()
        .map((snapshot) => snapshot.docs

            .map((doc) => DayProgress.fromDoc(doc.id, doc.data()!))
            .toList());
  }
}
