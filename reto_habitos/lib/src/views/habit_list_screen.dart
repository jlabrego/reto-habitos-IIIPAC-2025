import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reto_habitos/src/shared/utils.dart';
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
        colorValue = int.tryParse(hex, radix: 16) ?? defaultColorValue;
      } else {
        colorValue = defaultColorValue;
      }
    } else {
      colorValue = defaultColorValue;
    }
    
    final Color habitColor = Color(colorValue);
    
    // Garantiza que la tarjeta lea el conteo de la subcolección.
    return StreamBuilder<int>(
      stream: habitService.getCompletedDaysCountStream(habit.id), 
      builder: (context, countSnapshot) {
        
        // Usar 0 como valor de respaldo si el Stream aún no tiene datos.
        final completedDays = countSnapshot.data ?? 0; 
        const totalDays = 30;
        final progress = completedDays / totalDays;
        final remainingDays = totalDays - completedDays;

        return Dismissible(
          key: Key(habit.id),
          confirmDismiss: (direction) async {
            if(direction==DismissDirection.startToEnd){

              //Para eliminar
              return await Utils.showConfirm(context: context,
              confirmButton: () {

                habitService.deleteHabit(habit.id);

                if (!context.mounted) return;
                context.pop();
               },              
              );
            }
            //? Para actualizar
            if (direction == DismissDirection.endToStart) {
              context.pushNamed(
                'update-habit',
                 extra: habit,
              );
              return false;
            }    
            return null;
          },

          background: Container(
                  padding: EdgeInsets.only(left: 16),
                  color: Colors.red,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red[50],
                      size: 30,
                    ),
                  ),
                ),
                
          secondaryBackground: Container(
                  padding: EdgeInsets.only(right: 16),
                  color: Colors.blue,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Modificar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[50],
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(
                        Icons.edit_outlined,
                        color: Colors.blue[50],
                        size: 30,
                      ),
                    ],
                  ),
                ),
          
          child: Card(
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
                          //Usa los valores calculados con el Stream:
                          Text('$remainingDays días restantes ($completedDays completados)', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 30),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildBottomNavBar(BuildContext context) {
    return Container(height: 0); 
  }
  
  Widget _buildEmptyState(BuildContext context) { 
    return const Center(child: Text('No hay retos activos.')); 
  }

  Widget _buildAppDrawer(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'Usuario';
    final userEmail = user?.email ?? 'Sin correo';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Cabecera del Drawer (Muestra info del usuario logueado)
          UserAccountsDrawerHeader(
            accountName: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 30, color: Colors.deepPurple),
              ),
            ),
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
            ),
          ),
          
          // Opción de Configuración/Perfil
          ListTile(
            leading: const Icon(Icons.account_circle_rounded),
            title: const Text('Mi Perfil',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              Navigator.pop(context);  
              Utils.showSnackBar(context:context, title: 'Navegar a Perfil...');
            },
          ),
          
          // Opción de Estadísticas Globales
          ListTile(
            leading: const Icon(Icons.bar_chart_rounded),
            title: const Text('Estadísticas',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              Navigator.pop(context); 
              // context.pushNamed('statistics'); 
              Utils.showSnackBar(context:context , title: 'Navegar a Estadísticas...');
            },
          ),
          
          const Divider(),
          
          // Opción de Cerrar Sesión
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onTap: () async {
              // Cierra el drawer
              Navigator.pop(context); 
              
              // Cierra la sesión de Firebase
              await FirebaseAuth.instance.signOut();
              
              // Redirige al usuario a la pantalla de Login/Home
              context.go('/'); // Redirige a la ruta raíz (Login/Splash)
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      drawer: _buildAppDrawer(context),
      appBar: AppBar(
        title: const Text('Tus Retos de 30 Días', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.grey.shade50, elevation: 0, centerTitle: true,
      ),
      
      //CORRECCIÓN: Habits como StreamBuilder PRINCIPAL
    body: StreamBuilder<List<Habit>>(
      stream: habitService.getHabitsStream(),
      builder: (context, habitSnapshot) {
        
        //Solo muestra la carga la primera vez:
        if (habitSnapshot.connectionState == ConnectionState.waiting &&
        !habitSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final habits = habitSnapshot.data ?? [];
        if (habits.isEmpty) return _buildEmptyState(context);

        //CORRECCIÓN: Progress como StreamBuilder SECUNDARIO
        return StreamBuilder<Map<String, int>>(
          stream: habitService.getGlobalProgressSummary(),
          builder: (context, globalSnapshot) {
            final completed = globalSnapshot.data?['completed'] ?? 0;
            final possible = globalSnapshot.data?['possible'] ?? 0;

              return CustomScrollView(
                slivers: [
                  // Usa los valores del Stream Global
                  SliverToBoxAdapter(
                    child: GlobalProgressSummary(
                      totalCompletedDays: completed, 
                      totalPossibleDays: possible,    
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