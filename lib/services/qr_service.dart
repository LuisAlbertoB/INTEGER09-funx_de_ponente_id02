/// Servicio auxiliar para la generación y parseo de payloads QR.
///
/// El QR codifica un deep-link interno de la forma:
///   unievent://evento/{id_conferencia}
///
/// No se requiere subir nada al servidor: el QR se renderiza localmente
/// con el paquete qr_flutter y se decodifica con mobile_scanner.
class QrService {
  QrService._();

  static const String _scheme = 'unievent';
  static const String _host = 'evento';

  /// Construye el payload que se codifica dentro del QR.
  static String buildPayload(int idConferencia) =>
      '$_scheme://$_host/$idConferencia';

  /// Parsea el raw-string escaneado y devuelve el id_conferencia.
  /// Retorna null si el QR no pertenece a esta app.
  static int? parsePayload(String raw) {
    try {
      final uri = Uri.parse(raw.trim());
      if (uri.scheme != _scheme || uri.host != _host) return null;
      if (uri.pathSegments.isEmpty) return null;
      return int.tryParse(uri.pathSegments.first);
    } catch (_) {
      return null;
    }
  }
}
