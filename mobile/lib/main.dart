import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_page.dart';
import 'services/auth_service.dart';

void main() => runApp(const SMATApp());

class SMATApp extends StatelessWidget {
  const SMATApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SMAT Mobile',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // El home ahora depende de la verificación en tiempo real del token
      home: FutureBuilder<String?>(
        future: AuthService().getToken(),
        builder: (context, snapshot) {
          // Mientras verifica, muestra un indicador de carga redondo
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Si encuentra el token guardado, salta directo al Dashboard
          if (snapshot.hasData && snapshot.data != null) {
            return const HomePage();
          }
          // Si no hay token, lo manda a loguearse
          return const LoginScreen();
        },
      ),
    );
  }
}