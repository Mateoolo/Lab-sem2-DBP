import 'package:flutter/material.dart';
import '../api_service.dart';

class AddEstacionScreen extends StatefulWidget {
  const AddEstacionScreen({Key? key}) : super(key: key);

  @override
  State<AddEstacionScreen> createState() => _AddEstacionScreenState();
}

class _AddEstacionScreenState extends State<AddEstacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nombreController = TextEditingController();
  final _ubicacionController = TextEditingController();
  
  String _riesgoSeleccionado = 'SIN DATOS'; 
  bool _isSaving = false;

void _enviarFormulario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // LLAMADA CORREGIDA: Pasamos los parámetros sueltos tal como los pide tu api_service.dart
    bool exito = await ApiService().crearEstacion(
      int.parse(_idController.text.trim()),
      _nombreController.text.trim(),
      _ubicacionController.text.trim(),
      _riesgoSeleccionado, // Asegúrate de que esta variable sea la del Dropdown
    );

    if (mounted) {
      setState(() => _isSaving = false);
    }

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estación e informe de riesgo creados con éxito')),
      );
      Navigator.pop(context); // Regresa al Home y refresca la lista automáticamente
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Verifique si el ID ya existe en SQLite')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Estación de Monitoreo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _idController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ID de la Estación (Número único)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.fingerprint),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El ID numérico es obligatorio';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Ingrese un número entero válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Dispositivo / Sensor',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.router),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ubicacionController,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación / Ciudad',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.map),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La ciudad/ubicación es obligatoria';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _riesgoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Nivel Inicial de Alerta',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.waves),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'SIN DATOS', child: Text('SIN DATOS (Gris / Verde Claro)')),
                    DropdownMenuItem(value: 'NORMAL', child: Text('NORMAL (Verde Seguro)')),
                    DropdownMenuItem(value: 'ALERTA', child: Text('ALERTA (Amarillo Moderado)')),
                    DropdownMenuItem(value: 'PELIGRO', child: Text('PELIGRO (Rojo Crítico)')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _riesgoSeleccionado = value);
                    }
                  },
                ),
                const SizedBox(height: 28),
                _isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _enviarFormulario,
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Subir y Conectar Estación'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}