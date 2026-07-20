import '../models/user_model.dart';
import '../../services/auth_service.dart';

class AuthRepository {
  final AuthService service;

  AuthRepository(this.service);

  Future<UserModel> login(String email, String password) {
    return service.login(email, password);
  }
}