import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import 'storage_service.dart';

/// Servicio HTTP que cubre todos los endpoints de eventos.service.js:
///   • Foro (GET + POST)
///   • Evaluación (POST) → alimenta análisis de sentimiento BERT
///   • Recomendaciones (GET) → IA content-based
///   • Solicitar espacio (POST)
class EventService {
  final StorageService _storage = StorageService();

  Future<Map<String, String>> _headers() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Eventos (Generales) ─────────────────────────────────────────────────

  /// GET /api/eventos
  Future<Map<String, dynamic>> getEventos({
    int page = 1,
    int limit = 10,
    int? estado,
    int? idActividad,
    String? nivelAcademicoObjetivo,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.eventos}').replace(
      queryParameters: {
        'page': '$page',
        'limit': '$limit',
        if (estado != null) 'estado': '$estado',
        if (idActividad != null) 'id_actividad': '$idActividad',
        if (nivelAcademicoObjetivo != null && nivelAcademicoObjetivo.isNotEmpty)
          'nivel_academico_objetivo': nivelAcademicoObjetivo,
      },
    );
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final err = jsonDecode(response.body);
    throw Exception(err['message'] ?? 'Error al cargar los eventos.');
  }

  /// GET /api/eventos/:id
  Future<Map<String, dynamic>> getEventoById(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.eventoById(id)}'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final err = jsonDecode(response.body);
    throw Exception(err['message'] ?? 'Error al cargar el evento.');
  }

  // ── Foro ────────────────────────────────────────────────────────────────

  /// GET /api/eventos/:id/foro
  Future<List<Map<String, dynamic>>> getForo(int idEvento) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.eventoForo(idEvento)}'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    final err = jsonDecode(response.body);
    throw Exception(err['message'] ?? 'Error al cargar el foro.');
  }

  /// POST /api/eventos/:id/foro
  Future<Map<String, dynamic>> postComentario(
    int idEvento,
    String mensaje, {
    int? idComentarioPadre,
  }) async {
    final body = <String, dynamic>{
      'mensaje': mensaje,
      if (idComentarioPadre != null) 'id_comentario_padre': idComentarioPadre,
    };
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.eventoForo(idEvento)}'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final err = jsonDecode(response.body);
    throw Exception(err['message'] ?? 'Error al publicar el comentario.');
  }

  // ── Evaluación ──────────────────────────────────────────────────────────

  /// POST /api/eventos/:id/evaluacion
  /// El [comentarioEscrito] es el texto que BERT analiza en el servidor.
  Future<void> submitEvaluacion({
    required int idEvento,
    required int calificacion,
    required int porcentajeSatisfaccion,
    String? comentarioEscrito,
  }) async {
    final body = <String, dynamic>{
      'calificacion': calificacion,
      'porcentaje_satisfaccion': porcentajeSatisfaccion,
      if (comentarioEscrito != null && comentarioEscrito.trim().isNotEmpty)
        'comentario_escrito': comentarioEscrito.trim(),
    };
    final response = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.eventoEvaluacion(idEvento)}',
      ),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (response.statusCode == 201) return;

    final err = jsonDecode(response.body);
    final msg = err['message'] ?? 'Error al enviar la evaluación.';
    // 409 = el usuario ya evaluó este evento
    throw Exception(msg);
  }

  // ── Recomendaciones (IA) ────────────────────────────────────────────────

  /// GET /api/eventos/recomendados
  Future<List<Map<String, dynamic>>> getRecomendados() async {
    final response = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.recomendaciones}',
      ),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    final err = jsonDecode(response.body);
    throw Exception(err['message'] ?? 'Error al cargar recomendaciones.');
  }

  // ── Solicitar Espacio ───────────────────────────────────────────────────

  /// POST /api/eventos/:idEvento/solicitar-espacio/:idEspacio
  Future<void> solicitarEspacio({
    required int idEvento,
    required int idEspacio,
    required DateTime fechaInicio,
    required DateTime fechaFinal,
    String? motivo,
  }) async {
    final body = <String, dynamic>{
      'fecha_inicio': fechaInicio.toIso8601String(),
      'fecha_final': fechaFinal.toIso8601String(),
      if (motivo != null && motivo.trim().isNotEmpty) 'motivo': motivo.trim(),
    };
    final response = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.eventoEspacio(idEvento, idEspacio)}',
      ),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (response.statusCode == 201) return;
    final err = jsonDecode(response.body);
    throw Exception(err['message'] ?? 'Error al solicitar el espacio.');
  }

  // ── Catálogo ────────────────────────────────────────────────────────────

  /// GET /api/catalogo/eventos?buscar=X&tematica=Y
  Future<List<Map<String, dynamic>>> getCatalogo({
    String? buscar,
    String? tematica,
    int page = 1,
    int limit = 20,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.catalogoEventos}',
    ).replace(queryParameters: {
      'page': '$page',
      'limit': '$limit',
      if (buscar != null && buscar.isNotEmpty) 'buscar': buscar,
      if (tematica != null && tematica.isNotEmpty) 'tematica': tematica,
    });
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items =
          data is List ? data : (data['data'] ?? data['eventos'] ?? []);
      return items.cast<Map<String, dynamic>>();
    }
    throw Exception('Error al cargar el catálogo.');
  }
}