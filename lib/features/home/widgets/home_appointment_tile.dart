import 'package:cursor_hack/features/home/models/task_appointment.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeAppointmentTile extends StatelessWidget {
  const HomeAppointmentTile({
    super.key,
    required this.task,
    required this.onToggleComplete,
  });

  final TaskAppointment task;
  final VoidCallback onToggleComplete;

  @override
  Widget build(BuildContext context) {
    final Color accent = task.color;
    final String range =
        '${DateFormat('h:mm a').format(task.startTime)} – ${DateFormat('h:mm a').format(task.endTime)}';

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxHeight < 44;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: Row(
            children: <Widget>[
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: compact ? 2 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: compact
                            ? Text(
                                '${task.subject}  $range',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  color: task.isCompleted
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF1A1A1A),
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: const Color(0xFF9CA3AF),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Flexible(
                                    child: Text(
                                      task.subject,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: task.isCompleted
                                            ? const Color(0xFF9CA3AF)
                                            : const Color(0xFF1A1A1A),
                                        decoration: task.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                        decorationColor:
                                            const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    range,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFB0B5C0),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      if (!compact) ...<Widget>[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onToggleComplete,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: task.isCompleted
                                    ? accent
                                    : const Color(0xFFD1D5DB),
                                width: 1.8,
                              ),
                              color: task.isCompleted
                                  ? accent
                                  : Colors.transparent,
                            ),
                            child: task.isCompleted
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
