import 'package:cursor_hack/features/ai_chat/models/agent_response.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProposedSlotsCard extends StatelessWidget {
  const ProposedSlotsCard({
    super.key,
    required this.slots,
    this.groupName,
    this.onSlotTap,
  });

  final List<ProposedSlot> slots;
  final String? groupName;
  final ValueChanged<ProposedSlot>? onSlotTap;

  @override
  Widget build(BuildContext context) {
    final bool tappable = onSlotTap != null;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E3EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF0FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.event_available_rounded, size: 16, color: Color(0xFF3D5AFE)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tappable ? 'Pick a time' : 'Suggested times',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                    if (groupName != null)
                      Text(
                        groupName!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF8E95A4)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...slots.map((slot) => _SlotTile(slot: slot, onTap: onSlotTap)),
          if (tappable)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Tap a slot to schedule it',
                style: TextStyle(fontSize: 11, color: Color(0xFF8E95A4), fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.slot, this.onTap});
  final ProposedSlot slot;
  final ValueChanged<ProposedSlot>? onTap;

  @override
  Widget build(BuildContext context) {
    final parsed = slot.parsedWindow;
    final dateFmt = DateFormat('EEE, MMM d');
    final timeFmt = DateFormat.jm();
    final bool tappable = onTap != null;

    String dateLabel = '';
    String timeLabel = '';
    if (parsed != null) {
      final (start, end) = parsed;
      dateLabel = dateFmt.format(start);
      timeLabel = '${timeFmt.format(start)} – ${timeFmt.format(end)}';
    } else {
      dateLabel = slot.freeWindow;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: tappable ? () => onTap!(slot) : null,
          borderRadius: BorderRadius.circular(12),
          splashColor: const Color(0x183D5AFE),
          highlightColor: const Color(0x0C3D5AFE),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tappable ? const Color(0xFFBCC5FF) : const Color(0xFFE0E3EB),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111111),
                        ),
                      ),
                      if (timeLabel.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          timeLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF3D5AFE),
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        '${slot.participantCount} available',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (tappable)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF0FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Color(0xFF3D5AFE),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
