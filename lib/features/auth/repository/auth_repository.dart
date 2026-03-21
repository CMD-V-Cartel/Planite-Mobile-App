import 'dart:developer';

import 'package:cursor_hack/services/network/api_response.dart';
import 'package:cursor_hack/services/network/api_urls.dart';
import 'package:cursor_hack/services/network/dio_service.dart';
import 'package:cursor_hack/services/storage/storage_service.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  final dio = BaseDio().instance;
  final StorageService storageService = StorageService.instance;

  Future<void> login({
    required String username,
    required String password,
  }) async {
    try {
      final body = {"username": username, "password": password};

      await Future.delayed(const Duration(seconds: 2));
      // final response = await dio.post(
      //   ApiUrls.baseUrl + ApiUrls.loginUrl,
      //   data: body,
      // );
      // if (response.statusCode == 200) {
      //   //   await Future.wait([
      //   //     storageService.saveToken(token: response.data['data']['token']),
      //   //   ]);

      //   // return AuthModel.fromJson(response.data);
      // } else {
      //   return Future.error('Failed to login');
      // }
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
