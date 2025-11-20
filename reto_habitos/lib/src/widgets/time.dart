import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../models/habit.dart';
import '../providers/habit_service.dart';
import '../models/day_progress.dart';

// Extensión para manipular colores (lighten/darken)
extension ColorManipulation on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  Color lighten([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }
}

class TimerLogicWidget extends StatefulWidget {
  final Habit habit;
  final HabitService habitService;

  const TimerLogicWidget({
    Key? key,
    required this.habit,
    required this.habitService,
  }) : super(key: key);

  @override
  State<TimerLogicWidget> createState() => _TimerLogicWidgetState();
}

class _TimerLogicWidgetState extends State<TimerLogicWidget> {
  late StreamSubscription<DayProgress?> _progressSubscription;
  Timer? _timer;

  int _totalSecondsSpentToday = 0;
  int _currentSessionSeconds = 0;
  bool _isRunning = false;

  late int _requiredSeconds;
  late Color _habitColor; 

  @override
  void initState() {
    super.initState();
    _requiredSeconds = widget.habit.duration * 60;
    _habitColor = _getHabitColor(widget.habit); 
    _initializeProgressStream(); 
  }

  void _initializeProgressStream() {
    _progressSubscription = widget.habitService
        .getTodayProgressStream(widget.habit.id)
        .listen((progress) {
      if (progress != null) {
        setState(() {
          _totalSecondsSpentToday = progress.timeSpentSeconds;
          if (progress.isCompleted && _isRunning) { 
            _handleCompletion();
          }
        });
      }
    });
  }

  Color _getHabitColor(Habit habit) {
      final String? hex = habit.colorHex;
      const int defaultColorValue = 0xFF673AB7; 
      const Color defaultColor = Color(defaultColorValue);

      if (hex == null || hex.isEmpty || hex.toLowerCase().contains('seleccionado')) {
          return defaultColor; 
      }

      int colorValue;
      try {
          String cleanHex = hex.startsWith('#') ? hex.substring(1) : hex;
          colorValue = int.parse(cleanHex.length == 6 ? 'FF$cleanHex' : cleanHex, radix: 16);
          return Color(colorValue);
      } catch (e) {
          return defaultColor;
      }
  }


  void _startTimer() {
    if (_isRunning) return;
    if ((_totalSecondsSpentToday + _currentSessionSeconds) >= _requiredSeconds) return;

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentSessionSeconds++;
        
        if ((_totalSecondsSpentToday + _currentSessionSeconds) >= _requiredSeconds) {
            _handleCompletion();
        }
      });
    });
  }

  // Al parar/pausar, se registra el progreso.
  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
    // Registra automáticamente el progreso al pausar/detener.
    _registerProgress(showSuccessSnackBar: false); 
  }
  
  // FUNCIÓN REINICIAR: Reinicia la sesión actual (descartando el tiempo)
  void _resetSession() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      // Esto pone a cero la sesión actual, pero respeta el progreso guardado (_totalSecondsSpentToday)
      _currentSessionSeconds = 0; 
    });
     ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión actual descartada.')));
  }

  void _handleCompletion() {
    _stopTimer(); 
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Meta diaria completada! 🎉')));
  }

  // Registra el tiempo acumulado de la sesión actual y la reinicia
  void _registerProgress({bool showSuccessSnackBar = false}) async {
    // Si no se corrió el cronómetro, no hacemos nada 
    if (_currentSessionSeconds == 0) return; 
    
    final newTotalSeconds = _totalSecondsSpentToday + _currentSessionSeconds;
    
    await widget.habitService.completeTodayWithTime(
      widget.habit.id,
      newTotalSeconds,
      widget.habit.duration,
    );

    // Reinicia la sesión actual después de registrarla
    setState(() {
      _currentSessionSeconds = 0; 
    });
    
    if (showSuccessSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Progreso registrado y sesión reiniciada: ${_formatTimeShort(newTotalSeconds)}')));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    
    // Guardado automático al salir 
    if (_currentSessionSeconds > 0) {
       _registerProgress(showSuccessSnackBar: false); 
    }
    
    _progressSubscription.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTimeShort(int totalSeconds) {
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes} m ${seconds} s';
  }


  @override
  Widget build(BuildContext context) {
    final currentTotal = _totalSecondsSpentToday + _currentSessionSeconds;
    final isGoalMet = currentTotal >= _requiredSeconds;
    final double progressValue = _requiredSeconds > 0 ? (currentTotal / _requiredSeconds).clamp(0.0, 1.0) : 0.0;
    
    final Color baseColor = _habitColor;
    final Color startGradientColor = baseColor.lighten(0.3);
    final Color endGradientColor = baseColor.darken(0.3);

    final String name = widget.habit.name;

    return Scaffold(
      backgroundColor: Colors.white, 
      
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[

              // TÍTULO DEL HÁBITO
              Text(
                name.length > 20 ? name.substring(0, 18) + '...' : name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87, 
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Meta diaria: ${widget.habit.duration} minutos',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 40),

              // CÍRCULO DE PROGRESO CON CircularPercentIndicator Y GRADIENTE
              SizedBox(
                width: 320, 
                height: 320,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100, 
                        shape: BoxShape.circle,
                      ),
                    ),
                    
                    CircularPercentIndicator(
                      radius: 120.0, 
                      lineWidth: 25.0, 
                      percent: progressValue,
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Text(
                              _formatTimeShort(_requiredSeconds),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _formatTime(currentTotal),
                              style: const TextStyle(
                                fontSize: 85, 
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_none_rounded, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 5),
                                Text(
                                  _formatTimeShort(_requiredSeconds), 
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                      ),
                      linearGradient: LinearGradient( 
                        colors: [startGradientColor, endGradientColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      backgroundColor: Colors.grey.shade200, 
                      circularStrokeCap: CircularStrokeCap.round,
                    ),

                    // INDICADOR DE FINALIZACIÓN
                    Positioned(
                      top: 1, 
                      child: Transform.translate(
                        offset: const Offset(0, -12.5), 
                        child: progressValue > 0.99 
                            ? Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade600, 
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3), 
                                ),
                              )
                            : Container( 
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: startGradientColor, 
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 60),

              // BOTONES DE CONTROL (Reiniciar y Play/Pause)
              Row(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  // Botón Izquierdo (Reiniciar/Resetear)
                   FloatingActionButton(
                    onPressed: _resetSession, 
                    heroTag: 'reset_tag',
                    backgroundColor: Colors.grey.shade300,
                    child: Icon(Icons.refresh_rounded, size: 30, color: Colors.grey.shade800),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Botón Principal (Resume/Pause/Start)
                  FloatingActionButton.extended(
                    onPressed: isGoalMet ? null : (_isRunning ? _stopTimer : _startTimer),
                    heroTag: 'play_pause_tag', 
                    backgroundColor: isGoalMet ? Colors.green.shade600 : (_isRunning ? Colors.red.shade600 : baseColor),
                    foregroundColor: Colors.white,
                    label: Text(
                      isGoalMet ? "COMPLETADO" : (_isRunning ? "PAUSAR" : "INICIAR"), 
                      style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
                    icon: Icon(
                      isGoalMet ? Icons.check_circle_outline : (_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded), 
                      size: 28
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              
              // TIEMPO DE SESIÓN ACTUAL
              if (_isRunning || _currentSessionSeconds > 0)
                Text(
                  'Sesión Actual: ${_formatTimeShort(_currentSessionSeconds)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
            ],
          ),
        ),
      ),
    );
  }
}