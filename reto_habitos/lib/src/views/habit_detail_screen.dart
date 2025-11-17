// File: habit_detail_screen.dart

import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../providers/habit_service.dart';

// 1. Debe llamarse EXACTAMENTE HabitDetailScreen
class HabitDetailScreen extends StatelessWidget {
  // 2. Debe aceptar los argumentos habit y habitService
  final Habit habit;
  final HabitService habitService;

  const HabitDetailScreen({
    super.key,
    required this.habit,
    required this.habitService,
  });

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(
        habit.name,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: habit.color,
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: 0,
    ),
    // Usamos StreamBuilder para escuchar el progreso del hábito en tiempo real
    body: StreamBuilder<int>(
      stream: habitService.getCompletedDaysCountStream(habit.id),
      builder: (context, snapshot) {
        final completedDays = snapshot.data ?? 0;
        const totalDays = 30;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. Resumen de Progreso ---
              _buildProgressSummary(habit, completedDays, totalDays),
              const SizedBox(height: 30),

              // --- 2. Rejilla de Días (TODO: Implementar) ---
              Text(
                'Calendario de 30 Días:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
              ),
              const SizedBox(height: 10),
              // Aquí iría tu widget que mapea los 30 días para marcar el progreso
              //  
              
              Container(
                height: 200,
                color: Colors.grey.shade100,
                alignment: Alignment.center,
                child: const Text('Implementar Rejilla de 30 días aquí.'),
              ),
            ],
          ),
        );
      },
    ),
    
    // --- 3. Floating Action Button para marcar como completado ---
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () {
        // TODO: Lógica para marcar el hábito de HOY como completado
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hábito marcado como completado (Mock).')),
        );
      },
      label: const Text('Completar Hoy'),
      icon: const Icon(Icons.check_rounded),
      backgroundColor: habit.color,
      foregroundColor: Colors.white,
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
  );
}

// Widget auxiliar para el resumen de progreso
Widget _buildProgressSummary(Habit habit, int completedDays, int totalDays) {
  final remainingDays = totalDays - completedDays;
  final progress = completedDays / totalDays;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '¡${habit.name}!',
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 10),
      Text(
        'Días Completados: $completedDays de $totalDays',
        style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
      ),
      const SizedBox(height: 8),
      Text(
        'Días restantes: $remainingDays',
        style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
      ),
      const SizedBox(height: 15),
      LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.grey.shade200,
        valueColor: AlwaysStoppedAnimation<Color>(habit.color),
        minHeight: 12,
        borderRadius: BorderRadius.circular(6),
      ),
    ],
  );
}
}