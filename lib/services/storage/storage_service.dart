import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  FlutterSecureStorage storage = const FlutterSecureStorage();

  static const String _keyAccessToken = 'token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';

  /// Backend / Supabase access token (JWT) for `Authorization: Bearer`.
  Future<void> saveToken({required String token}) async {
    await storage.write(key: _keyAccessToken, value: token);
  }

  Future<String?> getToken() async {
    return storage.read(key: _keyAccessToken);
  }

  /// Supabase (or backend) refresh token -- persist per AGENTS.md.
  Future<void> saveRefreshToken({required String token}) async {
    await storage.write(key: _keyRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return storage.read(key: _keyRefreshToken);
  }

  /// Backend `user_id` from `public.users` -- needed for protected calls.
  Future<void> saveUserId({required int userId}) async {
    await storage.write(key: _keyUserId, value: userId.toString());
  }

  Future<int?> getUserId() async {
    final String? raw = await storage.read(key: _keyUserId);
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  Future<void> clearStorage() async {
    await storage.deleteAll();
  }
}
