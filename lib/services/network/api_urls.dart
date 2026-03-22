class ApiUrls {
  static const String baseUrl = "https://planiteinvite.share.zrok.io/";

  ///[AUTH]
  static const String loginUrl = "auth/login";
  static const String registerUrl = "auth/register";
  static const String logoutUrl = "auth/logout";
  static const String refreshUrl = "auth/refresh";
  static const String googleSyncUrl = "auth/google/sync";
  static const String googleExchangeUrl = "auth/google/exchange";

  ///[GROUPS & INVITES]
  static const String createGroup = "groups";
  static String deleteGroup(int groupId) => "groups/$groupId";
  static String groupMembers(int groupId) => "groups/$groupId/members";
  static String removeMember(int groupId, int userId) =>
      "groups/$groupId/members/$userId";
  static String inviteToGroup(int groupId) => "groups/$groupId/invite";
  static const String myInvites = "invites/me";
  static String respondInvite(int inviteId) => "invites/$inviteId/respond";

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
