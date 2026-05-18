import 'dart:convert';
import 'dart:async'; // ¡Esencial para el TimeoutException!
import 'package:http/http.dart' as http;
import 'services/auth_service.dart';

class ApiService {
  final String baseUrl = "http://127.0.0.1:8000";

  // REQUERIMIENTO 1: Robustez ante caídas de red y Timeouts (Laboratorio 7.1)
  Future<List<Map<String, dynamic>>> getEstaciones() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/estaciones/'))
          .timeout(const Duration(seconds: 5)); // Evita esperas infinitas

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<Map<String, dynamic>> estacionesConRiesgo = [];

        for (var est in data) {
          final id = est['id'];
          String nivelRiesgo = "NORMAL";
          
          try {
            final riesgoRes = await http
                .get(Uri.parse('$baseUrl/estaciones/$id/riesgo'))
                .timeout(const Duration(seconds: 3));
            if (riesgoRes.statusCode == 200) {
              final riesgoData = jsonDecode(riesgoRes.body);
              nivelRiesgo = riesgoData['nivel'] ?? "NORMAL";
            }
          } catch (_) {
            nivelRiesgo = "DESCONOCIDO"; // Si falla el endpoint de riesgo, no rompe la app
          }

          estacionesConRiesgo.add({
            'id': est['id'],
            'nombre': est['nombre'],
            'ubicacion': est['ubicacion'],
            'riesgo': nivelRiesgo
          });
        }
        return estacionesConRiesgo;
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } on TimeoutException catch (_) {
      throw Exception('El servidor está tardando demasiado en responder.');
    } catch (e) {
      throw Exception('No se pudo conectar con SMAT. ¿Está el servidor activo?');
    }
  }

  // MODIFICADO: Mantiene los parámetros requeridos sumando el nivel de riesgo
  Future<bool> crearEstacion(int id, String nombre, String ubicacion, String riesgo) async {
    try {
      final token = await AuthService().getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/estaciones/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id': id, 
          'nombre': nombre, 
          'ubicacion': ubicacion,
          'riesgo': riesgo // Envía el nivel para que FastAPI cree la lectura correspondiente
        }),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> editarEstacion(int id, String nombre, String ubicacion) async {
    try {
      final token = await AuthService().getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/estaciones/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'nombre': nombre, 'ubicacion': ubicacion}),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> eliminarEstacion(int id) async {
    try {
      final token = await AuthService().getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/estaciones/$id'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}