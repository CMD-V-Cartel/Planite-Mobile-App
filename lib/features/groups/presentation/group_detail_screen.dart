import 'package:cursor_hack/features/calendar/controllers/calendar_provider.dart';
import 'package:cursor_hack/features/groups/controllers/groups_provider.dart';
import 'package:cursor_hack/features/groups/models/group_model.dart';
import 'package:cursor_hack/features/groups/widgets/event_proposal_card.dart';
import 'package:cursor_hack/services/storage/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key, required this.group});

  final Group group;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late Group _group;
  List<GroupMembership> _members = [];
  List<EventProposal> _proposals = [];
  bool _loadingMembers = true;
  bool _loadingProposals = true;
  int? _currentUserId;
  bool _isOwner = false;
  int? _respondingProposalId;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _loadCurrentUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMembers();
      _fetchProposals();
    });
  }

  Future<void> _loadCurrentUser() async {
    final userId = await StorageService.instance.getUserId();
    if (mounted) setState(() => _currentUserId = userId);
  }

  Future<void> _fetchMembers() async {
    setState(() => _loadingMembers = true);
    final members = await context
        .read<GroupsProvider>()
        .fetchMembers(_group.groupId);
    if (mounted) {
      setState(() {
        _members = members;
        _loadingMembers = false;
        _isOwner = _currentUserId != null &&
            members.any((m) => m.userId == _currentUserId && m.isOwner);
      });
    }
  }

  Future<void> _fetchProposals() async {
    setState(() => _loadingProposals = true);
    final proposals = await context
        .read<GroupsProvider>()
        .fetchProposals(_group.groupId);
    if (mounted) {
      setState(() {
        _proposals = proposals;
        _loadingProposals = false;
      });
    }
  }

  Future<void> _respondToProposal(int proposalId, String action) async {
    setState(() => _respondingProposalId = proposalId);
    final result = await context.read<GroupsProvider>().respondToProposal(
          proposalId: proposalId,
          action: action,
          groupId: _group.groupId,
        );
    if (!mounted) return;
    setState(() => _respondingProposalId = null);

    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error!),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      String message;
      if (result.scheduled) {
        message = 'All members accepted — event added to Google Calendar!';
      } else if (action == 'accept') {
        message = 'Proposal accepted';
      } else {
        message = 'Proposal declined';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
      _fetchProposals();
      // Sync calendar so the new/removed event shows immediately.
      context.read<CalendarProvider>().invalidateCache();
    }
  }

  // ---------------------------------------------------------------------------
  // Invite by email
  // ---------------------------------------------------------------------------

  void _inviteMember() {
    final emailCtrl = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24, 24, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Invite Member',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Enter the email of the person you want to invite.',
              style: TextStyle(fontSize: 13, color: Color(0xFF8E95A4)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'friend@example.com',
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                filled: true,
                fillColor: const Color(0xFFF2F3F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                final email = emailCtrl.text.trim();
                if (email.isEmpty || !email.contains('@')) return;
                Navigator.pop(ctx);

                final provider = context.read<GroupsProvider>();
                final err = await provider.sendInvite(
                  groupId: _group.groupId,
                  email: email,
                );

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      err ?? 'Invite sent to $email',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3D5AFE),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Send Invite',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Remove member
  // ---------------------------------------------------------------------------

  void _confirmRemoveMember(GroupMembership member) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Remove User #${member.userId} from "${_group.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Remove'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true || !mounted) return;

      final err = await context.read<GroupsProvider>().removeMember(
            groupId: _group.groupId,
            userId: member.userId,
          );

      if (!mounted) return;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), behavior: SnackBarBehavior.floating),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User #${member.userId} removed'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchMembers();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Delete group
  // ---------------------------------------------------------------------------

  void _confirmDeleteGroup() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Group'),
        content:
            Text('Are you sure you want to delete "${_group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed != true || !mounted) return;
      context.read<GroupsProvider>().deleteGroup(_group.groupId);
      Navigator.pop(context);
    });
  }

  // ---------------------------------------------------------------------------
  // Members bottom sheet
  // ---------------------------------------------------------------------------

  void _showMembersSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final owners = _members.where((m) => m.isOwner).toList();
        final regulars = _members.where((m) => !m.isOwner).toList();

        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scrollCtrl) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Text(
                      'Members (${_members.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _inviteMember();
                      },
                      icon: const Icon(Icons.person_add_alt_1_rounded,
                          size: 18),
                      label: const Text('Invite'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF3D5AFE),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE8EAF0)),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  children: [
                    for (final m in owners)
                      _MemberTile(member: m),
                    for (final m in regulars)
                      _MemberTile(
                        member: m,
                        trailing: _isOwner
                            ? IconButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _confirmRemoveMember(m);
                                },
                                icon: const Icon(
                                  Icons.remove_circle_outline_rounded,
                                  size: 20,
                                ),
                                color: Colors.redAccent,
                                tooltip: 'Remove',
                              )
                            : null,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final pendingProposals =
        _proposals.where((p) => p.isProposed).toList();
    final pastProposals =
        _proposals.where((p) => !p.isProposed).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _group.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (_members.isNotEmpty)
                    GestureDetector(
                      onTap: _showMembersSheet,
                      child: _MemberAvatarStack(members: _members),
                    )
                  else
                    const Text(
                      'Loading…',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8E95A4),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        leadingWidth: 40,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _inviteMember,
            tooltip: 'Invite member',
            icon: const Icon(Icons.person_add_alt_1_rounded),
            color: const Color(0xFF3D5AFE),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') _confirmDeleteGroup();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 20),
                    SizedBox(width: 8),
                    Text('Delete Group',
                        style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loadingMembers
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3D5AFE)),
            )
          : RefreshIndicator(
              color: const Color(0xFF3D5AFE),
              onRefresh: () async {
                await Future.wait([_fetchMembers(), _fetchProposals()]);
              },
              child: CustomScrollView(
                slivers: <Widget>[
                  // Pending proposals
                  if (!_loadingProposals &&
                      pendingProposals.isNotEmpty) ...<Widget>[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Text(
                          'PENDING PROPOSALS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8E95A4),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                    SliverList.builder(
                      itemCount: pendingProposals.length,
                      itemBuilder: (context, index) {
                        final proposal = pendingProposals[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          child: EventProposalCard(
                            proposal: proposal,
                            totalMembers: _members.length,
                            currentUserId: _currentUserId,
                            responding: _respondingProposalId ==
                                proposal.proposalId,
                            onAccept: () => _respondToProposal(
                                proposal.proposalId, 'accept'),
                            onDecline: () => _respondToProposal(
                                proposal.proposalId, 'decline'),
                          ),
                        );
                      },
                    ),
                  ],

                  // Past proposals (confirmed / cancelled)
                  if (!_loadingProposals &&
                      pastProposals.isNotEmpty) ...<Widget>[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Text(
                          'PAST PROPOSALS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8E95A4),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                    SliverList.builder(
                      itemCount: pastProposals.length,
                      itemBuilder: (context, index) {
                        final proposal = pastProposals[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          child: EventProposalCard(
                            proposal: proposal,
                            totalMembers: _members.length,
                            currentUserId: _currentUserId,
                          ),
                        );
                      },
                    ),
                  ],

                  // Empty state
                  if (!_loadingProposals && _proposals.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_outlined,
                                  size: 52,
                                  color: const Color(0xFFCDD0D9)),
                              const SizedBox(height: 16),
                              const Text(
                                'No event proposals yet',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4A4D56),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Ask the AI Planner to schedule a group '
                                'event and proposals will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF8E919A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
                ],
              ),
            ),
    );
  }
}

