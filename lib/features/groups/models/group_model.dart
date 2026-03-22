import 'dart:ui';

/// Matches the backend `groups` table row.
class Group {
  Group({
    required this.groupId,
    required this.name,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.members = const [],
  });

  final int groupId;
  final String name;
  final int createdBy;
  final String? createdAt;
  final String? updatedAt;
  List<GroupMembership> members;

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      groupId: json['group_id'] as int,
      name: json['name'] as String,
      createdBy: json['created_by'] as int,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  String get initials {
    final List<String> parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  Color get avatarColor {
    final int hash = name.hashCode;
    const List<Color> palette = [
      Color(0xFF9B8CFF),
      Color(0xFF4A90E2),
      Color(0xFF5FD4A8),
      Color(0xFFFF7BAC),
      Color(0xFFFFA726),
      Color(0xFFE57373),
      Color(0xFF64B5F6),
      Color(0xFFFFB74D),
    ];
    return palette[hash.abs() % palette.length];
  }
}

/// Matches the backend `group_members` / membership row.
class GroupMembership {
  GroupMembership({
    required this.membershipId,
    required this.userId,
    required this.groupId,
    required this.role,
    this.joinedAt,
  });

  final int membershipId;
  final int userId;
  final int groupId;
  final String role;
  final String? joinedAt;

  bool get isOwner => role == 'owner';

  factory GroupMembership.fromJson(Map<String, dynamic> json) {
    return GroupMembership(
      membershipId: json['membership_id'] as int,
      userId: json['user_id'] as int,
      groupId: json['group_id'] as int,
      role: json['role'] as String,
      joinedAt: json['joined_at'] as String?,
    );
  }
}

/// Matches the backend `invites` row.
class GroupInvite {
  GroupInvite({
    required this.id,
    required this.groupId,
    required this.inviterId,
    required this.inviteeEmail,
    required this.status,
    this.createdAt,
    this.groupName,
  });

  final int id;
  final int groupId;
  final int inviterId;
  final String inviteeEmail;
  final String status;
  final String? createdAt;
  String? groupName;

  factory GroupInvite.fromJson(Map<String, dynamic> json) {
    return GroupInvite(
      id: json['id'] as int,
      groupId: json['group_id'] as int,
      inviterId: json['inviter_id'] as int,
      inviteeEmail: json['invitee_email'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] as String?,
    );
  }
}

/// Matches backend `event_proposals` row (Phase 10).
class EventProposal {
  EventProposal({
    required this.proposalId,
    required this.groupId,
    required this.proposerId,
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.description,
    this.location,
    this.acceptedBy = const [],
    this.declinedBy = const [],
    this.createdAt,
  });

  final int proposalId;
  final int groupId;
  final int proposerId;
  final String subject;
  final String startTime;
  final String endTime;
  final String status;
  final String? description;
  final String? location;
  final List<int> acceptedBy;
  final List<int> declinedBy;
  final String? createdAt;

  DateTime? get startDateTime => DateTime.tryParse(startTime)?.toLocal();
  DateTime? get endDateTime => DateTime.tryParse(endTime)?.toLocal();

  bool get isProposed => status == 'proposed';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';

  factory EventProposal.fromJson(Map<String, dynamic> json) {
    return EventProposal(
      proposalId: json['proposal_id'] as int,
      groupId: json['group_id'] as int,
      proposerId: json['proposer_id'] as int? ?? 0,
      subject: json['subject'] as String? ?? '(No title)',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      status: json['status'] as String? ?? 'proposed',
      description: json['description'] as String?,
      location: json['location'] as String?,
      acceptedBy: (json['accepted_by'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [],
      declinedBy: (json['declined_by'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [],
      createdAt: json['created_at'] as String?,
    );
  }
}
