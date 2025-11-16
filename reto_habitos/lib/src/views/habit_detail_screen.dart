import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit.dart';
import '../providers/habit_service.dart';

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;
  final HabitService habitService;

  const HabitDetailScreen({
    super.key,
    required this.habit,
    required this.habitService,
  });

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  int _currentTimeSeconds = 0;
  Timer? _timer;
  bool _isRunning = false;
  DayProgress? _todayProgress;
  // Suscripción al progreso de hoy para que la UI se actualice
  late final StreamSubscription<DayProgress?> _progressSubscription;

  @override
  void initState() {
    super.initState();
    // 1. Inicializa el listener para el progreso de hoy.
    _progressSubscription = widget.habitService
        .getTodayProgressStream(widget.habit.id) // Corregido: pasar solo el ID
        .listen((progress) {
      final today = DateTime.now();
      // Calcula el ID del día basado en la fecha de inicio del reto.
      final daysSinceStart = today.difference(widget.habit.startDate).inDays;
      final dayId = 'day-${daysSinceStart + 1}';

      setState(() {
        // Si no hay progreso en Firestore, crea un objeto DayProgress vacío para hoy.
        _todayProgress = progress ?? DayProgress(
          id: dayId,
          date: DateTime(today.year, today.month, today.day),
          timeSpentSeconds: 0,
          isCompleted: false,
        );
        _currentTimeSeconds = _todayProgress!.timeSpentSeconds;
        // Detiene el timer si ya está completado (evita que el usuario inicie si ya acabó)
        if (_todayProgress!.isCompleted) {
          _stopTimer(save: false);
        }
      });
    });
  }

  void _startTimer() {
    if (_todayProgress == null || _todayProgress!.isCompleted) return;
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTimeSeconds++;
          // Chequea si se alcanzó la meta de minutos
          if (_currentTimeSeconds >= widget.habit.suggestedDurationMinutes * 60) {
            _stopTimer(save: true, completed: true);
          }
        });
      }
    });
  }

  // LÓGICA DE LA PERSONA 1
  Future<void> _stopTimer({required bool save, bool completed = false}) async {
    if (_timer != null) {
      _timer!.cancel();
    }
    setState(() {
      _isRunning = false;
    });

    if (save && _todayProgress != null) {
      final newProgress = DayProgress(
        id: _todayProgress!.id,
        date: _todayProgress!.date,
        timeSpentSeconds: _currentTimeSeconds,
        isCompleted: completed,
      );
      // Llama al servicio para guardar el progreso en Firestore
      // El ID del hábito debe ser una String
      await widget.habitService.saveDayProgress(widget.habit.id, newProgress);
    }
  }

  //: Permite marcar/desmarcar manualmente como completado
  void _toggleCompleted(bool isCompleted) {
    if (_todayProgress == null) return;
    _stopTimer(save: false);

    // Si se marca como completado, establece el tiempo al total sugerido.
    final newTime = isCompleted
        ? widget.habit.suggestedDurationMinutes * 60
        : _currentTimeSeconds;

    final newProgress = DayProgress(
      id: _todayProgress!.id,
      date: _todayProgress!.date,
      timeSpentSeconds: newTime,
      isCompleted: isCompleted,
    );
    // El ID del hábito debe ser una String
    widget.habitService.saveDayProgress(widget.habit.id, newProgress);
  }

  
  @override
  void dispose() {
    // Asegura guardar el tiempo si el usuario sale de la pantalla mientras corre
    _stopTimer(save: true); 
    _progressSubscription.cancel(); // Cierra el listener del stream
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  // **********************************************
  // (Diseño/Estilo)
  // **********************************************

  @override
  Widget build(BuildContext context) {
    final totalSeconds = widget.habit.suggestedDurationMinutes * 60;
    // Calcula el progreso como un valor entre 0.0 y 1.0 para el indicador circular
    final progressValue =
        _currentTimeSeconds.toDouble().clamp(0, totalSeconds.toDouble()) / totalSeconds;
    final percentage = (progressValue * 100).toInt();

    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco para un look limpio
      appBar: AppBar(
        title: Text(widget.habit.name,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Indicador Circular
            _buildHabitStatus(percentage, totalSeconds, progressValue),
            const SizedBox(height: 30),
            // 2. Temporizador y Controles
            _buildTimerSection(),
            const SizedBox(height: 30),
            // 3. Cuadrícula de 30 Días
            _buildProgressGrid(context),
          ],
        ),
      ),
    );
  }

  // Diseño del estado de progreso (Indicador Circular - ESTILO MODERNO)
  Widget _buildHabitStatus(
      int percentage, int totalSeconds, double progressValue) {
    final isCompleted = _todayProgress?.isCompleted ?? false;
    final primaryColor = isCompleted ? Colors.green.shade600 : Colors.deepPurple;
    
    return Container(
      padding: const EdgeInsets.all(25.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4), 
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Meta Diaria: ${widget.habit.suggestedDurationMinutes} minutos',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200, // Tamaño aumentado
                height: 200,
                child: CircularProgressIndicator(
                  value: progressValue,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isCompleted ? '100%' : '$percentage%',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isCompleted ? 'Logro de Hoy' : 'Progreso',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Tiempo Invertido: ${_formatTime(_currentTimeSeconds)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Diseño de los controles del temporizador
  Widget _buildTimerSection() {
    final isCompleted = _todayProgress?.isCompleted ?? false;
    final primaryColor = isCompleted ? Colors.green.shade600 : Colors.deepPurple;

    return Column(
      children: [
        // El formato de tiempo simple
        Text(
          _formatTime(_currentTimeSeconds),
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.w200,
            color: primaryColor,
            fontFamily: 'monospace', // Usa fuente monoespaciada para el reloj
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Botón INICIAR
            if (!_isRunning && !isCompleted)
              _buildTimerButton(
                icon: Icons.play_arrow_rounded,
                label: 'INICIAR',
                color: Colors.green.shade600,
                onPressed: _startTimer,
              ),
            // Botón PAUSAR
            if (_isRunning && !isCompleted)
              _buildTimerButton(
                icon: Icons.pause_rounded,
                label: 'PAUSAR',
                color: Colors.amber.shade700,
                onPressed: () => _stopTimer(save: true),
              ),
            // Botón GUARDAR (si el tiempo no está corriendo y ya tiene tiempo registrado)
            if (!_isRunning && _currentTimeSeconds > 0 && !isCompleted)
              _buildTimerButton(
                icon: Icons.save_alt_rounded,
                label: 'GUARDAR',
                color: Colors.deepPurple,
                onPressed: () => _stopTimer(save: true),
              ),
            // Botón DESHACER (si ya está completado)
            if (isCompleted)
              _buildTimerButton(
                icon: Icons.restart_alt_rounded,
                label: 'REINICIAR',
                color: Colors.red.shade400,
                onPressed: () => _toggleCompleted(false),
              ),
          ],
        ),
      ],
    );
  }

  // Widget auxiliar para los botones (Mejor estilo visual)
  Widget _buildTimerButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white, size: 24),
      label: Text(label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // Cápsula
        elevation: 5,
      ),
    );
  }

  // Diseño de la Cuadrícula de Progreso (30 Días - ESTILO MODERNO)
  Widget _buildProgressGrid(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50, // Fondo ligero
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progreso del Reto (30 Días)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
          const SizedBox(height: 10),
          // StreamBuilder lee TODO el progreso del hábito
          StreamBuilder<List<DayProgress>>(
            stream: widget.habitService.getProgressStream(widget.habit.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Text('Cargando progreso...'));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                // Genera un mapa vacío si no hay datos
                final emptyProgressMap = <String, DayProgress>{};
                return _buildGrid(emptyProgressMap);
              }

              // Convierte la lista de DayProgress en un mapa para acceso rápido (ID del día -> Progreso)
              final progressMap = {
                for (var progress in snapshot.data!)
                  progress.id: progress
              };

              return _buildGrid(progressMap);
            },
          ),
        ],
      ),
    );
  }
  
  // Widget auxiliar para construir el GridView
  Widget _buildGrid(Map<String, DayProgress> progressMap) {
    // Calculamos el índice del día actual basado en la fecha de inicio
    final today = DateTime.now();
    final daysSinceStart = today.difference(widget.habit.startDate).inDays;
    final todayDayNumber = daysSinceStart + 1;


    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6, // 6 columnas para un look compacto
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
      ),
      itemCount: 30, // Siempre 30 días
      itemBuilder: (context, index) {
        final dayNumber = index + 1;
        final dayId = 'day-$dayNumber';
        final progress = progressMap[dayId];
        final isCompleted = progress?.isCompleted ?? false;

        // Determina si el día es pasado, presente o futuro
        final isToday = dayNumber == todayDayNumber;
        final isPast = dayNumber <= todayDayNumber;

        Color backgroundColor = Colors.white;
        Color textColor = Colors.black54;
        
        if (isCompleted) {
          backgroundColor = Colors.green.shade400; // Verde si completado
          textColor = Colors.white;
        } else if (isToday) {
          backgroundColor = Colors.deepPurple.shade200; // Morado claro para HOY
          textColor = Colors.deepPurple.shade900;
        } else if (isPast && !isCompleted) {
          backgroundColor = Colors.red.shade100; // Rojo claro si está perdido/pendiente
        } else {
          // Día futuro
          textColor = Colors.grey.shade400;
          backgroundColor = Colors.grey.shade100;
        }

        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isToday
                  ? Colors.deepPurple.shade700 // Borde morado oscuro para HOY
                  : Colors.transparent,
              width: isToday ? 2.5 : 0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$dayNumber',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}