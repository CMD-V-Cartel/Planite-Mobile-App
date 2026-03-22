import 'package:cursor_hack/features/groups/controllers/groups_provider.dart';
import 'package:cursor_hack/features/groups/models/group_model.dart';
import 'package:cursor_hack/features/groups/presentation/group_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GroupsProvider>();
      provider.fetchGroups();
      provider.fetchInvites();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openGroup(Group group) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => GroupDetailScreen(group: group),
      ),
    );
  }

  void _showCreateGroupDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Group'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Group name',
            filled: true,
            fillColor: const Color(0xFFF2F3F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              context.read<GroupsProvider>().createGroup(name).then((_) {
                if (!mounted) return;
                final err = context.read<GroupsProvider>().error;
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(err),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF3D5AFE),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<GroupsProvider>(
      builder: (context, provider, _) {
        return Column(
          children: <Widget>[
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Groups',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _showCreateGroupDialog,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF3D5AFE),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 22),
                  ),
                ],
              ),
            ),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3F7),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerHeight: 0,
                labelColor: const Color(0xFF3D5AFE),
                unselectedLabelColor: const Color(0xFF8E919A),
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                tabs: <Widget>[
                  const Tab(text: 'My Groups'),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text('Invites'),
                        if (provider.invites.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3D5AFE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${provider.invites.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  _MyGroupsTab(
                    groups: provider.groups,
                    loading: provider.loadingGroups,
                    onOpenGroup: _openGroup,
                  ),
                  _InvitesTab(
                    invites: provider.invites,
                    loading: provider.loadingInvites,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// My Groups tab
// ---------------------------------------------------------------------------

class _MyGroupsTab extends StatelessWidget {
  const _MyGroupsTab({
    required this.groups,
    required this.loading,
    required this.onOpenGroup,
  });

  final List<Group> groups;
  final bool loading;
  final void Function(Group) onOpenGroup;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3D5AFE)),
      );
    }
    if (groups.isEmpty) {
      return const _EmptyState(
        icon: Icons.group_outlined,
        title: 'No groups yet',
        subtitle: 'Tap + to create a group and start inviting people.',
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF3D5AFE),
      onRefresh: () => context.read<GroupsProvider>().fetchGroups(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: groups.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          indent: 76,
          endIndent: 20,
          color: Color(0xFFEEEFF3),
        ),
        itemBuilder: (BuildContext context, int index) {
          final Group group = groups[index];
          return _GroupTile(group: group, onTap: () => onOpenGroup(group));
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Invites tab
// ---------------------------------------------------------------------------

class _InvitesTab extends StatelessWidget {
  const _InvitesTab({
    required this.invites,
    required this.loading,
  });

  final List<GroupInvite> invites;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3D5AFE)),
      );
    }
    if (invites.isEmpty) {
      return const _EmptyState(
        icon: Icons.mail_outline_rounded,
        title: 'No pending invites',
        subtitle: 'When someone invites you to a group it will appear here.',
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF3D5AFE),
      onRefresh: () => context.read<GroupsProvider>().fetchInvites(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: invites.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          indent: 76,
          endIndent: 20,
          color: Color(0xFFEEEFF3),
        ),
        itemBuilder: (BuildContext context, int index) {
          final GroupInvite invite = invites[index];
          return _InviteTile(invite: invite);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Group tile
// ---------------------------------------------------------------------------

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group, required this.onTap});

  final Group group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 24,
              backgroundColor: group.avatarColor,
              child: Text(
                group.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    group.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${group.members.length} member${group.members.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8E919A),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFC5C8D0),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Invite tile
// ---------------------------------------------------------------------------

class _InviteTile extends StatelessWidget {
  const _InviteTile({required this.invite});

  final GroupInvite invite;

  @override
  Widget build(BuildContext context) {
    final String displayName =
        invite.groupName ?? 'Group #${invite.groupId}';
    final String initials = _initials(displayName);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 24,
            backgroundColor: Color(
              (displayName.hashCode & 0x00FFFFFF) | 0xFF606060,
            ),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Invited by user #${invite.inviterId}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8E919A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 34,
            child: FilledButton(
              onPressed: () {
                context.read<GroupsProvider>().acceptInvite(invite.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Joined "$displayName"'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3D5AFE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Join'),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: 34,
            width: 34,
            child: IconButton(
              onPressed: () {
                context.read<GroupsProvider>().rejectInvite(invite.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Declined "$displayName"'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF2F3F7),
                foregroundColor: const Color(0xFF8E919A),
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String text) {
    final parts = text.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return text.substring(0, text.length.clamp(0, 2)).toUpperCase();
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 52, color: const Color(0xFFCDD0D9)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A4D56),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF8E919A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
