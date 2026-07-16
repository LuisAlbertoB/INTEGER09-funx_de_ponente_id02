import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.checking;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _checkSession();
  }

  Future<void> _checkSession() async {
    final savedUser = await _authService.getSessionUser();
    if (savedUser != null) {
      _user = savedUser;
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String matricula, String contrasena) async {
    _errorMessage = null;
    try {
      _user = await _authService.login(matricula, contrasena);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
