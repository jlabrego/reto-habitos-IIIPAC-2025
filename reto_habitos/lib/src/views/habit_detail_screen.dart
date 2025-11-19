// File: src/views/habit_detail_screen.dart (Implementación Completa)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/habit.dart';
import '../providers/habit_service.dart';

// ESTA ES LA CLASE QUE EL ROUTER NECESITA EN ESTE ARCHIVO
class HabitDetailScreen extends StatelessWidget {
    final String habitId; 
    final HabitService habitService; 

    const HabitDetailScreen({
        super.key,
        required this.habitId,
        required this.habitService,
    });

    // Método para convertir el HEX a Color 
    Color _getHabitColor(Habit habit) {
        final String? hex = habit.colorHex;
        const int defaultColorValue = 0xFF673AB7; 

        int colorValue;
        if (hex != null && hex.length >= 6) {
            // Asegura que el valor tenga el componente de opacidad (AA)
            colorValue = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16) ?? defaultColorValue;
        } else {
            colorValue = defaultColorValue;
        }
        return Color(colorValue);
    }

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
                        // AppBar teñido con el color del hábito
                        backgroundColor: habitColor.withOpacity(0.9), 
                        foregroundColor: Colors.white,
                    ),
                    body: SingleChildScrollView(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                
                                // SECCIÓN 1: RESUMEN DE PROGRESO
                                _buildSummaryCard(habit, habitColor),
                                const SizedBox(height: 30),

                                // SECCIÓN 2: CUADRÍCULA DE REGISTRO
                                const Text(
                                    "Registro Diario (30 Días)", 
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                                ),
                                const SizedBox(height: 15),
                                
                                // Cuadrícula de días interactiva
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
    
    // Widget auxiliar para la tarjeta de resumen
    Widget _buildSummaryCard(Habit habit, Color color) {
        const totalDays = 30;
        final progress = habit.daysCompleted / totalDays;
        
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
                                _buildStat('Días Compl.', habit.daysCompleted.toString(), color),
                                _buildStat('Racha Actual', habit.streak.toString(), color),
                                _buildStat('Días Rest.', (totalDays - habit.daysCompleted).toString(), color),
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

    // Widget auxiliar para las estadísticas individuales
    Widget _buildStat(String title, String value, Color color) {
        return Column(
            children: [
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
        );
    }
    
    // Widget auxiliar para filas de detalle
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

    // Widget auxiliar para la cuadrícula de días
    Widget _buildDayGrid(BuildContext context, Habit habit, Color color, HabitService service) {
        // Obtenemos un Stream de las fechas completadas reales (Firestore)
        return StreamBuilder<List<DateTime>>(
            stream: service.getCompletedDatesStream(habit.id),
            builder: (context, snapshot) {
              
              // Usamos las fechas reales del servidor o una lista vacía
              final completedDates = snapshot.data ?? [];
              
              // Calcula el índice del día actual basado en la fecha de creación
              final today = DateTime.now();
              final creationDate = habit.createdAt;
              final int difference = today.difference(creationDate).inDays;
              final currentDayIndex = difference + 1; // Día actual en el reto (1 a 30)

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, // 7 días a la semana
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                ),
                itemCount: 30, // Reto de 30 días
                itemBuilder: (context, index) {
                  final dayNumber = index + 1;
                  
                  // Fecha específica para este cuadro (Día 1, Día 2, etc.)
                  final specificDate = creationDate.add(Duration(days: index));
                  
                  // Comprobación real si la fecha está en la lista de fechas completadas
                  final isCompleted = completedDates.any(
                    (date) => date.year == specificDate.year &&
                              date.month == specificDate.month &&
                              date.day == specificDate.day
                  );

                  final isTodayOrPast = dayNumber <= currentDayIndex;
                  final canToggle = specificDate.isBefore(today.add(const Duration(days: 1))); // Permite marcar hasta mañana

                  return GestureDetector(
                    onTap: canToggle ? () {
                      // Lógica para marcar/desmarcar el día en Firestore
                      service.toggleDayCompletion(
                        habit.id, 
                        specificDate, 
                        isCompleted
                      );
                    } : null,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isCompleted 
                               ? color.withOpacity(0.9) 
                               : (isTodayOrPast ? Colors.white : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: isTodayOrPast ? color : Colors.grey.shade300, 
                            width: isTodayOrPast ? 2 : 1
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
}