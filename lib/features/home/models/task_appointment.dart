import 'package:syncfusion_flutter_calendar/calendar.dart';

/// [Appointment] with extra UI state for the home calendar.
class TaskAppointment extends Appointment {
  TaskAppointment({
    required super.startTime,
    required super.endTime,
    super.subject,
    super.color,
    this.isCompleted = false,
  });

  bool isCompleted;
}
