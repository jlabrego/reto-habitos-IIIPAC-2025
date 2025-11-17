import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit.dart';

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
}
