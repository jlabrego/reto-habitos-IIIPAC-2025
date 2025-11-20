import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; 
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
    //WIDGETS AUXILIARES
    
    // 1. Obtener Color
    Color _getHabitColor(Habit habit) {
        final String? hex = habit.colorHex;
        // Usamos un valor por defecto si el campo es nulo o inválido 
        const int defaultColorValue = 0xFF673AB7; 

        int colorValue;
        if (hex != null && hex.length >= 6) {
            String cleanHex = hex.startsWith('#') ? hex.substring(1) : hex;
            colorValue = int.tryParse(cleanHex.length == 6 ? 'FF$cleanHex' : cleanHex, radix: 16) ?? defaultColorValue;
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

    // 4. WIDGET PRINCIPAL DE ESTADÍSTICAS
    Widget _buildStatsAndProgress(Habit habit, Color color, HabitService service) {
        return StreamBuilder<int>(
            stream: service.getCompletedDaysCountStream(habit.id),
            builder: (context, countSnapshot) {
                
                final completedDays = countSnapshot.data ?? 0; 
                const totalDays = 30;
                final remainingDays = totalDays - completedDays;
                final progress = completedDays / totalDays;
                
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

    // 5. WIDGET DE CUADRÍCULA DE DÍAS
    Widget _buildDayGrid(BuildContext context, Habit habit, Color color, HabitService service) {
      final bool isTimeBased = habit.duration > 0;
        return StreamBuilder<List<DateTime>>(
            stream: service.getCompletedDatesStream(habit.id),
            builder: (context, snapshot) {
                
                final completedDates = snapshot.data ?? [];
                
                final today = DateTime.now();
                final creationDate = habit.createdAt;
                final int difference = today.difference(creationDate).inDays;
                final currentDayIndex = difference + 1; 
                
                // Función auxiliar para normalizar las fechas a solo día, mes y año
                final Set<String> normalizedCompletedDates = completedDates
                    .map((date) => '${date.year}-${date.month}-${date.day}')
                    .toSet();

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
                        final normalizedSpecificDate = '${specificDate.year}-${specificDate.month}-${specificDate.day}';

                        // Comprobación real si la fecha está en la lista de fechas completadas
                        final isCompleted = normalizedCompletedDates.contains(normalizedSpecificDate);

                        final isTodayOrPast = dayNumber <= currentDayIndex;
                        // Permite marcar/desmarcar hasta el final del día de hoy
                        //final canToggle = specificDate.isBefore(today.add(const Duration(days: 1))) || specificDate.isAtSameMomentAs(DateTime(today.year, today.month, today.day)); 
                        final bool allowManualToggle = !isTimeBased && isTodayOrPast;
                        return GestureDetector(
                            onTap: allowManualToggle ? () {
                              if (!isTimeBased && !isTodayOrPast) return;
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
    
    // 6. WIDGET DEL BOTÓN DE CRONÓMETRO 
    Widget _buildTimerActionCard(BuildContext context, Habit habit, Color color) {
        return Card(
            color: color.withOpacity(0.1),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: color.withOpacity(0.3), width: 1),
            ),
            child: ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                leading: Icon(Icons.timer, size: 40, color: color),
                title: const Text(
                    'Registrar Sesión Diaria',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                    '${habit.duration} minutos | Toca para usar el cronómetro.',
                    style: TextStyle(color: Colors.grey.shade600),
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 20, color: color),
                onTap: () {
                    // NAVEGACIÓN A LA RUTA DEL CRONÓMETRO
                    context.goNamed('habit-timer', pathParameters: {'id': habit.id});
                },
            ),
        );
    }
    
    @override
    Widget build(BuildContext context) {
        
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
                                
                                // BOTÓN DE ACCIÓN DEL CRONÓMETRO
                                _buildTimerActionCard(context, habit, habitColor),
                                const SizedBox(height: 30),

                                // SECCIÓN 1: RESUMEN DE PROGRESO
                                _buildStatsAndProgress(habit, habitColor, habitService),
                                const SizedBox(height: 30),

                                // SECCIÓN 2: CUADRÍCULA DE REGISTRO
                                const Text(
                                    "Registro Diario (30 Días)", 
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                                ),
                                const SizedBox(height: 15),
                                
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