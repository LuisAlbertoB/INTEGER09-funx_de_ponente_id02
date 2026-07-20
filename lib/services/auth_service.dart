import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../data/models/user_model.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService _storage = StorageService();

  Future<UserModel> login(String matricula, String contrasena) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'matricula': matricula, 'contrasena': contrasena}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['usuario'], token);
      await _storage.saveUser(user);
      return user;
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Error al iniciar sesión.');
    }
  }

  Future<UserModel?> getSessionUser() async {
    return await _storage.getUser();
  }

  Future<void> logout() async {
    await _storage.clear();
  }
}