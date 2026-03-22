import 'package:cursor_hack/features/calendar/models/calendar_event.dart';
import 'package:cursor_hack/features/calendar/repository/calendar_repository.dart';
import 'package:flutter/foundation.dart';

class CalendarProvider with ChangeNotifier {
  final CalendarRepository _repo = CalendarRepository();

  /// All fetched events keyed by date string (YYYY-MM-DD) to avoid duplicates.
  final Map<String, List<CalendarEvent>> _eventsByDate = {};

  /// Flat list of all unique events for the Syncfusion DataSource.
  List<CalendarEvent> get events =>
      _eventsByDate.values.expand((e) => e).toList();

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  final Set<String> _fetchedDates = {};

  static int get _deviceTzOffset => DateTime.now().timeZoneOffset.inHours;

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Fetch events for a single [date]. Skips if already fetched unless [force].
  Future<void> fetchEventsForDate(DateTime date, {bool force = false}) async {
    final key = _dateKey(date);
    if (!force && _fetchedDates.contains(key)) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repo.fetchEvents(date: key, tzOffset: _deviceTzOffset);
      _eventsByDate[key] = result;
      _fetchedDates.add(key);
    } catch (e) {
      _error = e.toString();
      debugPrint('CalendarProvider fetchEventsForDate error: $e');
    }

    _loading = false;
    notifyListeners();
  }

  /// Fetch events for a range of visible dates (batch call for calendar scroll).
  Future<void> fetchEventsForRange(List<DateTime> dates,
      {bool force = false}) async {
    final uniqueDays = <String>{};
    final toFetch = <DateTime>[];

    for (final d in dates) {
      final key = _dateKey(d);
      if (!uniqueDays.contains(key) && (force || !_fetchedDates.contains(key))) {
        uniqueDays.add(key);
        toFetch.add(d);
      }
    }

    if (toFetch.isEmpty) return;

    _loading = true;
    _error = null;
    notifyListeners();

    for (final d in toFetch) {
      final key = _dateKey(d);
      try {
        final result = await _repo.fetchEvents(date: key, tzOffset: _deviceTzOffset);
        _eventsByDate[key] = result;
        _fetchedDates.add(key);
      } catch (e) {
        debugPrint('CalendarProvider range fetch error for $key: $e');
      }
    }

    _loading = false;
    notifyListeners();
  }

  /// Create a new event via POST /calendar/events.
  /// Returns null on success, error message on failure.
  Future<String?> createEvent({
    required String subject,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    String? location,
  }) async {
    final created = await _repo.createEvent(
      subject: subject,
      startTime: startTime,
      endTime: endTime,
      description: description,
      location: location,
    );

    if (created == null) return 'Failed to create event';

    // Refresh that day's events from the server for full sync.
    await fetchEventsForDate(startTime, force: true);
    return null;
  }
}
