import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user_model.dart';

class StorageService {
  static const _tokenKey = 'jwt_token';
  static const _idKey = 'user_id';
  static const _nombreKey = 'user_nombre';
  static const _matriculaKey = 'user_matricula';
  static const _rolKey = 'user_rol';
  static const _estadoKey = 'user_estado';

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, user.token);
    await prefs.setInt(_idKey, user.idUsuario);
    await prefs.setString(_nombreKey, user.nombreCompleto);
    await prefs.setString(_matriculaKey, user.matricula);
    await prefs.setString(_rolKey, user.rol);
    await prefs.setInt(_estadoKey, user.estado);
  }

  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) return null;
    return UserModel(
      idUsuario: prefs.getInt(_idKey) ?? 0,
      nombreCompleto: prefs.getString(_nombreKey) ?? '',
      matricula: prefs.getString(_matriculaKey) ?? '',
      rol: prefs.getString(_rolKey) ?? 'usuario_general',
      estado: prefs.getInt(_estadoKey) ?? 1,
      token: token,
    );
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
