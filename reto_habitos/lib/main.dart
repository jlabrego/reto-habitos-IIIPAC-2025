// main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
// Asume que tienes este archivo para la configuración de Firebase
import 'firebase_options.dart'; 

// Importaciones de tus archivos
import 'src/views/habit_detail_screen.dart'; 
import 'src/views/habit_list_screen.dart'; // NECESARIO para la ruta
import 'src/providers/habit_service.dart'; 

// --- Singleton de Servicio (Disponible Globalmente en Rutas) ---
// NOTA: Usamos una variable global para el servicio, ya que GoRouter no usa Provider 
// por defecto en la configuración de sus builders.
final HabitService habitService = FirestoreHabitService(); 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inicialización de Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 2. Ejecutar la aplicación con el configurador de rutas
  runApp(const HabitTrackerApp());
}

// --- Configuración de Rutas con GoRouter ---
final _router = GoRouter(
  initialLocation: '/habits',
  routes: [
    // 1. Ruta Principal: Lista de Hábitos
    GoRoute(
      path: '/habits',
      name: 'habit-list',
      builder: (context, state) {
        // Pasa el servicio al constructor de la pantalla
        return HabitListScreen(habitService: habitService);
      },
      routes: [
        // 2. Ruta de Detalle: /habits/:id
        GoRoute(
          path: ':id', 
          name: 'habit-detail',
          builder: (context, state) {
            // Extrae el ID del hábito de la URL
            final habitId = state.pathParameters['id']!;
            
            // NOTA: Para obtener el objeto 'Habit' completo, necesitarás
            // hacer una lectura síncrona o usar un FutureBuilder aquí.
            // Para mantenerlo simple, la pantalla de detalle usará el habitId
            // para cargar sus propios datos, como se hace en muchas apps con rutas.
            
            return HabitDetailScreen(
              // Necesitas cargar el hábito por ID. Por ahora, pasaremos un objeto vacío 
              // y dejaremos que la pantalla de detalle lo cargue.
              habit: state.extra as Habit, 
              habitService: habitService,
            );
          },
        ),
      ],
    ),
    
    // TODO: Ruta para Añadir Hábito (Formulario)
    GoRoute(
      path: '/add-habit',
      name: 'add-habit',
      builder: (context, state) => const Scaffold(
        appBar: AppBar(title: Text('Nuevo Hábito')),
        body: Center(child: Text('Aquí va HabitFormScreen')),
      ),
    ),
  ],
);

// El widget raíz usa MaterialApp.router
class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      title: '30 Días de Hábitos',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        // ... otros temas ...
        useMaterial3: true,
      ),
    );
  }
}