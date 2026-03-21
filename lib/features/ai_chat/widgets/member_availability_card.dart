import 'package:cursor_hack/features/ai_chat/models/chat_message.dart';
import 'package:flutter/material.dart';

class MemberAvailabilityCard extends StatelessWidget {
  const MemberAvailabilityCard({
    super.key,
    required this.groupName,
    required this.schedules,
  });

  final String groupName;
  final Map<String, List<MemberScheduleSlot>> schedules;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10, right: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F8FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                  color: Color(0xFF3D5AFE),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$groupName — Member Availability',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...schedules.entries.map((entry) {
            final String name = entry.key;
            final List<MemberScheduleSlot> slots = entry.value;
            final bool allFree = slots.every((s) => !s.isBusy);
            return _MemberRow(name: name, slots: slots, allFree: allFree);
          }),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.name,
    required this.slots,
    required this.allFree,
  });

  final String name;
  final List<MemberScheduleSlot> slots;
  final bool allFree;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: allFree
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _initials(name),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: allFree
                          ? const Color(0xFF388E3C)
                          : const Color(0xFFF57C00),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111111),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: allFree
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  allFree ? 'Free' : '${slots.where((s) => s.isBusy).length} conflict(s)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: allFree
                        ? const Color(0xFF388E3C)
                        : const Color(0xFFF57C00),
                  ),
                ),
              ),
            ],
          ),
          if (slots.isNotEmpty && !allFree) ...[
            const SizedBox(height: 6),
            ...slots.where((s) => s.isBusy).map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(left: 36, bottom: 3),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF5350),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${s.title}  •  ${s.timeRange}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8E95A4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  String _initials(String name) {
    final List<String> parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }
}