// =============================================================================
// Overlapping member avatars for the app bar
// =============================================================================

class _MemberAvatarStack extends StatelessWidget {
  const _MemberAvatarStack({required this.members});

  final List<GroupMembership> members;

  static const int _maxVisible = 4;
  static const double _avatarRadius = 12.0;
  static const double _overlap = 8.0;

  @override
  Widget build(BuildContext context) {
    final visible = members.take(_maxVisible).toList();
    final overflow = members.length - _maxVisible;
    final count = visible.length + (overflow > 0 ? 1 : 0);
    final width =
        (_avatarRadius * 2) * count - _overlap * (count - 1).clamp(0, count);

    return SizedBox(
      height: _avatarRadius * 2 + 2,
      width: width + 2,
      child: Stack(
        children: [
          for (int i = 0; i < visible.length; i++)
            Positioned(
              left: i * (_avatarRadius * 2 - _overlap),
              child: _SmallAvatar(userId: visible[i].userId),
            ),
          if (overflow > 0)
            Positioned(
              left: visible.length * (_avatarRadius * 2 - _overlap),
              child: CircleAvatar(
                radius: _avatarRadius,
                backgroundColor: const Color(0xFFE0E3EB),
                child: Text(
                  '+$overflow',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A4D56),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  const _SmallAvatar({required this.userId});
  final int userId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: CircleAvatar(
        radius: _MemberAvatarStack._avatarRadius,
        backgroundColor: Color(
          (userId.hashCode & 0x00FFFFFF) | 0xFF606060,
        ),
        child: Text(
          'U${userId % 100}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 8,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Member tile (used in bottom sheet)
// =============================================================================

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, this.trailing});

  final GroupMembership member;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final String label = 'User #${member.userId}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE8EAF0),
                width: 1.5,
              ),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Color(
                (member.userId.hashCode & 0x00FFFFFF) | 0xFF606060,
              ),
              child: Text(
                'U${member.userId % 100}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    if (member.isOwner) ...<Widget>[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D5AFE)
                              .withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Owner',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3D5AFE),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  member.role,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFB0B5C0),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
