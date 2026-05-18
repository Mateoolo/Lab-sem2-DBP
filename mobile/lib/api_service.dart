import 'dart:convert';
import 'package:http/http.dart' as http;
import 'services/auth_service.dart';

class ApiService {
  final String baseUrl = "http://127.0.0.1:8000";

  // 1. Obtener estaciones con su nivel de riesgo
  Future<List<Map<String, dynamic>>> getEstaciones() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/estaciones/'));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<Map<String, dynamic>> estacionesConRiesgo = [];

        for (var est in data) {
          final id = est['id'];
          String nivelRiesgo = "NORMAL";
          
          try {
            final riesgoRes = await http.get(Uri.parse('$baseUrl/estaciones/$id/riesgo'));
            if (riesgoRes.statusCode == 200) {
              final riesgoData = jsonDecode(riesgoRes.body);
              nivelRiesgo = riesgoData['nivel'] ?? "NORMAL";
            }
          } catch (_) {}

          estacionesConRiesgo.add({
            'id': est['id'],
            'nombre': est['nombre'],
            'ubicacion': est['ubicacion'],
            'riesgo': nivelRiesgo
          });
        }
        return estacionesConRiesgo;
      } else {
        throw Exception('Error al cargar estaciones');
      }
    } catch (e) {
      return [];
    }
  }

  // 2. CREAR ESTACIÓN (Corregido para mandar el JSON limpio que espera el diccionario)
  Future<bool> crearEstacion(int id, String nombre, String ubicacion) async {
    try {
      final token = await AuthService().getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/estaciones/'),
        headers: {
          'Content-Type': 'application/json', // Le avisa al backend que va un JSON plano
          'Authorization': 'Bearer $token',  // Inserta la llave de seguridad JWT
        },
        body: jsonEncode({
          'id': id, 
          'nombre': nombre, 
          'ubicacion': ubicacion
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // 3. EDITAR ESTACIÓN (Corregido)
  Future<bool> editarEstacion(int id, String nombre, String ubicacion) async {
    try {
      final token = await AuthService().getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/estaciones/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nombre': nombre, 
          'ubicacion': ubicacion
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 4. ELIMINAR ESTACIÓN
  Future<bool> eliminarEstacion(int id) async {
    try {
      final token = await AuthService().getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/estaciones/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}