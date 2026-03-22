import 'package:cursor_hack/features/ai_chat/models/agent_response.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventCreatedCard extends StatelessWidget {
  const EventCreatedCard({super.key, required this.event});
  final CreatedEvent event;

  @override
  Widget build(BuildContext context) {
    final start = event.startDateTime;
    final end = event.endDateTime;
    final dateFmt = DateFormat('EEE, MMM d');
    final timeFmt = DateFormat.jm();
    final dateLabel = start != null ? dateFmt.format(start) : '';
    final timeLabel = (start != null && end != null)
        ? '${timeFmt.format(start)} – ${timeFmt.format(end)}'
        : '';

    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 10, right: 48),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAF0)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                event.pushedToGoogle
                    ? Icons.check_circle_rounded
                    : Icons.cloud_off_rounded,
                size: 16,
                color: event.pushedToGoogle
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFFA726),
              ),
              const SizedBox(width: 6),
              Text(
                event.pushedToGoogle ? 'Added to Google Calendar' : 'Saved locally',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: event.pushedToGoogle
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFFA726),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            event.subject,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF8E95A4)),
              const SizedBox(width: 5),
              Text(
                dateLabel,
                style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF8E95A4)),
              const SizedBox(width: 5),
              Text(
                timeLabel,
                style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
              ),
            ],
          ),
          if (event.location != null && event.location!.isNotEmpty) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF8E95A4)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    event.location!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
