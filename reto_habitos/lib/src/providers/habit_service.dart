// habit_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:intl/intl.dart'; 
import '../models/habit.dart'; // Asegúrate de que esta ruta sea correcta
import '../models/day_progress.dart'; // Asegúrate de que esta ruta sea correcta

class HabitService {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final CollectionReference habitsRef = FirebaseFirestore.instance.collection('habits');
    
    // Inyección de dependencias de tiempo para pruebas
    final DateTime Function() _now;
    HabitService({DateTime Function()? now}) : _now = now ?? DateTime.now;

    // 1. MÉTODOS BÁSICOS (CRUD)

    Future<void> addHabit(Habit habit) async {
        await habitsRef.doc(habit.id).set(habit.tojson()); 
    }

    Stream<Habit?> getHabitStream(String habitId) {
        return habitsRef.doc(habitId).snapshots().map((snapshot) {
            if (!snapshot.exists) return null;

            final data = snapshot.data() as Map<String, dynamic>;
            data['id'] = snapshot.id; 

            return Habit.fromJson(data);
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

    // 2. STREAMS Y CONTEOS REACTIVOS

    Stream<int> getCompletedDaysCountStream(String habitId) {
        return habitsRef
            .doc(habitId)
            .collection('completed_dates')
            .snapshots() 
            .map((snapshot) => snapshot.size);
    }

    Stream<Map<String, int>> getGlobalProgressSummary() {
        return getHabitsStream().switchMap((habits) {
            if (habits.isEmpty) {
                return Stream.value({'completed': 0, 'possible': 0});
            }

            final streams = habits.map((habit) => getCompletedDaysCountStream(habit.id));
            
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

    // 3. LÓGICA Y ACTUALIZACIÓN DE RACHA (STREAK)
    int _calculateStreak(DateTime today, List<DateTime> completedDates) {
        if (completedDates.isEmpty) {
            return 0;
        }
        
        final Set<DateTime> normalizedDates = completedDates
            .map((date) => DateTime(date.year, date.month, date.day))
            .toSet();
            
        DateTime checkDate = DateTime(today.year, today.month, today.day);
        int streak = 0;
        
        if (!normalizedDates.contains(checkDate)) {
            checkDate = checkDate.subtract(const Duration(days: 1));
        }
        
        while (normalizedDates.contains(checkDate)) {
            streak++;
            checkDate = checkDate.subtract(const Duration(days: 1));
        }

        return streak;
    }

    Future<void> updateStreak(String habitId) async {
        final now = _now(); // ✅ Usa la fecha inyectada
        final completedDates = await getCompletedDatesStream(habitId).first;
        final newStreak = _calculateStreak(now, completedDates);
        await habitsRef.doc(habitId).update({'streak': newStreak});
    }

    // 4. REGISTRO DIARIO (GRID Y CRONÓMETRO)
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

    Future<void> toggleDayCompletion(String habitId, DateTime date, bool isCompleted) async {
        final dateKey = date.toIso8601String().substring(0, 10);
        final dateRef = habitsRef.doc(habitId).collection('completed_dates').doc(dateKey);

        if (isCompleted) {
            await dateRef.delete();
        } else {
            final dateToSave = DateTime(date.year, date.month, date.day);
            await dateRef.set({'date': Timestamp.fromDate(dateToSave)});
        }
        
        await updateStreak(habitId); 
    }
    
    // FUNCIÓN DE REGISTRO DEL CRONÓMETRO 
    Future<void> completeTodayWithTime(String habitId, int totalSecondsSpent, int requiredDurationMinutes) async {
        final today = _now(); // ✅ Usa la fecha inyectada
        final dateKey = today.toIso8601String().substring(0, 10);
        final habitRef = habitsRef.doc(habitId);

        final requiredSeconds = requiredDurationMinutes * 60;
        final isGoalCompleted = totalSecondsSpent >= requiredSeconds;

        final progressRecord = DayProgress(
            id: dateKey,
            date: today,
            timeSpentSeconds: totalSecondsSpent,
            isCompleted: isGoalCompleted,
        );

        await habitRef
            .collection('progress') 
            .doc(dateKey)
            .set(progressRecord.toJson());

        if (isGoalCompleted) {
            final dateToSave = DateTime(today.year, today.month, today.day);
            await habitRef
                .collection('completed_dates')
                .doc(dateKey)
                .set({'date': Timestamp.fromDate(dateToSave)});
        } else {
            await habitRef
                .collection('completed_dates')
                .doc(dateKey)
                .delete();
        }
        
        await updateStreak(habitId); 
    }

    // STREAM DE LECTURA DEL CRONÓMETRO 
    Stream<DayProgress?> getTodayProgressStream(String habitId) {
        final today = _now(); // ✅ Usa la fecha inyectada
        final dateKey = today.toIso8601String().substring(0, 10);

        return habitsRef
            .doc(habitId)
            .collection('progress')
            .doc(dateKey)
            .snapshots()
            .map((snapshot) {
                if (!snapshot.exists) {
                    return null;
                }
                final data = snapshot.data();
                if (data != null) {
                    return DayProgress.fromJson(snapshot.id, data);
                }
                return null;
            });
    }
}