import 'package:cursor_hack/features/home/data/sample_home_tasks.dart';
import 'package:cursor_hack/features/home/data/task_calendar_data_source.dart';
import 'package:cursor_hack/features/home/models/task_appointment.dart';
import 'package:cursor_hack/features/home/widgets/home_appointment_tile.dart';
import 'package:cursor_hack/features/home/widgets/home_calendar_header.dart';
import 'package:cursor_hack/features/home/widgets/week_date_strip.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with AutomaticKeepAliveClientMixin {
  final CalendarController _controller = CalendarController();
  late List<TaskAppointment> _tasks;
  late TaskCalendarDataSource _dataSource;

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

    _tasks = buildSampleTasksForDay(now);
    _dataSource = TaskCalendarDataSource(_tasks);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime get _displayDate => _controller.displayDate ?? DateTime.now();

  void _selectDay(DateTime day) {
    setState(() {
      _controller.displayDate = day;
      _controller.selectedDate = day;
      _tasks = buildSampleTasksForDay(day);
      _dataSource = TaskCalendarDataSource(_tasks);
    });
  }

  void _toggleTask(TaskAppointment task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
      _dataSource.notifyListeners(CalendarDataSourceAction.reset, _tasks);
    });
  }

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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
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
        const Divider(height: 1, thickness: 0.5, color: Color(0xFFE8EAF0)),
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
                  startHour: 7,
                  endHour: 20,
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
                    setState(() {
                      _controller.displayDate = details.visibleDates.first;
                    });
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
