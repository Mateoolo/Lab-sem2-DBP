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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estaciones en Red'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // BOTÓN DE LOGOUT EXIGIDO EN EL RETO
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await AuthService().logout(); // Borra el token de SharedPreferences
              if (mounted) {
                // Te expulsa de inmediato al LoginScreen limpio
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
                return ListTile(
                  leading: const Icon(Icons.router, color: Colors.blue),
                  title: Text(est['nombre'] ?? 'Desconocido'),
                  subtitle: Text(est['ubicacion'] ?? 'Sin ubicación'),
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