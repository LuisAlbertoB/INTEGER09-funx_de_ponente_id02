import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../data/models/conferencia_model.dart';
import 'storage_service.dart';

class PonenteService {
  final StorageService _storage = StorageService();

  Future<Map<String, String>> _headers() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<ConferenciaModel>> getMisConferencias() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.conferencias}'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => ConferenciaModel.fromJson(e)).toList();
    }
    throw Exception('Error al cargar conferencias.');
  }

  Future<ConferenciaModel> createConferencia({
    required String titulo,
    String? descripcion,
    String? tematica,
    required String nivelAcademicoObjetivo,
    required int duracionEstimadaMin,
    required int idActividad,
    required int idPeriodo,
    int? idAulaUtilizada,
  }) async {
    final body = {
      'titulo': titulo,
      if (descripcion != null) 'descripcion': descripcion,
      if (tematica != null) 'tematica': tematica,
      'nivel_academico_objetivo': nivelAcademicoObjetivo,
      'duracion_estimada_min': duracionEstimadaMin,
      'id_actividad': idActividad,
      'id_periodo': idPeriodo,
      if (idAulaUtilizada != null) 'id_aula_utilizada': idAulaUtilizada,
    };

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.conferencias}'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return ConferenciaModel.fromJson(data['conferencia']);
    }
    final err = jsonDecode(response.body);
    throw Exception(err['message'] ?? 'Error al crear la conferencia.');
  }

  Future<void> updateConferencia(int id, Map<String, dynamic> campos) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.conferenciaById(id)}'),
      headers: await _headers(),
      body: jsonEncode(campos),
    );
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Error al actualizar la conferencia.');
    }
  }

  Future<void> uploadMaterial({
    required int idConferencia,
    required String tituloMaterial,
    required String tipoArchivo,
    required String filePath,
  }) async {
    final token = await _storage.getToken();
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.materialesConferencia(idConferencia)}',
    );
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['titulo_material'] = tituloMaterial;
    request.fields['tipo_archivo'] = tipoArchivo;
    request.files.add(await http.MultipartFile.fromPath('archivo', filePath));

    final streamedResponse = await request.send();
    if (streamedResponse.statusCode != 201) {
      throw Exception('Error al subir el material.');
    }
  }

  Future<void> deleteConferencia(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.conferenciaById(id)}'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar la conferencia.');
    }
  }

  Future<List<Map<String, dynamic>>> getActividades() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.actividades}'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
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
    return [];
  }
}
