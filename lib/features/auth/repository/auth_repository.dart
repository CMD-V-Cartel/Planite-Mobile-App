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

  Future<AuthModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final body = {"name": name, "email": email, "password": password};

      final response = await dio.post(
        ApiUrls.baseUrl + ApiUrls.registerUrl,
        data: body,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await storageService.saveToken(token: response.data['access_token']);
        final String? refresh = response.data['refresh_token'] as String?;
        if (refresh != null) {
          await storageService.saveRefreshToken(token: refresh);
        }
        return AuthModel.fromJson(response.data);
      } else {
        return Future.error('Failed to create account');
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

  /// Calls `POST /auth/google/sync` to bridge the identity gap between
  /// `auth.users` and `public.users` + `public.google_auth_tokens`.
  /// No Authorization header needed -- backend uses service role key.
  Future<Map<String, dynamic>> googleSync({
    required String email,
    required String providerUserId,
    String? googleRefreshToken,
    String? username,
    String? fullName,
    String? profilePictureUrl,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'email': email,
        'provider_user_id': providerUserId,
      };
      if (googleRefreshToken != null) {
        body['google_refresh_token'] = googleRefreshToken;
      }
      if (username != null) body['username'] = username;
      if (fullName != null) body['full_name'] = fullName;
      if (profilePictureUrl != null) {
        body['profile_picture_url'] = profilePictureUrl;
      }

      final response = await Dio().post(
        ApiUrls.baseUrl + ApiUrls.googleSyncUrl,
        data: body,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final data = response.data as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>?;
      if (user != null && user['user_id'] != null) {
        await storageService.saveUserId(userId: user['user_id'] as int);
      }
      return data;
    } on DioException catch (e) {
      log('googleSync DioException: $e');
      if (e.response != null) {
        return Future.error(
          e.response?.data['detail'] ?? 'Google sync failed',
        );
      }
      return Future.error('Google sync failed: $e');
    } catch (e) {
      log('googleSync error: $e');
      return Future.error(e.toString());
    }
  }

  /// Calls `POST /auth/refresh` to get fresh tokens.
  Future<AuthModel> refreshToken({required String refreshToken}) async {
    try {
      final response = await dio.post(
        ApiUrls.baseUrl + ApiUrls.refreshUrl,
        data: {'refresh_token': refreshToken},
      );
      if (response.statusCode == 200) {
        await storageService.saveToken(token: response.data['access_token']);
        final String? refresh = response.data['refresh_token'] as String?;
        if (refresh != null) {
          await storageService.saveRefreshToken(token: refresh);
        }
        return AuthModel.fromJson(response.data);
      } else {
        return Future.error('Failed to refresh session');
      }
    } on DioException catch (e) {
      log('refreshToken error: $e');
      return Future.error(
        e.response?.data['message'] ?? 'Token refresh failed',
      );
    } catch (e) {
      log('refreshToken error: $e');
      return Future.error(e.toString());
    }
  }

  /// Calls `POST /auth/logout` with the Bearer token to invalidate the session
  /// server-side.
  Future<void> backendLogout() async {
    try {
      await dio.post(ApiUrls.baseUrl + ApiUrls.logoutUrl);
    } catch (e) {
      log('backendLogout error: $e');
    }
  }
}
