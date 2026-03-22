import 'dart:developer';

import 'package:cursor_hack/features/calendar/models/calendar_event.dart';
import 'package:cursor_hack/services/network/api_urls.dart';
import 'package:cursor_hack/services/storage/storage_service.dart';
import 'package:dio/dio.dart';

class CalendarRepository {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiUrls.baseUrl,
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 12),
    contentType: Headers.jsonContentType,
  ));

  Future<Options> _authOptions() async {
    final token = await StorageService.instance.getToken();
    return Options(headers: {
      if (token != null) 'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
  }

  /// GET /calendar/events?date=YYYY-MM-DD&tz_offset=4
  Future<List<CalendarEvent>> fetchEvents({
    required String date,
    int tzOffset = 4,
  }) async {
    try {
      final response = await _dio.get(
        ApiUrls.calendarEvents,
        queryParameters: {'date': date, 'tz_offset': tzOffset},
        options: await _authOptions(),
      );

      final data = response.data as Map<String, dynamic>;
      final items = data['events'] as List<dynamic>? ?? [];

      return items
          .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 424) {
        log('CalendarRepository: token expired (424) — re-sync needed');
      } else if (code == 502) {
        log('CalendarRepository: Google Calendar API failure (502)');
      } else {
        log('CalendarRepository fetchEvents error: '
            '$code ${e.response?.data}');
      }
      return [];
    }
  }

  /// Format a local DateTime as ISO 8601 with the device's UTC offset,
  /// e.g. "2026-03-22T15:00:00+04:00".
  static String _toIso8601WithOffset(DateTime dt) {
    final local = dt.isUtc ? dt.toLocal() : dt;
    final offset = local.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hh = offset.inHours.abs().toString().padLeft(2, '0');
    final mm = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    // yyyy-MM-ddTHH:mm:ss±HH:MM
    return '${local.year}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}T'
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}'
        '$sign$hh:$mm';
  }

  /// POST /calendar/events — create a new event (pushed to Google Calendar).
  Future<CalendarEvent?> createEvent({
    required String subject,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    String? location,
  }) async {
    try {
      final body = {
        'Subject': subject,
        'StartTime': _toIso8601WithOffset(startTime),
        'EndTime': _toIso8601WithOffset(endTime),
        if (description != null) 'Description': description,
        if (location != null) 'Location': location,
      };

      final response = await _dio.post(
        ApiUrls.calendarEvents,
        data: body,
        options: await _authOptions(),
      );

      final data = response.data as Map<String, dynamic>;
      final event = data['event'] as Map<String, dynamic>?;
      if (event == null) return null;

      final pushedToGoogle = data['pushed_to_google'] as bool? ?? false;
      log('CalendarRepository createEvent: pushed_to_google=$pushedToGoogle');

      return CalendarEvent.fromJson(event);
    } on DioException catch (e) {
      log('CalendarRepository createEvent error: '
          '${e.response?.statusCode} ${e.response?.data}');
      return null;
    }
  }
}
