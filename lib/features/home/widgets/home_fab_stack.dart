import 'package:flutter/material.dart';

class HomeFabStack extends StatelessWidget {
  const HomeFabStack({
    super.key,
    required this.onTasks,
    required this.onCalendar,
    required this.onClose,
  });

  final VoidCallback onTasks;
  final VoidCallback onCalendar;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        FloatingActionButton.small(
          heroTag: 'home_fab_tasks',
          backgroundColor: const Color(0xFFFF8A50),
          onPressed: onTasks,
          child: const Icon(Icons.assignment_outlined, color: Colors.white),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.small(
          heroTag: 'home_fab_calendar',
          backgroundColor: const Color(0xFF4CAF79),
          onPressed: onCalendar,
          child: const Icon(Icons.calendar_today_rounded, color: Colors.white),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'home_fab_close',
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E3A5F),
          elevation: 3,
          onPressed: onClose,
          child: const Icon(Icons.close_rounded, size: 28),
        ),
      ],
    );
  }
}
