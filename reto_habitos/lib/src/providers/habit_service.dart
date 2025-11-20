import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart'; // ¡Necesario para switchMap y Rx.combineLatestList!
import '../models/habit.dart';
// import '../providers/day_progress.dart'; // Deja esta línea si usas DayProgress en otros lugares

class HabitService {
    // Referencias a Firestore
    final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Mantenemos esta si la necesitas
    final CollectionReference habitsRef = FirebaseFirestore.instance.collection('habits');

    // =======================================================
    // 1. MÉTODOS BÁSICOS (CRUD)
    // =======================================================

    Future<void> addHabit(Habit habit) async {
        await habitsRef.doc(habit.id).set(habit.tojson());
    }

    Stream<Habit?> getHabitStream(String habitId) {
        return habitsRef.doc(habitId).snapshots().map((snapshot) {
            if (!snapshot.exists) return null;
            return Habit.fromJson(snapshot.data() as Map<String, dynamic>);
        });
    }

    Stream<List<Habit>> getHabitsStream() {
        return habitsRef.snapshots().map((snapshot) {
            return snapshot.docs
                .map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  data['id'] = d.id;

            return Habit.fromJson(data);
                })
                .toList();
        });
    }

    // =======================================================
    // 2. STREAMS Y CONTEOS REACTIVOS (SOLUCIÓN AL '0%')
    // =======================================================

    // Conteo de días completados (Individual)
    Stream<int> getCompletedDaysCountStream(String habitId) {
        // Cuenta el número de documentos con .size en la subcolección
        return habitsRef
            .doc(habitId)
            .collection('completed_dates')
            .snapshots() 
            .map((snapshot) => snapshot.size);
    }

    // Resumen de Progreso Global (Círculo de progreso en la lista)
    Stream<Map<String, int>> getGlobalProgressSummary() {
        return getHabitsStream().switchMap((habits) {
            if (habits.isEmpty) {
                return Stream.value({'completed': 0, 'possible': 0});
            }

            final streams = habits.map((habit) => getCompletedDaysCountStream(habit.id!));
            
            // Combina los streams de conteo de todos los hábitos (rxdart)
            return Rx.combineLatestList(streams).map((completedCounts) {
                
                final totalCompleted = completedCounts.fold<int>(0, (sum, count) => sum + count);
                final totalPossible = habits.length * 30;

                return {
                    'completed': totalCompleted,
                    'possible': totalPossible,
                };
            });
        });
    }

    // =======================================================
    // 3. LÓGICA Y ACTUALIZACIÓN DE RACHA (STREAK)
    // =======================================================

    /// Algoritmo para calcular el número de días consecutivos.
    int _calculateStreak(DateTime today, List<DateTime> completedDates) {
        if (completedDates.isEmpty) {
            return 0;
        }
        
        // Normalizar las fechas a medianoche para comparaciones exactas
        final Set<DateTime> normalizedDates = completedDates
            .map((date) => DateTime(date.year, date.month, date.day))
            .toSet();
            
        DateTime checkDate = DateTime(today.year, today.month, today.day);
        int streak = 0;
        
        // Si el día de hoy aún no está marcado, empezamos la revisión desde ayer.
        if (!normalizedDates.contains(checkDate)) {
            checkDate = checkDate.subtract(const Duration(days: 1));
        }
        
        // Recorrer hacia atrás y contar la racha
        while (normalizedDates.contains(checkDate)) {
            streak++;
            checkDate = checkDate.subtract(const Duration(days: 1));
        }

        return streak;
    }

    /// Actualiza el campo 'streak' en el documento principal del hábito.
    Future<void> updateStreak(String habitId) async {
        final now = DateTime.now();
        
        // Obtener la lista de fechas completadas (el último valor del Stream)
        final completedDates = await getCompletedDatesStream(habitId).first;
        
        final newStreak = _calculateStreak(now, completedDates);

        // Actualizar el documento principal del hábito
        await habitsRef.doc(habitId).update({'streak': newStreak});
    }

    // =======================================================
    // 4. REGISTRO DIARIO (GRID)
    // =======================================================

    // Obtener Stream de Fechas Completadas para la cuadrícula
    Stream<List<DateTime>> getCompletedDatesStream(String habitId) {
        return habitsRef.doc(habitId).collection('completed_dates').snapshots().map((snapshot) {
            return snapshot.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                if (data != null && data.containsKey('date')) {
                    return (data['date'] as Timestamp).toDate(); 
                }
                return DateTime(1900); 
            }).where((date) => date.year > 1900).toList();
        });
    }

    // Marcar/Desmarcar un Día y Recalcular la Racha
    Future<void> toggleDayCompletion(String habitId, DateTime date, bool isCompleted) async {
        final dateKey = date.toIso8601String().substring(0, 10);
        final dateRef = habitsRef.doc(habitId).collection('completed_dates').doc(dateKey);

        if (isCompleted) {
            // Si ya estaba completado, lo eliminamos (desmarcar)
            await dateRef.delete();
        } else {
            // Si no estaba completado, lo añadimos (marcar)
            final dateToSave = DateTime(date.year, date.month, date.day);
            await dateRef.set({'date': Timestamp.fromDate(dateToSave)});
        }
        
        // 🟢 CLAVE: Recalcular y actualizar la racha después de cualquier cambio.
        await updateStreak(habitId); 
    }
}