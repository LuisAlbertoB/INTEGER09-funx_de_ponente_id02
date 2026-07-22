class UserModel {
  final int idUsuario;
  final String nombreCompleto;
  final String matricula;
  final String rol;
  final int estado;
  final String token;

  UserModel({
    required this.idUsuario,
    required this.nombreCompleto,
    required this.matricula,
    required this.rol,
    required this.estado,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String token) {
    return UserModel(
      idUsuario: json['id_usuario'] ?? 0,
      nombreCompleto: json['nombre_completo'] ?? '',
      matricula: json['matricula'] ?? '',
      rol: json['rol'] ?? 'usuario_general',
      estado: json['estado'] ?? 1,
      token: token,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_usuario': idUsuario,
      'nombre_completo': nombreCompleto,
      'matricula': matricula,
      'rol': rol,
      'estado': estado,
      'token': token,
    };
  }

  bool get isPonente => rol == 'ponente' || rol == 'admin';
  bool get isAdmin => rol == 'admin';
  bool get isCoordinador => rol == 'coordinador' || rol == 'admin';
}