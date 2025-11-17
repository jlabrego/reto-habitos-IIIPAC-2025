import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/habit.dart';
import '../providers/habit_service.dart';

class HabitFormScreen extends StatefulWidget {
  final HabitService habitService;

  const HabitFormScreen({super.key, required this.habitService});

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _category = 'Salud';
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

    // Crear ID único
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final habit = Habit(
      id: id,
      name: _name,
      //category: _category,
      duration: _duration,
      createdAt: DateTime.now(), 
      description: 'Prueba', 
      streak: 0, 
      daysCompleted: 0,
      //color: _selectedColor,
    );

    try {
      await widget.habitService.addHabit(habit);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Hábito creado con éxito")),
        );
        Navigator.pop(context);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Hábito"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // NOMBRE
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Nombre del hábito",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Ingrese un nombre" : null,
                onSaved: (value) => _name = value!,
              ),

              const SizedBox(height: 15),

              // CATEGORÍA
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Categoría",
                  border: OutlineInputBorder(),
                ),
                value: _category,
                items: _categories
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _category = value!),
              ),

              const SizedBox(height: 15),

              // DURACIÓN
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Minutos por día",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                initialValue: "10",
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

              const SizedBox(height: 15),

              // COLOR
              Row(
                children: [
                  const Text(
                    "Color:",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _pickColor,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _selectedColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // BOTÓN GUARDAR
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Guardar hábito"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
