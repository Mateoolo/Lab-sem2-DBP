import 'dart:convert';
import 'package:http/http.dart' as http;
import 'estacion.dart';

class ApiService {
  // Nota: Dejamos la IP local 127.0.0.1 para probar la app rápido desde Google Chrome
  final String url = "http://127.0.0.1:8000/estaciones/";

  Future<List<Estacion>> fetchEstaciones() async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => Estacion.fromJson(item)).toList();
      } else {
        throw Exception("Error al conectar con el servidor backend");
      }
    } catch (e) {
      throw Exception("No se pudo establecer conexión: $e");
    }
  }
}