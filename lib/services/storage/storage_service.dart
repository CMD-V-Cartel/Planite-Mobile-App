import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  FlutterSecureStorage storage = const FlutterSecureStorage();

  // save authorization token
  Future<void> saveToken({required String token}) async {
    await storage.write(key: 'token', value: token);
  }

  // get authorization token
  Future<String?> getToken() async {
    final token = await storage.read(key: 'token');
    if (token != null) {
      return token;
    }
    return null;
  }

  Future<void> clearStorage() async {
    await storage.deleteAll();
  }
}
