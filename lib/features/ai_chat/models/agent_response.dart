import 'package:cursor_hack/features/groups/models/group_model.dart';

class AgentResponse {
  AgentResponse({
    required this.intent,
    required this.response,
    this.transcript,
    this.proposedSlots = const [],
    this.createdEvent,
    this.eventProposal,
    this.groupId,
    this.groupName,
    this.contextEvents = const [],
  });

  final String intent;
  final String response;
  final String? transcript;
  final List<ProposedSlot> proposedSlots;
  final CreatedEvent? createdEvent;
  final EventProposal? eventProposal;
  final int? groupId;
  final String? groupName;
  final List<Map<String, dynamic>> contextEvents;

  factory AgentResponse.fromJson(Map<String, dynamic> json) {
    return AgentResponse(
      intent: json['intent'] as String? ?? 'query',
      response: json['response'] as String? ?? '',
      transcript: json['transcript'] as String?,
      proposedSlots: (json['proposed_slots'] as List<dynamic>?)
              ?.map((e) => ProposedSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdEvent: json['created_event'] != null
          ? CreatedEvent.fromJson(json['created_event'] as Map<String, dynamic>)
          : null,
      eventProposal: json['event_proposal'] != null
          ? EventProposal.fromJson(json['event_proposal'] as Map<String, dynamic>)
          : null,
      groupId: json['group_id'] as int?,
      groupName: json['group_name'] as String?,
      contextEvents: (json['context_events'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
    );
  }
}

class ProposedSlot {
  ProposedSlot({
    required this.freeWindow,
    required this.participantCount,
  });

  final String freeWindow;
  final int participantCount;

  factory ProposedSlot.fromJson(Map<String, dynamic> json) {
    return ProposedSlot(
      freeWindow: json['free_window'] as String? ?? '',
      participantCount: json['participant_count'] as int? ?? 0,
    );
  }

  /// Try to parse the free_window string into a (start, end) pair.
  /// The backend may return either:
  ///   1. A tsrange: ["2026-03-22 17:00:00","2026-03-23 00:00:00")
  ///   2. A human-readable string: "Saturday, March 22 06:00 PM – 08:00 PM"
  (DateTime, DateTime)? get parsedWindow {
    // --- Attempt 1: PostgreSQL tsrange format ---
    try {
      final cleaned =
          freeWindow.replaceAll(RegExp(r'[\[\]\(\)""]'), '').trim();
      // Only split on comma if it looks like a tsrange (contains a date-like
      // pattern on both sides). A reliable heuristic: if the first segment
      // starts with a digit, it's a timestamp, not a day name.
      if (cleaned.isNotEmpty && RegExp(r'^\d').hasMatch(cleaned)) {
        final parts = cleaned.split(',');
        if (parts.length == 2) {
          final a = DateTime.parse(parts[0].trim());
          final b = DateTime.parse(parts[1].trim());
          return (
            DateTime(a.year, a.month, a.day, a.hour, a.minute, a.second),
            DateTime(b.year, b.month, b.day, b.hour, b.minute, b.second),
          );
        }
      }
    } catch (_) {}

    // --- Attempt 2: Human-readable "Day, Month DD HH:MM AM – HH:MM AM" ---
    try {
      // Split on " – " or " - " to get [datePart + startTime, endTime].
      final dashParts = freeWindow.split(RegExp(r'\s[–\-]\s'));
      if (dashParts.length == 2) {
        // e.g. "Saturday, March 22 06:00 PM" and "08:00 PM"
        final leftRaw = dashParts[0].trim();
        final endTimeRaw = dashParts[1].trim();

        // Separate the date portion from the start-time portion.
        // Match a trailing time like "06:00 PM" at the end of the left part.
        final timeRe = RegExp(r'(\d{1,2}:\d{2}\s*[APap][Mm])$');
        final startTimeMatch = timeRe.firstMatch(leftRaw);
        if (startTimeMatch == null) return null;

        final startTimeStr = startTimeMatch.group(1)!;
        final datePart =
            leftRaw.substring(0, startTimeMatch.start).trim();

        // Remove leading day-of-week ("Saturday, ") to get "March 22".
        final dateOnly = datePart.replaceFirst(
            RegExp(r'^[A-Za-z]+,?\s*'), '');

        final now = DateTime.now();
        final startDt = _parseHumanDateTime(dateOnly, startTimeStr, now.year);
        final endDt = _parseHumanDateTime(dateOnly, endTimeRaw, now.year);
        if (startDt == null || endDt == null) return null;

        // If end is before start, it wraps past midnight → next day.
        final adjustedEnd =
            endDt.isBefore(startDt) ? endDt.add(const Duration(days: 1)) : endDt;
        return (startDt, adjustedEnd);
      }
    } catch (_) {}

    return null;
  }

  static DateTime? _parseHumanDateTime(
      String dateStr, String timeStr, int year) {
    // dateStr: "March 22"   timeStr: "06:00 PM"
    final months = <String, int>{
      'january': 1, 'february': 2, 'march': 3, 'april': 4,
      'may': 5, 'june': 6, 'july': 7, 'august': 8,
      'september': 9, 'october': 10, 'november': 11, 'december': 12,
    };
    final dateParts = dateStr.trim().split(RegExp(r'\s+'));
    if (dateParts.length < 2) return null;
    final month = months[dateParts[0].toLowerCase()];
    final day = int.tryParse(dateParts[1]);
    if (month == null || day == null) return null;

    final timeParts = timeStr.trim().split(RegExp(r'[\s:]+'));
    if (timeParts.length < 3) return null;
    var hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = int.tryParse(timeParts[1]) ?? 0;
    final ampm = timeParts[2].toUpperCase();
    if (ampm == 'PM' && hour != 12) hour += 12;
    if (ampm == 'AM' && hour == 12) hour = 0;

    return DateTime(year, month, day, hour, minute);
  }
}

class CreatedEvent {
  CreatedEvent({
    required this.subject,
    required this.startTime,
    required this.endTime,
    this.description,
    this.location,
    this.pushedToGoogle = false,
    this.googleEventId,
  });

  final String subject;
  final String startTime;
  final String endTime;
  final String? description;
  final String? location;
  final bool pushedToGoogle;
  final String? googleEventId;

  factory CreatedEvent.fromJson(Map<String, dynamic> json) {
    return CreatedEvent(
      subject: json['subject'] as String? ?? '(No title)',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      description: json['description'] as String?,
      location: json['location'] as String?,
      pushedToGoogle: json['pushed_to_google'] as bool? ?? false,
      googleEventId: json['google_event_id'] as String?,
    );
  }

  DateTime? get startDateTime => DateTime.tryParse(startTime)?.toLocal();
  DateTime? get endDateTime => DateTime.tryParse(endTime)?.toLocal();
}
