import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false; 

  void _manejarLogin() async {
    if (_userController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campos obligatorios vacíos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    bool exito = await AuthService().login(
      _userController.text.trim(),
      _passController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (exito && mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/home', 
        (Route<dynamic> route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario o contraseña incorrectos')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'SMAT - Inicio de Sesión',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _userController,
                  decoration: const InputDecoration(labelText: 'Usuario'),
                ),
                TextField(
                  controller: _passController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                ),
                const SizedBox(height: 32),
                _isLoading 
                  ? const CircularProgressIndicator() 
                  : ElevatedButton(
                      onPressed: _manejarLogin,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(200, 45)),
                      child: const Text('Ingresar al Sistema'),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}