import 'package:cursor_hack/features/calendar/controllers/calendar_provider.dart';
import 'package:cursor_hack/features/calendar/models/calendar_event.dart';
import 'package:cursor_hack/features/home/data/task_calendar_data_source.dart';
import 'package:cursor_hack/features/home/models/task_appointment.dart';
import 'package:cursor_hack/features/home/widgets/home_appointment_tile.dart';
import 'package:cursor_hack/features/home/widgets/home_calendar_header.dart';
import 'package:cursor_hack/features/home/widgets/week_date_strip.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with AutomaticKeepAliveClientMixin {
  final CalendarController _controller = CalendarController();
  TaskCalendarDataSource _dataSource = TaskCalendarDataSource([]);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _controller
      ..displayDate = now
      ..selectedDate = now
      ..view = CalendarView.day;

    _controller.addPropertyChangedListener((String _) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchForDate(now);
      context.read<CalendarProvider>().addListener(_onProviderChanged);
    });
  }

  @override
  void dispose() {
    context.read<CalendarProvider>().removeListener(_onProviderChanged);
    _controller.dispose();
    super.dispose();
  }

  /// Rebuilds the data source when the provider's event list changes.
  /// Does NOT trigger any network calls — that avoids the polling loop.
  void _onProviderChanged() {
    if (mounted) _rebuildDataSource();
  }

  DateTime get _displayDate => _controller.displayDate ?? DateTime.now();

  Future<void> _fetchForDate(DateTime date, {bool force = false}) async {
    await context
        .read<CalendarProvider>()
        .fetchEventsForDate(date, force: force);
    if (mounted) _rebuildDataSource();
  }

  void _rebuildDataSource() {
    final calEvents = context.read<CalendarProvider>().events;
    final appointments = calEvents.map(_toAppointment).toList();
    setState(() {
      _dataSource = TaskCalendarDataSource(appointments);
    });
  }

  TaskAppointment _toAppointment(CalendarEvent e) {
    return TaskAppointment(
      startTime: e.startTime,
      endTime: e.endTime,
      subject: e.subject,
      color: e.color,
    );
  }

  void _selectDay(DateTime day) {
    setState(() {
      _controller.displayDate = day;
      _controller.selectedDate = day;
    });
    _fetchForDate(day, force: true);
  }

  void _toggleTask(TaskAppointment task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
      _dataSource.notifyListeners(
          CalendarDataSourceAction.reset, _dataSource.appointments!);
    });
  }

  // ---------------------------------------------------------------------------
  // Create event dialog
  // ---------------------------------------------------------------------------

  void _showCreateEventSheet() {
    final subjectCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    DateTime startTime = DateTime(
      _displayDate.year,
      _displayDate.month,
      _displayDate.day,
      DateTime.now().hour + 1,
    );
    DateTime endTime = startTime.add(const Duration(hours: 1));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24, 24, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'New Event',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 16),
                _sheetTextField(subjectCtrl, 'Event title', Icons.edit_outlined),
                const SizedBox(height: 12),
                _sheetTextField(
                    descCtrl, 'Description (optional)', Icons.notes_rounded),
                const SizedBox(height: 12),
                _sheetTextField(locationCtrl, 'Location (optional)',
                    Icons.location_on_outlined),
                const SizedBox(height: 16),
                _timeRow(
                  label: 'Start',
                  time: startTime,
                  onTap: () async {
                    final picked = await _pickDateTime(ctx, startTime);
                    if (picked != null) {
                      setSheetState(() {
                        startTime = picked;
                        if (endTime.isBefore(startTime)) {
                          endTime = startTime.add(const Duration(hours: 1));
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                _timeRow(
                  label: 'End',
                  time: endTime,
                  onTap: () async {
                    final picked = await _pickDateTime(ctx, endTime);
                    if (picked != null) {
                      setSheetState(() => endTime = picked);
                    }
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    final subject = subjectCtrl.text.trim();
                    if (subject.isEmpty) return;
                    Navigator.pop(ctx);

                    final err =
                        await context.read<CalendarProvider>().createEvent(
                              subject: subject,
                              startTime: startTime,
                              endTime: endTime,
                              description: descCtrl.text.trim().isNotEmpty
                                  ? descCtrl.text.trim()
                                  : null,
                              location: locationCtrl.text.trim().isNotEmpty
                                  ? locationCtrl.text.trim()
                                  : null,
                            );

                    if (!mounted) return;
                    if (err != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(err),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      _rebuildDataSource();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Event created'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3D5AFE),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Create Event',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetTextField(
      TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: const Color(0xFFF2F3F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _timeRow({
    required String label,
    required DateTime time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F3F7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(
              '$label:  ',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF8E95A4),
              ),
            ),
            Text(
              DateFormat('EEE, MMM d  h:mm a').format(time),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const Spacer(),
            const Icon(Icons.edit_calendar_rounded,
                size: 18, color: Color(0xFF3D5AFE)),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _pickDateTime(BuildContext ctx, DateTime initial) async {
    final date = await showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (date == null || !ctx.mounted) return null;

    final time = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // ---------------------------------------------------------------------------
  // Appointment builder
  // ---------------------------------------------------------------------------

  Widget _appointmentBuilder(
    BuildContext context,
    CalendarAppointmentDetails details,
  ) {
    if (details.isMoreAppointmentRegion) {
      final List<dynamic> list = details.appointments.toList();
      final int extra = list.length > 1 ? list.length - 1 : 0;
      return ColoredBox(
        color: const Color(0xFFF0F2F6),
        child: Center(
          child: Text(
            '+$extra more',
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ),
      );
    }

    final dynamic raw = details.appointments.first;
    if (raw is! TaskAppointment) {
      return const SizedBox.shrink();
    }

    return HomeAppointmentTile(
      task: raw,
      onToggleComplete: () => _toggleTask(raw),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isLoading = context.watch<CalendarProvider>().loading;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            HomeCalendarHeader(
              displayDate: _displayDate,
              onOpenMenu: () => Scaffold.of(context).openDrawer(),
              onSearch: () {},
              onClose: () {},
            ),
            WeekDateStrip(
              selectedDate: _displayDate,
              onDateSelected: _selectDay,
            ),
            const Divider(
                height: 1, thickness: 0.5, color: Color(0xFFE8EAF0)),
            if (isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF3D5AFE),
                backgroundColor: Color(0xFFF0F2F6),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: SfCalendar(
                    controller: _controller,
                    view: CalendarView.day,
                    dataSource: _dataSource,
                    backgroundColor: Colors.white,
                    cellBorderColor: const Color(0xFFF0F1F4),
                    headerHeight: 0,
                    viewHeaderHeight: 0,
                    showNavigationArrow: false,
                    showCurrentTimeIndicator: true,
                    todayHighlightColor: Colors.redAccent,
                    timeSlotViewSettings: const TimeSlotViewSettings(
                      startHour: 0,
                      endHour: 24,
                      timeInterval: Duration(minutes: 60),
                      timeIntervalHeight: 80,
                      timeFormat: 'h a',
                      nonWorkingDays: <int>[],
                      timeTextStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFB0B5C0),
                      ),
                      timeRulerSize: 52,
                    ),
                    appointmentBuilder: _appointmentBuilder,
                    onViewChanged: (ViewChangedDetails details) {
                      if (details.visibleDates.isEmpty) return;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        final dates = details.visibleDates;
                        setState(() => _controller.displayDate = dates.first);
                        context
                            .read<CalendarProvider>()
                            .fetchEventsForRange(dates)
                            .then((_) {
                          if (mounted) _rebuildDataSource();
                        });
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _showCreateEventSheet,
            backgroundColor: const Color(0xFF3D5AFE),
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
