import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:reto_habitos/src/models/habit.dart';
import 'package:reto_habitos/src/views/login_page.dart';
import 'package:reto_habitos/src/views/register.dart';
import 'firebase_options.dart';
import 'src/views/habit_detail_screen.dart';
import 'src/views/welcome_page.dart';
import 'src/views/habit_list_screen.dart';
import 'src/providers/habit_service.dart';
import 'src/views/admin_habit_page.dart';
import 'src/views/timer_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  MyApp({super.key});

  

  late final GoRouter _router = GoRouter(
    
    //initialLocation: '/welcome',
    redirect: (context, state) {
          final user = FirebaseAuth.instance.currentUser;

          final freeRoutes = ['/register', '/login'];

          if (user == null && !freeRoutes.contains(state.fullPath)) {
            return '/welcome';
          }

          return null;
        },

    initialLocation: '/welcome',

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
        path: '/login',
        name: 'login-page',
        builder: (context, state) {
          return LoginPage();
        } ),

      // 1. Lista de hábitos para usuarios autentificados
      GoRoute(

         path: '/habits',
         name: 'habit-list',
         builder: (context, state) {
          //Obtener usuario autenticado
          final user = FirebaseAuth.instance.currentUser;

          if (user == null) {
            //Si no hay usuario, redirigir al login
            context.go('/login');
            return const SizedBox(); // Widget vacío temporal
          }

          //servicio con el userId del usuario autenticado
          final habitService = HabitService(userId: user.uid);
          return HabitListScreen(habitService: habitService);
        },

        routes: [

          // 2. Detalle de un hábito: /habits/:id
          GoRoute(
            path: ':id',
            name: 'habit-detail',
            builder: (context, state) {
              final habitId = state.pathParameters['id']!;
              //Usuario autenticado
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                context.go('/login');
                return const SizedBox();
              }

              final habitService = HabitService(userId: user.uid);

              return HabitDetailScreen(
                habitId: habitId,
                habitService: habitService,
              );
            },

            //Sub-rutas del Detalle
            routes: [ 

              //Cronómetro del hábito: /habits/:id/timer
              GoRoute(
                path: 'timer', 
                name: 'habit-timer',
                builder: (context, state) {
                  final habitId = state.pathParameters['id']!;

                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    context.go('/login');
                    return const SizedBox();
                  }

                  final habitService = HabitService(userId: user.uid);

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

          //Obtener el usuario autenticado
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            context.go('/login');
            return const SizedBox();
          }
          
          final habitService = HabitService(userId: user.uid);

          return HabitFormScreen(habitService: habitService);
        },
      ),

      // 4. Modificar hábito
      GoRoute(
        path: '/update',
        name: 'update-habit',
        builder: (context, state) {
           //Obtener el usuario autenticado
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            context.go('/login');
            return const SizedBox();
          }
          
          final habitService = HabitService(userId: user.uid);

          final habit = state.extra as Habit?;
    
          return HabitFormScreen(
          habitService: habitService,
          habit: habit, //Pasar el hábito al formulario
    );    
        },
      ),
    ],
  );
  


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
      debugShowCheckedModeBanner: false,
    );
  }
}