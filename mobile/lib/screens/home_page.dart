import 'package:flutter/material.dart';
import '../api_service.dart';
import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> futureEstaciones;

  @override
  void initState() {
    super.initState();
    futureEstaciones = ApiService().getEstaciones();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoreo SMAT - Avanzado'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      // REQUERIMIENTO 2: Gesto Pull-to-Refresh (Laboratorio 7.1)
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            futureEstaciones = ApiService().getEstaciones();
          });
          await futureEstaciones;
        },
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: futureEstaciones,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No hay estaciones disponibles.'));
            }

            final estaciones = snapshot.data!;
            return ListView.builder(
              itemCount: estaciones.length,
              itemBuilder: (context, index) {
                final est = estaciones[index];
                
                // Lógica de colores de alerta del semáforo
                Color colorIcono = Colors.green;
                if (est['riesgo'] == 'PELIGRO') colorIcono = Colors.red;
                if (est['riesgo'] == 'ALERTA') colorIcono = Colors.amber;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Icon(Icons.router, color: colorIcono),
                    title: Text(est['nombre'] ?? 'Sin Nombre'),
                    subtitle: Text('${est['ubicacion'] ?? 'Sin Ubicación'} - Estado: ${est['riesgo']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            // Tu diálogo o navegación para editar
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            bool exito = await ApiService().eliminarEstacion(est['id']);
                            if (exito) {
                              setState(() {
                                futureEstaciones = ApiService().getEstaciones();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add_estacion').then((_) {
            setState(() {
              futureEstaciones = ApiService().getEstaciones();
            });
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}