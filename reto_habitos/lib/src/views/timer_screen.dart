import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../providers/habit_service.dart';
import '../widgets/time.dart'; 


class TimerScreen extends StatelessWidget {
  final String habitId; 
  final HabitService habitService;

  const TimerScreen({
    Key? key,
    required this.habitId,
    required this.habitService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Habit?>(
      stream: habitService.getHabitStream(habitId),
      builder: (context, snapshot) {
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Error al cargar el hábito.')),
          );
        }

        final habit = snapshot.data!;
        
        final String? colorHex = habit.colorHex;
        
        // 1. Usar un color por defecto si es null o inválido
        String cleanHex = colorHex != null && colorHex.startsWith('#')
            ? colorHex.substring(1) 
            : colorHex ?? '673AB7'; 

        // 2. Asegurar el prefijo FF (opacidad total) si solo tiene 6 caracteres (RRGGBB).
        if (cleanHex.length == 6) {
            cleanHex = 'FF$cleanHex';
        }

        // 3. Parsear la cadena como un número hexadecimal (radix: 16)
        final int colorValue = int.tryParse(cleanHex, radix: 16) ?? 0xFF673AB7;
        
        final Widget timerWidget = TimerLogicWidget(
            habit: habit,
            habitService: habitService,
        );
        
        return Scaffold(
          appBar: AppBar(
            title: Text('Cronómetro: ${habit.name}'),
            backgroundColor: Color(colorValue),
          ),
          body: timerWidget, // Usar el widget del cronómetro
        );
      },
    );
  }
}