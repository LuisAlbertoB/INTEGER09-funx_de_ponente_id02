class ApiConstants {
  static const String baseUrl = 'http://3.226.156.228'; // EC2 Producción

  // Auth
  static const String login = '/api/auth/login';

  // Usuarios
  static const String usuarios = '/api/usuarios';
  static String usuarioEstado(int id) => '/api/usuarios/$id/estado';
  static String usuarioById(int id) => '/api/usuarios/$id';

  // Ponente - Conferencias
  static const String conferencias = '/api/ponente/conferencias';
  static String conferenciaById(int id) => '/api/ponente/conferencias/$id';
  static String materialesConferencia(int id) => '/api/ponente/conferencias/$id/materiales';

  // Catálogos
  static const String actividades = '/api/actividades';
  static const String periodos = '/api/periodos';
  static const String periodosActive = '/api/periodos/active';
  static const String edificios = '/api/edificios';
  static const String aulas = '/api/aulas';
  
  // Catálogo General (IA Semántica)
  static const String catalogoEventos = '/api/catalogo/eventos';

  // Recomendaciones (IA)
  static const String recomendaciones = '/api/eventos/recomendados';

  // Reportes y Clustering (IA)
  static const String clusteringReportes = '/api/reportes/clustering';

  // Health
  static const String health = '/api/health';
}
