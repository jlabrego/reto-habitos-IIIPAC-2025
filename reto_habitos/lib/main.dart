import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:reto_habitos/src/views/login_page.dart';
import 'package:reto_habitos/src/views/register.dart';
import 'firebase_options.dart';
import 'src/views/habit_detail_screen.dart';
import 'src/views/welcome_page.dart';
import 'src/views/habit_list_screen.dart';
import 'src/providers/habit_service.dart';
import 'src/widgets/create_habit_form.dart';
import 'src/views/timer_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final HabitService habitService = HabitService();
  
  late final GoRouter _router = GoRouter(
    initialLocation: '/habits',

    routes: [
      //Pantalla de Bienvenida
      GoRoute(
        path: '/welcome',
        name: 'welcome-page',
        builder: (context, state) {
          return WelcomePage();
        } ),
        GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) {
          return Register();
        } ),
        //Pagina de inicio de sesion
        GoRoute(
        path: '/login-page',
        name: 'login',
        builder: (context, state) {
          return LoginPage();
        } ),
      // 1. Lista de hábitos
      GoRoute(
         path: '/habits',
         name: 'habit-list',
         builder: (context, state) {
          return HabitListScreen(habitService: habitService);
        },
        routes: [
          // 2. Detalle de un hábito: /habits/:id
          GoRoute(
            path: ':id',
            name: 'habit-detail',
            builder: (context, state) {
              final habitId = state.pathParameters['id']!;
              return HabitDetailScreen(
                habitId: habitId,
                habitService: habitService,
              );
            },
            //Sub-rutas del Detalle
            routes: [ 
              // 4. Cronómetro del hábito: /habits/:id/timer
              GoRoute(
                path: 'timer', 
                name: 'habit-timer',
                builder: (context, state) {
                  final habitId = state.pathParameters['id']!;
                  
                  return TimerScreen(
                    habitId: habitId,
                    habitService: habitService,
                  );
                },
              ),
            ],
          ),
        ],
      ),

      // 3. Crear hábito
      GoRoute(
        path: '/add-habit',
        name: 'add-habit',
        builder: (context, state) {
          return HabitFormScreen(habitService: habitService);
        },
      ),
    ],
  );
  
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Reto Hábitos 30 Días',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.grey.shade50,
      ),
      routerConfig: _router,
    );
  }
}