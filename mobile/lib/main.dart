import 'package:flutter/material.dart';
import 'api_service.dart';
import 'estacion.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMAT Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const EstacionesScreen(),
    );
  }
}

class EstacionesScreen extends StatefulWidget {
  const EstacionesScreen({super.key});

  @override
  State<EstacionesScreen> createState() => _EstacionesScreenState();
}

class _EstacionesScreenState extends State<EstacionesScreen> {
  late Future<List<Estacion>> _futureEstaciones;

  @override
  void initState() {
    super.initState();
    _futureEstaciones = ApiService().fetchEstaciones();
  }

  // Lógica del RETO obligatoria para refrescar los datos sin reiniciar la App
  void _refrescarEstaciones() {
    setState(() {
      _futureEstaciones = ApiService().fetchEstaciones();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMAT - Monitoreo UNMSM'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Estacion>>(
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
                return ListTile(
                  leading: const Icon(Icons.satellite_alt, color: Colors.blue),
                  title: Text(est.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(est.ubicacion),
                );
              },
            );
          }
        },
      ),
      // BOTÓN FLOTANTE DEL RETO ACADÉMICO
      floatingActionButton: FloatingActionButton(
        onPressed: _refrescarEstaciones,
        backgroundColor: Colors.blue.shade700,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}