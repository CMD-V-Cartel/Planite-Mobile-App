import 'package:cursor_hack/features/groups/models/group_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventProposalCard extends StatelessWidget {
  const EventProposalCard({
    super.key,
    required this.proposal,
    required this.totalMembers,
    this.currentUserId,
    this.onAccept,
    this.onDecline,
    this.responding = false,
  });

  final EventProposal proposal;
  final int totalMembers;
  final int? currentUserId;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final bool responding;

  bool get _isInteractive => onAccept != null || onDecline != null;

  bool get _hasResponded =>
      currentUserId != null &&
      (proposal.acceptedBy.contains(currentUserId) ||
          proposal.declinedBy.contains(currentUserId) ||
          proposal.proposerId == currentUserId);

  @override
  Widget build(BuildContext context) {
    final start = proposal.startDateTime;
    final end = proposal.endDateTime;
    final dateFmt = DateFormat('EEE, MMM d');
    final timeFmt = DateFormat.jm();
    final dateLabel = start != null ? dateFmt.format(start) : '';
    final timeLabel = (start != null && end != null)
        ? '${timeFmt.format(start)} – ${timeFmt.format(end)}'
        : '';
    final acceptCount = proposal.acceptedBy.length;
    final progress = totalMembers > 0 ? acceptCount / totalMembers : 0.0;

    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;
    if (proposal.isConfirmed) {
      statusColor = const Color(0xFF4CAF50);
      statusLabel = 'Confirmed';
      statusIcon = Icons.check_circle_rounded;
    } else if (proposal.isCancelled) {
      statusColor = const Color(0xFF9E9E9E);
      statusLabel = 'Cancelled';
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = const Color(0xFFFFA726);
      statusLabel = 'Pending';
      statusIcon = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 6),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
              const Spacer(),
              Text(
                '$acceptCount / $totalMembers accepted',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E95A4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: const Color(0xFFE8EAF0),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            proposal.subject,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 13, color: Color(0xFF8E95A4)),
              const SizedBox(width: 5),
              Text(
                dateLabel,
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.access_time_rounded,
                  size: 13, color: Color(0xFF8E95A4)),
              const SizedBox(width: 5),
              Text(
                timeLabel,
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
              ),
            ],
          ),
          if (proposal.location != null &&
              proposal.location!.isNotEmpty) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 13, color: Color(0xFF8E95A4)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    proposal.location!,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF4B5563)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (_isInteractive && proposal.isProposed && !_hasResponded) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: responding ? null : onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Decline',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: responding ? null : onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF3D5AFE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: responding
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Accept',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
          if (!_isInteractive && proposal.isProposed)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'You proposed this event',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4CAF50),
                ),
              ),
            )
          else if (_isInteractive && _hasResponded && proposal.isProposed)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                proposal.proposerId == currentUserId
                    ? 'You proposed this event'
                    : proposal.acceptedBy.contains(currentUserId)
                        ? 'You accepted this proposal'
                        : 'You declined this proposal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: (proposal.proposerId == currentUserId ||
                          proposal.acceptedBy.contains(currentUserId))
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF9E9E9E),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
