import 'package:cursor_hack/features/home/models/task_appointment.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class TaskCalendarDataSource extends CalendarDataSource {
  TaskCalendarDataSource(List<TaskAppointment> tasks) {
    appointments = tasks;
  }
}
