import 'dart:convert';
import 'package:http/http.dart' as http;
import 'services/auth_service.dart';

class ApiService {
  final String baseUrl = "http://127.0.0.1:8000";

  Future<List<Map<String, dynamic>>> getEstaciones() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/estaciones/'));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Error al cargar estaciones');
      }
    } catch (e) {
      return [];
    }
  }

  Future<bool> crearEstacion(int id, String nombre, String ubicacion) async {
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
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}