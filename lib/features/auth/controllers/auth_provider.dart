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

  Future<AuthModel?> register(
    BuildContext context, {
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      setErrorMessage(null);
      setLoading(true);
      final ctx = context;
      _authModel = await _authRepository.register(
        name: name,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    } finally {
      setLoading(false);
    }
  }

  /// Logout captured from a deactivated widget tree (e.g. after dialog dismiss).
  /// Calls the backend `POST /auth/logout` before clearing local state.
  Future<void> performLogout(GoRouter router) async {
    try {
      await _authRepository.backendLogout();
      await StorageService.instance.clearStorage();
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
      _authModel = null;
      notifyListeners();
      router.go(AppRouteConstant.onboarding);
    } catch (_) {}
  }

  /// Google OAuth via Supabase. After the redirect completes, calls
  /// `POST /auth/google/sync` per AGENTS.md to bridge the identity gap.
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
        onTimeout: () => throw TimeoutException('Google sign-in timed out.'),
      );

      // Persist Supabase tokens locally.
      await StorageService.instance.saveToken(token: session.accessToken);
      final String? supabaseRefresh = session.refreshToken;
      if (supabaseRefresh != null) {
        await StorageService.instance.saveRefreshToken(token: supabaseRefresh);
      }

      // Extract Google identity from the Supabase user object.
      final user = Supabase.instance.client.auth.currentUser;
      final String email = user?.email ?? session.user.email ?? '';
      String providerUserId = '';
      String? googleRefreshToken;
      String? fullName;
      String? profilePictureUrl;

      if (user != null) {
        final googleIdentity = user.identities?.where(
          (id) => id.provider == 'google',
        );
        if (googleIdentity != null && googleIdentity.isNotEmpty) {
          providerUserId = googleIdentity.first.id;
        }

        final Map<String, dynamic>? meta = user.userMetadata;
        if (meta != null) {
          fullName = meta['full_name'] as String? ??
              meta['name'] as String?;
          profilePictureUrl = meta['avatar_url'] as String? ??
              meta['picture'] as String?;
        }
      }

      // The Google refresh token is only available from provider token data
      // when offline access was granted. Supabase may expose it in the session
      // providerRefreshToken field.
      googleRefreshToken = session.providerRefreshToken;

      // Call POST /auth/google/sync -- only if we have a non-null Google
      // refresh token, OR this is potentially the first login (always sync).
      if (providerUserId.isNotEmpty) {
        try {
          final syncResult = await _authRepository.googleSync(
            email: email,
            providerUserId: providerUserId,
            googleRefreshToken: googleRefreshToken,
            fullName: fullName,
            profilePictureUrl: profilePictureUrl,
          );
          debugPrint('Google sync result: $syncResult');
        } catch (e) {
          debugPrint('Google sync failed (non-blocking): $e');
        }
      }

      _authModel = AuthModel(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        tokenType: 'bearer',
        user: AuthUser(email: email),
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
