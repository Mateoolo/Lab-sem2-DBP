import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_page.dart';
import 'services/auth_service.dart';
import 'screens/add_estacion.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMAT - Alerta Temprana',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Control de persistencia en el arranque del sistema (Laboratorio 7.1)
      home: FutureBuilder<String?>(
        future: AuthService().getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Si el token existe y es válido, entra directo sin logearse de nuevo
          if (snapshot.hasData && snapshot.data != null) {
            return const HomePage(); // ¡Llamada limpia sin choques!
          }
          // Si no hay token, lo mandamos al Login. ¡IMPORTANTE: Le quitamos el const!
          return LoginScreen(); 
        },
      ),
      routes: {
       '/login': (context) => const LoginScreen(),
       '/home': (context) => const HomePage(),
       '/add_estacion': (context) => const AddEstacionScreen(), // 👈 ¡Verifica que esta línea exista!
      },
    );
  }
}