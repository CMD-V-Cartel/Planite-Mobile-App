import 'package:cursor_hack/features/groups/models/group_model.dart';

enum MessageType { text, voice, availability, system }

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.type = MessageType.text,
    this.targetGroup,
    this.memberSchedules,
  });

  final String text;
  final bool isUser;
  final MessageType type;
  final Group? targetGroup;

  /// Map of member name -> list of schedule descriptions for availability view.
  final Map<String, List<MemberScheduleSlot>>? memberSchedules;
}

class MemberScheduleSlot {
  const MemberScheduleSlot({
    required this.title,
    required this.timeRange,
    this.isBusy = true,
  });

  final String title;
  final String timeRange;
  final bool isBusy;
}
