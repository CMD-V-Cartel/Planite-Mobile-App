import 'package:cursor_hack/features/auth/models/auth_model.dart';
import 'package:cursor_hack/features/auth/repository/auth_repository.dart';
import 'package:cursor_hack/router/app_route_constant.dart';
import 'package:cursor_hack/services/storage/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  bool _googleInitialized = false;

  static const List<String> _googleScopes = <String>[
    'email',
    'https://www.googleapis.com/auth/calendar',
  ];

  Future<void> _ensureGoogleInit() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

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
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
      _authModel = null;
      notifyListeners();
      router.go(AppRouteConstant.onboarding);
    } catch (_) {}
  }

  /// Native Google Sign-In per AGENTS.md:
  /// 1. GoogleSignIn.authenticate() -> idToken
  /// 2. supabase.auth.signInWithIdToken(idToken) -> session + providerRefreshToken
  /// 3. POST /auth/google/sync { email, provider_user_id, google_refresh_token }
  Future<void> signInWithGoogle(BuildContext context) async {
    setErrorMessage(null);
    setGoogleLoading(true);

    try {
      await _ensureGoogleInit();

      // Step 1: Native Google authentication.
      final GoogleSignInAccount googleUser;
      try {
        googleUser = await GoogleSignIn.instance.authenticate(
          scopeHint: _googleScopes,
        );
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled) {
          setGoogleLoading(false);
          return;
        }
        rethrow;
      }

      final String? idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw StateError(
          'Google sign-in succeeded but no ID token was returned.',
        );
      }

      // Get the Google access token via authorizeScopes (calendar access).
      String? accessToken;
      try {
        final clientAuth =
            await googleUser.authorizationClient.authorizeScopes(_googleScopes);
        accessToken = clientAuth.accessToken;
      } catch (e) {
        debugPrint('authorizeScopes failed: $e');
      }

      // Step 2: Create a Supabase session using the Google ID token.
      final AuthResponse authResponse =
          await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      final Session? session = authResponse.session;
      final User? supabaseUser = authResponse.user;

      if (session == null || supabaseUser == null) {
        throw StateError(
          'Supabase session creation failed after Google sign-in.',
        );
      }

      // Persist Supabase tokens locally.
      await StorageService.instance.saveToken(token: session.accessToken);
      if (session.refreshToken != null) {
        await StorageService.instance
            .saveRefreshToken(token: session.refreshToken!);
      }

      // Persist Google access token for direct Calendar API calls.
      if (accessToken != null) {
        await StorageService.instance
            .saveGoogleAccessToken(token: accessToken);
      }

      // Extract identity data.
      final String email = supabaseUser.email ?? googleUser.email;
      final String providerUserId =
          supabaseUser.userMetadata?['sub'] as String? ?? googleUser.id;
      final String? fullName = googleUser.displayName;
      final String? profilePicUrl = googleUser.photoUrl;

      debugPrint('Google sync data: email=$email, '
          'providerUserId=$providerUserId, '
          'accessToken=${accessToken != null ? "(present)" : "null"}');

      // Step 3: POST /auth/google/sync with the Google access token.
      if (providerUserId.isNotEmpty && accessToken != null) {
        try {
          final syncResult = await _authRepository.googleSync(
            email: email,
            providerUserId: providerUserId,
            googleAccessToken: accessToken,
            fullName: fullName,
            profilePictureUrl: profilePicUrl,
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
    } on GoogleSignInException catch (e) {
      debugPrint('signInWithGoogle GoogleSignInException: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: ${e.code}'),
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
      setGoogleLoading(false);
    }
  }
}
