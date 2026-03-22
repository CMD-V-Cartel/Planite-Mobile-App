import 'package:cursor_hack/features/groups/controllers/groups_provider.dart';
import 'package:cursor_hack/features/groups/models/group_model.dart';
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
  bool _loadingMembers = true;
  int? _currentUserId;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _loadCurrentUser();
    _fetchMembers();
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
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final owners =
        _members.where((m) => m.isOwner).toList();
    final regulars =
        _members.where((m) => !m.isOwner).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Column(
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
            Text(
              '${_members.length} member${_members.length == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8E95A4),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        leadingWidth: 40,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon:
                const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
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
                    Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
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
              child:
                  CircularProgressIndicator(color: Color(0xFF3D5AFE)),
            )
          : RefreshIndicator(
              color: const Color(0xFF3D5AFE),
              onRefresh: _fetchMembers,
              child: CustomScrollView(
                slivers: <Widget>[
                  // Invite banner
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                      child: InkWell(
                        onTap: _inviteMember,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3D5AFE)
                                .withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF3D5AFE)
                                  .withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3D5AFE)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.email_outlined,
                                  color: Color(0xFF3D5AFE),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Invite via email',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Send an invite to join this group',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF8E95A4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: Color(0xFF3D5AFE),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Owners
                  if (owners.isNotEmpty) ...<Widget>[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Text(
                          'OWNER',
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
                      itemCount: owners.length,
                      itemBuilder: (context, index) =>
                          _MemberTile(member: owners[index]),
                    ),
                  ],

                  // Regular members
                  if (regulars.isNotEmpty) ...<Widget>[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Text(
                          'MEMBERS  (${regulars.length})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8E95A4),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                    SliverList.builder(
                      itemCount: regulars.length,
                      itemBuilder: (context, index) {
                        final member = regulars[index];
                        return _MemberTile(
                          member: member,
                          trailing: _isOwner
                              ? IconButton(
                                  onPressed: () =>
                                      _confirmRemoveMember(member),
                                  icon: const Icon(
                                    Icons.remove_circle_outline_rounded,
                                    size: 20,
                                  ),
                                  color: Colors.redAccent,
                                  tooltip: 'Remove',
                                )
                              : null,
                        );
                      },
                    ),
                  ],

                  if (_members.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No members yet',
                          style: TextStyle(
                            color: Color(0xFF8E95A4),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                  const SliverPadding(
                      padding: EdgeInsets.only(bottom: 32)),
                ],
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Member tile
// ---------------------------------------------------------------------------

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, this.trailing});

  final GroupMembership member;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final String label = 'User #${member.userId}';
    final String initials = label.length >= 2
        ? label.substring(0, 2).toUpperCase()
        : label.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 22,
            backgroundColor: Color(
              (member.userId.hashCode & 0x00FFFFFF) | 0xFF606060,
            ),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
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
