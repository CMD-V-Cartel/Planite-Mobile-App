import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  FlutterSecureStorage storage = const FlutterSecureStorage();

  static const String _keyAccessToken = 'token';
  static const String _keyRefreshToken = 'refresh_token';

  /// Backend / Supabase access token (JWT) for `Authorization: Bearer`.
  Future<void> saveToken({required String token}) async {
    await storage.write(key: _keyAccessToken, value: token);
  }

  Future<String?> getToken() async {
    return storage.read(key: _keyAccessToken);
  }

  /// Supabase (or backend) refresh token — persist per AGENTS.md.
  Future<void> saveRefreshToken({required String token}) async {
    await storage.write(key: _keyRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return storage.read(key: _keyRefreshToken);
  }

  Future<void> clearStorage() async {
    await storage.deleteAll();
  }
}
