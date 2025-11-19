import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/habit.dart';
import '../providers/habit_service.dart';
import '../widgets/global_progress_summary.dart';

class HabitListScreen extends StatelessWidget {
  final HabitService habitService;

  const HabitListScreen({super.key, required this.habitService});

  // 1. Método auxiliar para íconos
  IconData _getIconForCategory(String description) {
    switch (description.toLowerCase()) {
    case 'salud': 
      return Icons.fitness_center_rounded;
    case 'estudio': 
      return Icons.book_rounded;           
    case 'productividad': 
      return Icons.work_outline_rounded; 
    case 'finanzas': 
      return Icons.account_balance_wallet_rounded; 
    default: 
      return Icons.local_activity_rounded;
    }
  }


  Widget _buildHabitCard(BuildContext context, Habit habit) {
    
    final String? hex = habit.colorHex;
    const int defaultColorValue = 0xFF673AB7; 

    int colorValue;
    if (hex != null) {
      if (hex.length == 6) {
        colorValue = int.tryParse('FF$hex', radix: 16) ?? defaultColorValue;
      } else if (hex.length >= 8) {
        // AARRGGBB -> Usar tal cual
        colorValue = int.tryParse(hex, radix: 16) ?? defaultColorValue;
      } else {
        colorValue = defaultColorValue;
      }
    } else {
      colorValue = defaultColorValue;
    }
    
    final Color habitColor = Color(colorValue);
    

    return StreamBuilder<int>(
      stream: habitService.getCompletedDaysCountStream(habit.id), 
      builder: (context, countSnapshot) {
        final completedDays = countSnapshot.data ?? habit.daysCompleted; 
        const totalDays = 30;
        final progress = completedDays / totalDays;
        final remainingDays = totalDays - completedDays;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 3,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              // Navegación a la pantalla de detalle
              context.pushNamed(
                'habit-detail',
                pathParameters: {'id': habit.id},
                extra: habit,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: habitColor.withOpacity(0.15), 
                      borderRadius: BorderRadius.circular(12)),
                    child: Icon(
                      _getIconForCategory(habit.category), 
                      color: habitColor, 
                      size: 30
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(habit.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
                        const SizedBox(height: 3),
                        Text('Meta diaria: ${habit.duration} min', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.shade200,
                          color: progress >= 1.0 ? Colors.green.shade400 : habitColor,
                          minHeight: 6, borderRadius: BorderRadius.circular(3),
                        ),
                        const SizedBox(height: 5),
                        Text('$remainingDays días restantes ($completedDays completados)', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _buildBottomNavBar(BuildContext context) { /* ... */ return Container(height: 60); }
  Widget _buildEmptyState(BuildContext context) { /* ... */ return const Center(child: Text('No hay retos activos.')); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Tus Retos de 30 Días', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.grey.shade50, elevation: 0, centerTitle: true,
      ),
      body: StreamBuilder<List<Habit>>(
        stream: habitService.getHabitsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final habits = snapshot.data ?? [];
          if (habits.isEmpty) return _buildEmptyState(context);

          // Lógica de cálculo de progreso global
          final int totalCompletedDays = habits.fold<int>(0, (sum, habit) => sum + habit.daysCompleted);
          final int totalPossibleDays = habits.length * 30;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: GlobalProgressSummary(
                  totalCompletedDays: totalCompletedDays,
                  totalPossibleDays: totalPossibleDays,
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 10, 16, 5),
                  child: Text('Retos Activos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.builder(
                  itemCount: habits.length,
                  itemBuilder: (context, index) {
                    final habit = habits[index];
                    return _buildHabitCard(context, habit);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('add-habit'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }
}