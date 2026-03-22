import 'package:cursor_hack/features/ai_chat/presentation/ai_chat_screen.dart';
import 'package:cursor_hack/features/auth/controllers/auth_provider.dart';
import 'package:cursor_hack/features/calendar/controllers/calendar_provider.dart';
import 'package:cursor_hack/features/calendar/presentation/calendar_screen.dart';
import 'package:cursor_hack/features/groups/presentation/groups_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const List<Widget> _screens = <Widget>[
    CalendarScreen(),
    GroupsScreen(),
    AiChatScreen(),
  ];

  void _switchTab(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    if (index == 0) {
      context.read<CalendarProvider>().refreshIfStale(DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      drawer: _AppDrawer(),
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: _screens),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE8EAF0), width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _NavItem(
                  icon: Icons.calendar_today_rounded,
                  label: 'Calendar',
                  isActive: _currentIndex == 0,
                  onTap: () => _switchTab(0),
                ),
                _NavItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Groups',
                  isActive: _currentIndex == 1,
                  onTap: () => _switchTab(1),
                ),
                _NavItem(
                  icon: Icons.auto_awesome_rounded,
                  label: 'AI Planner',
                  isActive: _currentIndex == 2,
                  onTap: () => _switchTab(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF7F8FA),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: <Color>[Color(0xFF6C63FF), Color(0xFF3D5AFE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.event_note_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Planite',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111111),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFE8EAF0), height: 32),
            _DrawerItem(
              icon: Icons.calendar_today_rounded,
              label: 'Calendar',
              onTap: () => Navigator.of(context).pop(),
            ),
            _DrawerItem(
              icon: Icons.group_outlined,
              label: 'Groups',
              onTap: () => Navigator.of(context).pop(),
            ),
            _DrawerItem(
              icon: Icons.auto_awesome_rounded,
              label: 'AI Planner',
              onTap: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
            const Divider(color: Color(0xFFE8EAF0), height: 1),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'Log Out',
              color: const Color(0xFFEF4444),
              onTap: () {
                Navigator.of(context).pop();
                _showLogoutConfirmation(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    final AuthProvider authProvider = context.read<AuthProvider>();
    final GoRouter router = GoRouter.of(context);

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Log Out',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(fontSize: 14, color: Color(0xFF8E95A4)),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF8E95A4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                authProvider.performLogout(router);
              },
              child: const Text(
                'Log Out',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color c = color ?? const Color(0xFF4B5563);
    return ListTile(
      leading: Icon(icon, size: 22, color: c),
      title: Text(
        label,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = isActive
        ? const Color(0xFF3D5AFE)
        : const Color(0xFF9CA3AF);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: isActive ? 20 : 0,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF3D5AFE) : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
