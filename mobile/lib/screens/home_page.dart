import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../api_service.dart';
import 'add_estacion.dart';
import 'login_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _futureEstaciones;

  @override
  void initState() {
    super.initState();
    _refreshEstaciones();
  }

  void _refreshEstaciones() {
    setState(() {
      _futureEstaciones = ApiService().getEstaciones();
    });
  }

  // RETO SOLUCIONADO: Función que decide el color del sensor en base al riesgo del Backend
  Color _obtenerColorRiesgo(String? riesgo) {
    switch (riesgo) {
      case 'PELIGRO':
        return Colors.red; // Riesgo crítico
      case 'ALERTA':
        return Colors.amber; // Riesgo intermedio (Amarillo)
      case 'NORMAL':
      default:
        return Colors.green; // Todo bajo control
    }
  }

  // DIÁLOGO UX: Ventana emergente para editar los campos de la estación
  void _mostrarDialogoEditar(Map<String, dynamic> estacion) {
    final nombreCtrl = TextEditingController(text: estacion['nombre']);
    final ubicacionCtrl = TextEditingController(text: estacion['ubicacion']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Editar Estación: ID ${estacion['id']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre")),
            TextField(controller: ubicacionCtrl, decoration: const InputDecoration(labelText: "Ubicación")),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              bool ok = await ApiService().editarEstacion(
                estacion['id'],
                nombreCtrl.text,
                ubicacionCtrl.text,
              );
              if (ok && mounted) {
                Navigator.pop(context);
                _refreshEstaciones(); // Recargar la lista en vivo
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Estación actualizada con éxito')),
                );
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoreo SMAT - Avanzado'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await AuthService().logout();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureEstaciones,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay estaciones registradas.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final est = snapshot.data![index];
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    // RETO DE LA SEMANA APLICADO AQUÍ (Cambia de color dinámicamente)
                    leading: Icon(
                      Icons.router, 
                      color: _obtenerColorRiesgo(est['riesgo']), 
                      size: 35,
                    ),
                    title: Text(est['nombre'] ?? 'Desconocido', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${est['ubicacion']} \nEstado: ${est['riesgo'] ?? 'NORMAL'}"),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // BOTÓN EDITAR
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _mostrarDialogoEditar(est),
                        ),
                        // BOTÓN ELIMINAR
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            bool confirmar = await showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text("¿Eliminar Estación?"),
                                content: const Text("Esta acción no se puede deshacer de la base de datos."),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Eliminar", style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            ) ?? false;

                            if (confirmar) {
                              bool ok = await ApiService().eliminarEstacion(est['id']);
                              if (ok && mounted) {
                                _refreshEstaciones();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Estación eliminada de la DB')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          bool? actualizado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEstacionScreen()),
          );
          if (actualizado == true) _refreshEstaciones();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}