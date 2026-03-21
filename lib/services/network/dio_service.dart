import 'package:awesome_dio_interceptor/awesome_dio_interceptor.dart';
import 'package:cursor_hack/router/app_route_constant.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as fsc;
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

class BaseDio {
  Dio? _dio;
  static final BaseDio _instance = BaseDio._internal();

  factory BaseDio() => _instance;
  Dio get instance => _dio!;

  BaseDio._internal() {
    _dio = Dio();
    // timeout
    const storage = fsc.FlutterSecureStorage();
    _dio!.options.contentType = Headers.jsonContentType;
    _dio!.options.connectTimeout = const Duration(seconds: 8);
    _dio!.options.receiveTimeout = const Duration(seconds: 8);
    _dio!.options.sendTimeout = const Duration(seconds: 8);
    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, handler) async {
          final isToken = await storage.containsKey(key: 'token');
          if (isToken) {
            final token = await storage.read(key: 'token');
            options.headers['Authorization'] = 'Bearer $token';
            options.headers['Accept'] = 'application/json';
            options.followRedirects = false;
          }
          return handler.next(options);
        },
        onResponse: (Response response, handler) {
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          if (error.type == DioExceptionType.connectionTimeout) {
            return handler.next(
              DioException(
                requestOptions: error.requestOptions,
                error: 'Connection timeout',
                type: DioExceptionType.connectionTimeout,
              ),
            );
          } else if (error.response != null &&
              error.response!.statusCode == 401) {
            await storage.delete(key: 'token');
            await storage.delete(key: 'refresh_token');
            navKey.currentContext?.go(AppRouteConstant.login);
          }
          return handler.next(error);
        },
      ),
    );
    _dio!.interceptors.add(
      AwesomeDioInterceptor(
        logRequestTimeout: false,
        logRequestHeaders: false,
        logResponseHeaders: false,
      ),
    );
  }
}
