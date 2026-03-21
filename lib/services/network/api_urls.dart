class ApiUrls {
  static const String baseUrl = "http://192.168.2.4/pmtool/api/";

  ///[AUTH]
  static const String loginUrl = "user/login";

  ///[HOME]
  static const String getMyTasks = "my-tasks";
  static const String getTaskById = "task/";
  static const String createTimesheet = 'timesheet/create';

  ///[ATTENDANCE]
  static const String getAttendance = 'attendance';
  static const String createAttendance = 'attendance/create';

  ///[ACTIVITY]
  static const String createActivity = 'activity/create';
  static const String getActivities = 'activity/all';

  ///[PROFILE]
  static const String getProfile = 'employee/';
}
