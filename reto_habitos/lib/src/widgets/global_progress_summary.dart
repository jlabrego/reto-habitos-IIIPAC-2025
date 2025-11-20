import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../models/habit.dart';

class GlobalProgressSummary extends StatelessWidget {
  final int totalCompletedDays;
  final int totalPossibleDays;

  const GlobalProgressSummary({
    super.key,
    required this.totalCompletedDays,
    required this.totalPossibleDays,
  });

  @override
  Widget build(BuildContext context) {
    // Si no hay retos activos, el progreso es 0.
    final double overallProgress = totalPossibleDays > 0
        ? totalCompletedDays / totalPossibleDays
        : 0.0;
    
    // Cálculo del porcentaje para mostrar en el centro del círculo
    final int overallPercentage = (overallProgress * 100).round();

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      child: Center(
        child: CircularPercentIndicator(
          radius: 65.0, 
          lineWidth: 12.0,
          percent: overallProgress,
          center: Text(
            "$overallPercentage%",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 26.0,
              color: Colors.deepPurple,
            ),
          ),
          progressColor: Colors.deepPurple.shade400,
          backgroundColor: Colors.deepPurple.shade100.withOpacity(0.5),
          circularStrokeCap: CircularStrokeCap.round,
        ),
      ),
    );
  }
}