import 'package:flutter/material.dart';

/// Matches the backend `GET /calendar/events` response shape
/// (Syncfusion-ready fields).
class CalendarEvent {
  CalendarEvent({
    required this.id,
    required this.subject,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    this.description,
    this.categoryColor,
    this.location,
    this.googleEventId,
  });

  final String id;
  final String subject;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final String? description;
  final String? categoryColor;
  final String? location;
  final String? googleEventId;

  Color get color => _hexToColor(categoryColor ?? '#1A73E8');

  static Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: (json['Id'] as String?) ?? '',
      subject: (json['Subject'] as String?) ?? '(No title)',
      startTime: DateTime.parse(json['StartTime'] as String).toLocal(),
      endTime: DateTime.parse(json['EndTime'] as String).toLocal(),
      isAllDay: (json['IsAllDay'] as bool?) ?? false,
      description: json['Description'] as String?,
      categoryColor: json['CategoryColor'] as String?,
      location: json['Location'] as String?,
      googleEventId: json['GoogleEventId'] as String?,
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'Subject': subject,
        'StartTime': startTime.toIso8601String(),
        'EndTime': endTime.toIso8601String(),
        if (description != null) 'Description': description,
        if (location != null) 'Location': location,
      };
}
