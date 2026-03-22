import 'dart:developer';
import 'dart:io';

import 'package:cursor_hack/features/ai_chat/models/agent_response.dart';
import 'package:cursor_hack/services/network/api_urls.dart';
import 'package:cursor_hack/services/storage/storage_service.dart';
import 'package:dio/dio.dart';

class AgentApiException implements Exception {
  AgentApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

class AgentRepository {
  AgentRepository();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiUrls.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.instance.getToken();
    return {
      if (token != null) 'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static int get _deviceTzOffset => DateTime.now().timeZoneOffset.inHours;

  /// POST /agent/interact/text
  Future<AgentResponse> sendText({
    required String query,
    int? tzOffset,
  }) async {
    tzOffset ??= _deviceTzOffset;
    try {
      final response = await _dio.post(
        ApiUrls.agentText,
        data: {'query': query, 'tz_offset': tzOffset},
        options: Options(headers: await _authHeaders()),
      );
      return AgentResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// POST /agent/interact — multipart with audio file
  Future<AgentResponse> sendAudio({
    required String filePath,
    String? queryFallback,
    int? tzOffset,
  }) async {
    tzOffset ??= _deviceTzOffset;
    try {
      final file = File(filePath);
      final ext = filePath.split('.').last.toLowerCase();
      final mimeType = switch (ext) {
        'wav' => 'audio/wav',
        'mp3' => 'audio/mpeg',
        _ => 'audio/mp4',
      };

      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          file.path,
          filename: 'recording.$ext',
          contentType: DioMediaType.parse(mimeType),
        ),
        'tz_offset': tzOffset,
        if (queryFallback != null) 'query': queryFallback,
      });

      final token = await StorageService.instance.getToken();
      final response = await _dio.post(
        ApiUrls.agentAudio,
        data: formData,
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );
      return AgentResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  AgentApiException _mapError(DioException e) {
    final code = e.response?.statusCode ?? 0;
    log('AgentRepository error $code: ${e.response?.data}');
    return switch (code) {
      401 => AgentApiException(401, 'Session expired. Please log in again.'),
      422 => AgentApiException(422, 'No query or audio provided.'),
      424 => AgentApiException(424, 'Google Calendar not connected. Sign in with Google first.'),
      429 => AgentApiException(429, 'AI is busy, please try again in a moment.'),
      502 || 503 => AgentApiException(code, 'Something went wrong. Please try again.'),
      _ => e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout
          ? AgentApiException(0, 'No connection. Check your network.')
          : AgentApiException(code, 'Something went wrong. Please try again.'),
    };
  }
}
