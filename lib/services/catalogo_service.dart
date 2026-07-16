import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import 'storage_service.dart';

class CatalogoService {
  final StorageService _storage = StorageService();

  Future<Map<String, String>> _headers() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> getEdificios() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.edificios}'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Error al cargar edificios.');
  }

  Future<List<Map<String, dynamic>>> getAulas() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.aulas}'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Error al cargar aulas.');
  }

  Future<List<Map<String, dynamic>>> getPeriodos() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.periodos}'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Error al cargar periodos.');
  }

  Future<Map<String, dynamic>?> getPeriodoActivo() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.periodosActive}'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.health}'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // NLP: Búsqueda Semántica de Eventos
  Future<Map<String, dynamic>> getEventosSemanticos({String? buscar, int page = 1, int limit = 10}) async {
    String url = '${ApiConstants.baseUrl}${ApiConstants.catalogoEventos}?page=$page&limit=$limit';
    if (buscar != null && buscar.isNotEmpty) {
      url += '&buscar=${Uri.encodeComponent(buscar)}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Error al buscar eventos semánticamente.');
  }

  // NLP: Recomendaciones de Eventos basadas en Historial
  Future<List<Map<String, dynamic>>> getRecomendaciones() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.recomendaciones}'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Error al cargar recomendaciones personalizadas.');
  }
}
