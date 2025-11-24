import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:go_router/go_router.dart';
import '../models/habit.dart';
import '../providers/habit_service.dart';
import 'package:reto_habitos/src/widgets/custom_Scaffold.dart';

class HabitFormScreen extends StatefulWidget {
  const HabitFormScreen({
    super.key, 
    required this.habitService,
    this.habit // Si viene habit es edición
  });

  final HabitService habitService;
  final Habit? habit;

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _category = 'Salud';
  String _description = '';
  int _duration = 10;
  Color _selectedColor = Colors.deepPurple;

  final List<String> _categories = [
    'Salud',
    'Estudio',
    'Productividad',
    'Finanzas',
    'Otro',
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initialForm();
  }

  void _initialForm() {
    // Si estamos editando llenar los campos con datos existentes
    if (widget.habit != null) {
      _name = widget.habit!.name;
      _description = widget.habit!.description ?? "";
      _duration = widget.habit!.duration;
      _category = widget.habit!.category;
      _selectedColor = Color(int.parse(widget.habit!.colorHex, radix: 16));
    }
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selecciona un color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() => _selectedColor = color);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSaving = true);

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final String colorString = _selectedColor.value.toRadixString(16).padLeft(8, '0');

    // Preservar la fecha de creación original si estamos editando
    final createdAt = widget.habit?.createdAt ?? DateTime.now();
    final streak = widget.habit?.streak ?? 0;

    final habit = Habit(
      id: widget.habit?.id ?? id,
      name: _name,
      category: _category,
      duration: _duration,
      createdAt: createdAt,
      description: _description,
      streak: streak,
      colorHex: colorString,
    );

    try {
      // Crear o actualizar
      if (widget.habit == null) {
        await widget.habitService.addHabit(habit);
      } else {
        await widget.habitService.updateHabit(habit);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.habit == null 
                ? "Hábito creado con éxito" 
                : "Hábito actualizado con éxito"
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al guardar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.habit != null;

    return CustomScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // HEADER MEJORADO
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isEditing ? 'Editar Hábito' : 'Crear Nuevo Hábito',
                    style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          // FORMULARIO
          Expanded(
            flex: 7,
            child: Container(
              padding: const EdgeInsets.fromLTRB(25.0, 40.0, 25.0, 20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // NOMBRE
                      _buildSectionTitle('Nombre del hábito'),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _name,
                        decoration: _inputDecoration(
                          hintText: 'Ej: Meditación, Ejercicio, Lectura...',
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? "Ingrese un nombre" : null,
                        onSaved: (value) => _name = value!,
                      ),

                      const SizedBox(height: 25),

                      // CATEGORÍA
                      _buildSectionTitle('Categoría'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration(),
                        value: _category,
                        items: _categories
                            .map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(
                                    cat,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _category = value!),
                      ),

                      const SizedBox(height: 25),

                      // DESCRIPCIÓN
                      _buildSectionTitle('Descripción (opcional)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _description,
                        decoration: _inputDecoration(
                          hintText: 'Describe tu hábito...',
                        ),
                        maxLines: 3,
                        onSaved: (value) => _description = value ?? '',
                      ),

                      const SizedBox(height: 25),

                      // DURACIÓN
                      _buildSectionTitle('Minutos por día'),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _duration.toString(),
                        decoration: _inputDecoration(
                          hintText: '10',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Ingrese un número";
                          }
                          final n = int.tryParse(value);
                          if (n == null || n <= 0) {
                            return "Ingrese un valor válido";
                          }
                          return null;
                        },
                        onSaved: (value) => _duration = int.parse(value!),
                      ),

                      const SizedBox(height: 25),

                      // COLOR
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle('Color del hábito'),
                          GestureDetector(
                            onTap: _pickColor,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _selectedColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.color_lens,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      Text(
                        'Toca el ícono para cambiar el color',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // BOTÓN GUARDAR
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 30,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 4,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isEditing ? "Actualizar Hábito" : "Crear Hábito",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGETS AUXILIARES
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1F2937),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: const Color(0xFFB0B0B0), fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}