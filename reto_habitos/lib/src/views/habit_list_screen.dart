import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Necesario para Firestore o mock
import '../models/habit.dart'; // Importa los modelos definidos previamente
import '../providers/habit_service.dart'; // Importa el servicio de datos
import 'habit_detail_screen.dart'; // Importa la pantalla de detalle

// --- INICIO DEL CÓDIGO ---

/// Pantalla principal que muestra el listado de hábitos del usuario.
class HabitListScreen extends StatelessWidget {
  final HabitService habitService;

  const HabitListScreen({super.key, required this.habitService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Tus Retos de 30 Días',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: StreamBuilder<List<Habit>>(
        // Escucha el stream de todos los hábitos
        stream: habitService.getHabitsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Error al cargar: ${snapshot.error}',
                    textAlign: TextAlign.center));
          }

          final habits = snapshot.data ?? [];

          if (habits.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              return _buildHabitCard(context, habit);
            },
          );
        },
      ),
      // Botón para añadir un nuevo hábito
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implementar navegación a HabitFormScreen
          _showMockAddHabit(context); 
        },
        backgroundColor: Colors.teal.shade400,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }

  // Widget para el estado vacío (cuando no hay hábitos)
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rocket_launch_rounded, size: 80, color: Colors.deepPurple.shade200),
            const SizedBox(height: 20),
            const Text(
              '¡Aún no tienes hábitos!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Presiona el botón "+" para empezar tu primer reto de 30 días.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para mostrar la tarjeta de cada hábito
  Widget _buildHabitCard(BuildContext context, Habit habit) {
    // Calculamos el progreso (para un indicador simple)
    // Para simplificar, asumiremos que se completan 10 días de 30 para el ejemplo
    // En una aplicación real, esto requeriría una consulta adicional de Firestore.
    const mockCompletedDays = 10;
    const totalDays = 30;
    final progress = mockCompletedDays / totalDays;
    final remainingDays = totalDays - mockCompletedDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: habit.color.withOpacity(0.5), width: 1.5),
      ),
      elevation: 5,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          // Navega a la pantalla de detalle, pasando el hábito y el servicio
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => HabitDetailScreen(
                habit: habit,
                habitService: habitService,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // Icono de color
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: habit.color.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getIconForCategory(habit.category), // Icono basado en la categoría
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 15),
              // Detalles del Hábito
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Meta diaria: ${habit.suggestedDurationMinutes} min | ${habit.category}',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    // Barra de Progreso
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(habit.color),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$remainingDays días restantes',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // Función simple para obtener iconos basados en la categoría
  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
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

  // Función para añadir un hábito
  void _showMockAddHabit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Añadir Hábito'),
        content: const Text('Aquí se abriría la pantalla/modal para crear un nuevo hábito.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}