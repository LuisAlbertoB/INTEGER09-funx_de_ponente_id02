import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import 'storage_service.dart';

class AdminService {
  final StorageService _storage = StorageService();

  Future<Map<String, String>> _headers() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> getUsuarios() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.usuarios}'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      final List<dynamic> data = body['data'] ?? [];
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Error al cargar usuarios.');
  }

  Future<void> createUsuario({
    required String nombreCompleto,
    required String matricula,
    required String contrasena,
    required String rol,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.usuarios}'),
      headers: await _headers(),
      body: jsonEncode({
        'nombre_completo': nombreCompleto,
        'matricula': matricula,
        'contrasena': contrasena,
        'rol': rol,
      }),
    );
    if (response.statusCode != 201) {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Error al crear usuario.');
    }
  }

  Future<void> updateEstadoUsuario(int id, int estado) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.usuarioEstado(id)}'),
      headers: await _headers(),
      body: jsonEncode({'estado': estado}),
    );
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Error al actualizar estado.');
    }
  }

  Future<void> deleteUsuario(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.usuarioById(id)}'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar usuario.');
    }
  }

  // NLP: Obtener agrupamiento inteligente de reportes (Topic Modeling)
  Future<Map<String, dynamic>> getReportesClustering() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.clusteringReportes}'),
      headers: await _headers(),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    
    throw Exception('Error al cargar clustering de reportes. Código: ${response.statusCode}');
  }
}
