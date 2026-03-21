import 'dart:developer';

import 'package:cursor_hack/features/auth/models/auth_model.dart';
import 'package:cursor_hack/services/network/api_response.dart';
import 'package:cursor_hack/services/network/api_urls.dart';
import 'package:cursor_hack/services/network/dio_service.dart';
import 'package:cursor_hack/services/storage/storage_service.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  final dio = BaseDio().instance;
  final StorageService storageService = StorageService.instance;

  Future<AuthModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final body = {"email": email, "password": password};

      final response = await dio.post(
        ApiUrls.baseUrl + ApiUrls.loginUrl,
        data: body,
      );
      if (response.statusCode == 200) {
        await storageService.saveToken(token: response.data['access_token']);
        final String? refresh = response.data['refresh_token'] as String?;
        if (refresh != null) {
          await storageService.saveRefreshToken(token: refresh);
        }
        return AuthModel.fromJson(response.data);
      } else {
        return Future.error('Failed to login');
      }
    } on DioException catch (e) {
      log(e.toString());
      if (e.response != null) {
        return Future.error(
          e.response?.data['message'] ?? ApiResponse.noInternet,
        );
      }
      return Future.error(
        e.response?.data['message'] ?? ApiResponse.unauthorized,
      );
    } catch (e) {
      log(e.toString());
      return Future.error(e.toString());
    }
  }
}
