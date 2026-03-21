import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeCalendarHeader extends StatelessWidget {
  const HomeCalendarHeader({
    super.key,
    required this.displayDate,
    required this.onOpenMenu,
    required this.onSearch,
    required this.onClose,
  });

  final DateTime displayDate;
  final VoidCallback onOpenMenu;
  final VoidCallback onSearch;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final String title = DateFormat('MMMM yyyy').format(displayDate);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onOpenMenu,
            icon: const Icon(Icons.menu_rounded),
            color: const Color(0xFF1A1A1A),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
            ),
          ),
          IconButton(
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded),
            color: const Color(0xFF1A1A1A),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: const Color(0xFF1A1A1A),
          ),
        ],
      ),
    );
  }
}
