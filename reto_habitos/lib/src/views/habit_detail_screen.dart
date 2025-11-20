import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../providers/habit_service.dart';

class HabitDetailScreen extends StatelessWidget {
    final String habitId; 
    final HabitService habitService; 

    const HabitDetailScreen({
        super.key,
        required this.habitId,
        required this.habitService,
    });

    // =======================================================
    // ⚙️ WIDGETS AUXILIARES
    // =======================================================
    
    // 1. Obtener Color
    Color _getHabitColor(Habit habit) {
        final String? hex = habit.colorHex;
        const int defaultColorValue = 0xFF673AB7; 

        int colorValue;
        if (hex != null && hex.length >= 6) {
            // Asegura que tenga el alfa (FF) al inicio si solo tiene 6 dígitos
            colorValue = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16) ?? defaultColorValue;
        } else {
            colorValue = defaultColorValue;
        }
        return Color(colorValue);
    }
    
    // 2. Widget auxiliar para las estadísticas individuales
    Widget _buildStat(String title, String value, Color color) {
        return Column(
            children: [
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
        );
    }
    
    // 3. Widget auxiliar para filas de detalle
    Widget _buildDetailRow(IconData icon, String title, String value, Color color) {
        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Row(
                children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 10),
                    Text("$title: ", style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(value),
                ],
            ),
        );
    }

    // 4. 🟢 WIDGET PRINCIPAL DE ESTADÍSTICAS (Usa StreamBuilder para el conteo de días)
    Widget _buildStatsAndProgress(Habit habit, Color color, HabitService service) {
        return StreamBuilder<int>(
            stream: service.getCompletedDaysCountStream(habit.id),
            builder: (context, countSnapshot) {
                
                // Usar el conteo REAL de la subcolección.
                final completedDays = countSnapshot.data ?? 0; 
                const totalDays = 30;
                final remainingDays = totalDays - completedDays;
                final progress = completedDays / totalDays;
                
                // Nota: El campo 'streak' sigue viniendo del modelo, asumiendo
                // que será actualizado por Cloud Functions o lógica cliente más adelante.
                final streak = habit.streak; 
                
                return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                            children: [
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                        // Los contadores usan 'completedDays' real
                                        _buildStat('Días Compl.', completedDays.toString(), color),
                                        _buildStat('Racha Actual', streak.toString(), color),
                                        _buildStat('Días Rest.', remainingDays.toString(), color),
                                    ],
                                ),
                                const SizedBox(height: 15),
                                LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey.shade200,
                                    color: progress >= 1.0 ? Colors.green : color,
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(4),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                    "${(progress * 100).toStringAsFixed(0)}% del Reto completado",
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                            ],
                        ),
                    ),
                );
            }
        );
    }

    // 5. 🟢 WIDGET DE CUADRÍCULA (Usa StreamBuilder para las fechas completadas)
    Widget _buildDayGrid(BuildContext context, Habit habit, Color color, HabitService service) {
        // Obtenemos un Stream de las fechas completadas reales (Firestore)
        return StreamBuilder<List<DateTime>>(
            stream: service.getCompletedDatesStream(habit.id),
            builder: (context, snapshot) {
                
                final completedDates = snapshot.data ?? [];
                
                // Calcula el índice del día actual basado en la fecha de creación
                final today = DateTime.now();
                final creationDate = habit.createdAt;
                final int difference = today.difference(creationDate).inDays;
                final currentDayIndex = difference + 1; 

                return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7, 
                        crossAxisSpacing: 5,
                        mainAxisSpacing: 5,
                    ),
                    itemCount: 30, 
                    itemBuilder: (context, index) {
                        final dayNumber = index + 1;
                        final specificDate = creationDate.add(Duration(days: index));
                        
                        // Comprobación real si la fecha está en la lista de fechas completadas
                        final isCompleted = completedDates.any(
                            (date) => date.year == specificDate.year &&
                                      date.month == specificDate.month &&
                                      date.day == specificDate.day
                        );

                        final isTodayOrPast = dayNumber <= currentDayIndex;
                        // Permite marcar/desmarcar hasta el final del día de mañana
                        final canToggle = specificDate.isBefore(today.add(const Duration(days: 1))); 

                        return GestureDetector(
                            onTap: canToggle ? () {
                                // Lógica para marcar/desmarcar el día en Firestore
                                service.toggleDayCompletion(
                                    habit.id, 
                                    specificDate, 
                                    isCompleted // <-- Envía el estado actual
                                );
                            } : null,
                            child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    // Púrpura si está completado, Blanco si es un día actual/pasado sin marcar
                                    color: isCompleted 
                                             ? color.withOpacity(0.9) 
                                             : (isTodayOrPast ? Colors.white : Colors.grey.shade200),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: isTodayOrPast ? color : Colors.grey.shade300, 
                                        width: isTodayOrPast ? 2 : 1 // Borde más grueso para días activos/pasados
                                    ),
                                ),
                                child: Text(
                                    '$dayNumber',
                                    style: TextStyle(
                                        color: isCompleted ? Colors.white : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                    ),
                                ),
                            ),
                        );
                    },
                );
            }
        );
    }
    
    // =======================================================
    // 🧱 BUILD PRINCIPAL
    // =======================================================
    @override
    Widget build(BuildContext context) {
        
        // Usamos un StreamBuilder para obtener la información más reciente del hábito
        return StreamBuilder<Habit?>(
            stream: habitService.getHabitStream(habitId),
            builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                
                final habit = snapshot.data;

                if (habit == null) {
                    return Scaffold(
                        appBar: AppBar(title: const Text("Hábito no encontrado")),
                        body: const Center(child: Text("El hábito con este ID no existe.")),
                    );
                }

                final habitColor = _getHabitColor(habit);

                return Scaffold(
                    appBar: AppBar(
                        title: Text(habit.name),
                        backgroundColor: habitColor.withOpacity(0.9), 
                        foregroundColor: Colors.white,
                    ),
                    body: SingleChildScrollView(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                
                                // SECCIÓN 1: RESUMEN DE PROGRESO (Usa el Stream del conteo real)
                                _buildStatsAndProgress(habit, habitColor, habitService),
                                const SizedBox(height: 30),

                                // SECCIÓN 2: CUADRÍCULA DE REGISTRO
                                const Text(
                                    "Registro Diario (30 Días)", 
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                                ),
                                const SizedBox(height: 15),
                                
                                // Cuadrícula de días interactiva (Usa el Stream de las fechas)
                                _buildDayGrid(context, habit, habitColor, habitService),
                                const SizedBox(height: 30),
                                
                                // SECCIÓN 3: INFORMACIÓN DETALLADA
                                const Text(
                                    "Detalles", 
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                                ),
                                const SizedBox(height: 10),
                                _buildDetailRow(
                                    Icons.access_time_filled, 
                                    "Duración Diaria", 
                                    "${habit.duration} minutos", 
                                    habitColor
                                ),
                                _buildDetailRow(
                                    Icons.label_important_rounded, 
                                    "Categoría", 
                                    habit.category, 
                                    habitColor
                                ),
                                _buildDetailRow(
                                    Icons.calendar_month_rounded, 
                                    "Fecha de Inicio", 
                                    "${habit.createdAt.day}/${habit.createdAt.month}/${habit.createdAt.year}", 
                                    habitColor
                                ),
                            ],
                        ),
                    ),
                );
            },
        );
    }
}