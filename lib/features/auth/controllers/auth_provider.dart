import 'package:cursor_hack/features/auth/repository/auth_repository.dart';
import 'package:cursor_hack/router/app_route_constant.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  bool _isPasswordVisible = false;
  bool get isPasswordVisible => _isPasswordVisible;

  void togglePassword() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  Future<void> login(
    BuildContext context, {
    required String username,
    required String password,
  }) async {
    try {
      setErrorMessage(null);
      setLoading(true);
      final ctx = context;
      await _authRepository.login(username: username, password: password);
      if (ctx.mounted) {
        ctx.goNamed(AppRouteConstant.home);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      setLoading(false);
    }
  }
}
