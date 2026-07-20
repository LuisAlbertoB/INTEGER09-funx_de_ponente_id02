class ConferenciaModel {
  final int idConferencia;
  final String titulo;
  final String? descripcion;
  final String? tematica;
  final String nivelAcademicoObjetivo;
  final int duracionEstimadaMin;
  final DateTime? fechaRealizada;
  final int estado;
  final int idPonente;
  final int idActividad;
  final int idPeriodo;
  final int? idAulaUtilizada;

  ConferenciaModel({
    required this.idConferencia,
    required this.titulo,
    this.descripcion,
    this.tematica,
    required this.nivelAcademicoObjetivo,
    required this.duracionEstimadaMin,
    this.fechaRealizada,
    required this.estado,
    required this.idPonente,
    required this.idActividad,
    required this.idPeriodo,
    this.idAulaUtilizada,
  });

  factory ConferenciaModel.fromJson(Map<String, dynamic> json) {
    return ConferenciaModel(
      idConferencia: json['id_conferencia'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      tematica: json['tematica'],
      nivelAcademicoObjetivo: json['nivel_academico_objetivo'] ?? 'ambos',
      duracionEstimadaMin: json['duracion_estimada_min'] ?? 60,
      fechaRealizada: json['fecha_realizada'] != null
          ? DateTime.parse(json['fecha_realizada'])
          : null,
      estado: json['estado'] ?? 1,
      idPonente: json['id_ponente'],
      idActividad: json['id_actividad'],
      idPeriodo: json['id_periodo'],
      idAulaUtilizada: json['id_aula_utilizada'],
    );
  }
}
