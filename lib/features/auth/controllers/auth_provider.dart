import 'dart:async';

import 'package:cursor_hack/config/supabase_oauth_config.dart';
import 'package:cursor_hack/features/auth/models/auth_model.dart';
import 'package:cursor_hack/features/auth/repository/auth_repository.dart';
import 'package:cursor_hack/router/app_route_constant.dart';
import 'package:cursor_hack/services/storage/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

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

  bool _isGoogleLoading = false;
  bool get isGoogleLoading => _isGoogleLoading;

  void setGoogleLoading(bool value) {
    _isGoogleLoading = value;
    notifyListeners();
  }

  bool _isPasswordVisible = false;
  bool get isPasswordVisible => _isPasswordVisible;

  void togglePassword() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  AuthModel? _authModel;
  AuthModel? get authModel => _authModel;

  Future<AuthModel?> login(
    BuildContext context, {
    required String email,
    required String password,
  }) async {
    try {
      setErrorMessage(null);
      setLoading(true);
      final ctx = context;
      _authModel = await _authRepository.login(
        email: email,
        password: password,
      );
      setLoading(false);
      if (ctx.mounted) {
        ctx.go(AppRouteConstant.home);
      }
      return _authModel;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return null;
    } finally {
      setLoading(false);
    }
  }

  /// Google OAuth via Supabase. Session tokens are persisted for backend
  /// `Authorization: Bearer` usage. Handles user cancellation gracefully.
  Future<void> signInWithGoogle(BuildContext context) async {
    setErrorMessage(null);
    setGoogleLoading(true);
    StreamSubscription<AuthState>? sub;
    var oauthLaunched = false;

    try {
      final Completer<Session> sessionCompleter = Completer<Session>();

      sub = Supabase.instance.client.auth.onAuthStateChange.listen((
        AuthState data,
      ) {
        if (!oauthLaunched) return;

        if (data.event == AuthChangeEvent.signedIn && data.session != null) {
          if (!sessionCompleter.isCompleted) {
            sessionCompleter.complete(data.session!);
          }
        }
      });

      final bool launched = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: supabaseOAuthRedirectTo(),
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw StateError('Could not open Google sign-in.');
      }
      oauthLaunched = true;

      final Session session = await sessionCompleter.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () =>
            throw TimeoutException('Google sign-in timed out.'),
      );

      await StorageService.instance.saveToken(token: session.accessToken);
      final String? refresh = session.refreshToken;
      if (refresh != null) {
        await StorageService.instance.saveRefreshToken(token: refresh);
      }

      _authModel = AuthModel(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        tokenType: 'bearer',
        user: AuthUser(email: session.user.email),
      );

      setGoogleLoading(false);
      if (context.mounted) {
        context.go(AppRouteConstant.home);
      }
      return;
    } on TimeoutException {
      debugPrint('signInWithGoogle: user cancelled or timed out');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign-in was cancelled. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on AuthException catch (e) {
      debugPrint('signInWithGoogle AuthException: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, st) {
      debugPrint('signInWithGoogle: $e\n$st');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      await sub?.cancel();
      setGoogleLoading(false);
    }
  }
}
