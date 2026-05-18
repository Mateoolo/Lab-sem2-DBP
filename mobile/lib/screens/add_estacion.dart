import 'package:flutter/material.dart';
import '../api_service.dart';

class AddEstacionScreen extends StatefulWidget {
  const AddEstacionScreen({super.key});

  @override
  State<AddEstacionScreen> createState() => _AddEstacionScreenState();
}

class _AddEstacionScreenState extends State<AddEstacionScreen> {
  final _idController = TextEditingController();
  final _nombreController = TextEditingController();
  final _ubicacionController = TextEditingController();
  bool _isLoading = false;

  void _guardarEstacion() async {
    if (_idController.text.isEmpty || _nombreController.text.isEmpty || _ubicacionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, llena todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Parseamos el ID a número entero obligatoriamente
    int id = int.parse(_idController.text.trim());
    String nombre = _nombreController.text.trim();
    String ubicacion = _ubicacionController.text.trim();

    bool exito = await ApiService().crearEstacion(id, nombre, ubicacion);

    setState(() => _isLoading = false);

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estación registrada con éxito en la DB')),
      );
      Navigator.pop(context, true); // Regresa al HomePage y le avisa que recargue la lista
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No autorizado o formato inválido')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Estación - SMAT')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _idController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ID de la Estación (Número)'),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre de la Estación'),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _ubicacionController,
              decoration: const InputDecoration(labelText: 'Ubicación / Región'),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    onPressed: _guardarEstacion,
                    child: const Text('Guardar Estación'),
                  ),
          ],
        ),
      ),
    );
  }
}