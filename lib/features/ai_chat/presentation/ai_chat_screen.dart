import 'dart:async';
import 'dart:io';

import 'package:cursor_hack/features/ai_chat/models/agent_response.dart';
import 'package:cursor_hack/features/ai_chat/models/chat_message.dart';
import 'package:cursor_hack/features/ai_chat/repository/agent_repository.dart';
import 'package:cursor_hack/features/ai_chat/widgets/event_created_card.dart';
import 'package:cursor_hack/features/ai_chat/widgets/proposed_slots_card.dart';
import 'package:cursor_hack/features/ai_chat/widgets/typing_indicator.dart';
import 'package:cursor_hack/features/ai_chat/widgets/voice_record_button.dart';
import 'package:cursor_hack/features/calendar/controllers/calendar_provider.dart';
import 'package:cursor_hack/features/groups/controllers/groups_provider.dart';
import 'package:cursor_hack/features/groups/widgets/event_proposal_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AgentRepository _repo = AgentRepository();
  final AudioRecorder _recorder = AudioRecorder();

  final List<ChatMessage> _messages = <ChatMessage>[
    const ChatMessage(
      text: 'Hi! I\'m your AI planning assistant. '
          'Ask me to plan events, check availability, '
          'or manage your schedule. Hold the mic to speak!',
      isUser: false,
    ),
  ];

  bool _isRecording = false;
  bool _isSending = false;
  String? _recordingPath;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Scroll
  // ---------------------------------------------------------------------------

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Text send
  // ---------------------------------------------------------------------------

  Future<void> _sendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    _messageController.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _messages.add(const ChatMessage(text: '', isUser: false, type: MessageType.loading));
      _isSending = true;
    });
    _scrollToBottom();

    final int tzOffset = DateTime.now().timeZoneOffset.inHours;
    try {
      final AgentResponse res = await _repo.sendText(query: text, tzOffset: tzOffset);
      _replaceLoading(res);
      await _addToCalendar(res);
    } on AgentApiException catch (e) {
      _replaceLoadingWithError(e);
    } catch (_) {
      _replaceLoadingWithError(
        AgentApiException(0, 'Something went wrong. Please try again.'),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Audio recording
  // ---------------------------------------------------------------------------

  Future<void> _startRecording() async {
    if (_isSending) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission required for voice input'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    _recordingPath = p.join(dir.path, 'agent_voice_${DateTime.now().millisecondsSinceEpoch}.m4a');

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
      ),
      path: _recordingPath!,
    );

    _recordingSeconds = 0;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordingSeconds++);
    });

    if (mounted) setState(() => _isRecording = true);
  }

  Future<void> _stopAndSend() async {
    if (!_isRecording) return;

    _recordingTimer?.cancel();
    final path = await _recorder.stop();
    if (!mounted) return;

    setState(() => _isRecording = false);

    if (path == null || _recordingSeconds < 1) return;

    setState(() {
      _messages.add(ChatMessage(
        text: '🎤 Voice message (${_formatDuration(_recordingSeconds)})',
        isUser: true,
        type: MessageType.voice,
      ));
      _messages.add(const ChatMessage(text: '', isUser: false, type: MessageType.loading));
      _isSending = true;
    });
    _scrollToBottom();

    final int tzOffset = DateTime.now().timeZoneOffset.inHours;
    try {
      final AgentResponse res = await _repo.sendAudio(filePath: path, tzOffset: tzOffset);
      // If backend transcribed the audio, update the user bubble with the transcript.
      if (res.transcript != null && res.transcript!.isNotEmpty) {
        final idx = _messages.lastIndexWhere(
          (m) => m.isUser && m.type == MessageType.voice,
        );
        if (idx >= 0) {
          _messages[idx] = ChatMessage(text: res.transcript!, isUser: true, type: MessageType.voice);
        }
      }
      _replaceLoading(res);
      await _addToCalendar(res);
    } on AgentApiException catch (e) {
      _replaceLoadingWithError(e);
    } catch (_) {
      _replaceLoadingWithError(
        AgentApiException(0, 'Something went wrong. Please try again.'),
      );
    }

    // Clean up the temp file.
    try {
      await File(path).delete();
    } catch (_) {}
  }

  void _cancelRecording() async {
    _recordingTimer?.cancel();
    await _recorder.stop();
    if (_recordingPath != null) {
      try { await File(_recordingPath!).delete(); } catch (_) {}
    }
    if (mounted) setState(() => _isRecording = false);
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------------------
  // Slot selection (follow-up request → proposal + calendar add)
  // ---------------------------------------------------------------------------

  Future<void> _onSlotSelected(ProposedSlot slot, AgentResponse agentRes) async {
    if (_isSending) return;

    final group = agentRes.groupName ?? 'the group';

    // Build a time description from parsed dates when possible,
    // otherwise fall back to the raw free_window string the agent sent.
    String timeDesc;
    final parsed = slot.parsedWindow;
    if (parsed != null) {
      final (start, end) = parsed;
      final dateFmt = DateFormat('EEEE, MMMM d');
      final timeFmt = DateFormat.jm();
      timeDesc = '${dateFmt.format(start)} from ${timeFmt.format(start)} to ${timeFmt.format(end)}';
    } else {
      timeDesc = slot.freeWindow;
    }

    // Find the original user query that triggered these suggestions so the
    // agent gets full context (event subject, group, etc.) — the API is
    // stateless with no conversation memory.
    final suggestionMsgIdx = _messages.lastIndexWhere(
      (m) => !m.isUser && m.agentResponse == agentRes,
    );
    String originalQuery = '';
    if (suggestionMsgIdx > 0) {
      for (int i = suggestionMsgIdx - 1; i >= 0; i--) {
        if (_messages[i].isUser) {
          originalQuery = _messages[i].text;
          break;
        }
      }
    }

    final followUp = originalQuery.isNotEmpty
        ? '$originalQuery — schedule it for $group on $timeDesc'
        : 'Schedule a group event for $group on $timeDesc';

    setState(() {
      _messages.add(ChatMessage(text: followUp, isUser: true));
      _messages.add(const ChatMessage(
        text: '',
        isUser: false,
        type: MessageType.loading,
      ));
      _isSending = true;
    });
    _scrollToBottom();

    final int tzOffset = DateTime.now().timeZoneOffset.inHours;
    try {
      final AgentResponse res = await _repo.sendText(
        query: followUp,
        tzOffset: tzOffset,
      );
      _replaceLoading(res);
      await _addToCalendar(res);
    } on AgentApiException catch (e) {
      _replaceLoadingWithError(e);
    } catch (_) {
      _replaceLoadingWithError(
        AgentApiException(0, 'Something went wrong. Please try again.'),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Response handling
  // ---------------------------------------------------------------------------

  void _replaceLoading(AgentResponse res) {
    if (!mounted) return;
    setState(() {
      _messages.removeWhere((m) => m.isLoading);
      _messages.add(ChatMessage(text: res.response, isUser: false, agentResponse: res));
      _isSending = false;
    });
    _scrollToBottom();

    if (res.createdEvent != null || res.eventProposal != null) {
      context.read<CalendarProvider>().invalidateCache();
    }
  }

  /// Directly pushes an event to the user's Google Calendar via
  /// POST /calendar/events, so it appears immediately without waiting
  /// for the stale-cache → tab-switch refresh cycle.
  Future<void> _addToCalendar(AgentResponse res) async {
    if (!mounted) return;
    final calProvider = context.read<CalendarProvider>();

    if (res.eventProposal != null) {
      final p = res.eventProposal!;
      if (p.startDateTime != null && p.endDateTime != null) {
        await calProvider.createEvent(
          subject: p.subject,
          startTime: p.startDateTime!,
          endTime: p.endDateTime!,
          description: p.description,
          location: p.location,
        );
      }
    } else if (res.createdEvent != null) {
      final e = res.createdEvent!;
      if (e.startDateTime != null && e.endDateTime != null) {
        await calProvider.createEvent(
          subject: e.subject,
          startTime: e.startDateTime!,
          endTime: e.endDateTime!,
          description: e.description,
          location: e.location,
        );
      }
    }
  }

  void _replaceLoadingWithError(AgentApiException e) {
    if (!mounted) return;

    if (e.statusCode == 401) {
      GoRouter.of(context).go('/login');
      return;
    }

    setState(() {
      _messages.removeWhere((m) => m.isLoading);
      _messages.add(ChatMessage(text: e.message, isUser: false, type: MessageType.system));
      _isSending = false;
    });
    _scrollToBottom();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        _buildHeader(),
        const Divider(height: 1, thickness: 0.5, color: Color(0xFFE8EAF0)),
        if (_isRecording) _buildRecordingBanner(),
        Expanded(child: _buildMessageList()),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF3D5AFE)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Planner',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111111)),
                ),
                SizedBox(height: 2),
                Text(
                  'Online',
                  style: TextStyle(fontSize: 12, color: Color(0xFF4CAF50), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFFFF3E0),
      child: Row(
        children: [
          const _PulsingDot(),
          const SizedBox(width: 10),
          Text(
            'Recording… ${_formatDuration(_recordingSeconds)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE65100),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _cancelRecording,
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFEF5350)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        reverse: true,
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final msg = _messages[_messages.length - 1 - index];
          if (msg.isLoading) return const TypingIndicator();
          return _MessageBubble(
            message: msg,
            onSlotSelected: _onSlotSelected,
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8EAF0), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            GestureDetector(
              onLongPressStart: (_) => _startRecording(),
              onLongPressEnd: (_) => _stopAndSend(),
              onLongPressCancel: _cancelRecording,
              child: VoiceRecordButton(
                isListening: _isRecording,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hold the mic button to record'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _messageController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendText(),
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Ask anything…',
                  hintStyle: const TextStyle(color: Color(0xFFB0B5C0), fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFFF2F3F7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Material(
              color: const Color(0xFF3D5AFE),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _sendText,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Message bubble — renders adaptively based on intent
// =============================================================================

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, this.onSlotSelected});
  final ChatMessage message;
  final void Function(ProposedSlot slot, AgentResponse agentRes)? onSlotSelected;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    final bool isUser = message.isUser;
    final agentRes = message.agentResponse;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 10,
          left: isUser ? 48 : 0,
          right: isUser ? 0 : 48,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (isUser && message.type == MessageType.voice)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.mic_rounded, size: 12, color: Color(0xFF8E95A4)),
                    SizedBox(width: 4),
                    Text('Voice', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8E95A4))),
                  ],
                ),
              ),

            // Text bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.type == MessageType.system
                    ? const Color(0xFFFFF3E0)
                    : isUser
                        ? const Color(0xFF3D5AFE)
                        : const Color(0xFFF2F3F7),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: message.type == MessageType.system
                      ? const Color(0xFFE65100)
                      : isUser
                          ? Colors.white
                          : const Color(0xFF1A1A1A),
                ),
              ),
            ),

            // Adaptive content below AI bubble
            if (!isUser && agentRes != null) ...[
              if (agentRes.eventProposal != null)
                Builder(builder: (ctx) {
                  final proposal = agentRes.eventProposal!;
                  final groupsProvider = ctx.read<GroupsProvider>();
                  final group = groupsProvider.groups.where(
                    (g) => g.groupId == proposal.groupId,
                  );
                  final memberCount = group.isNotEmpty
                      ? group.first.members.length
                      : (proposal.acceptedBy.length + proposal.declinedBy.length)
                          .clamp(1, 999);
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: EventProposalCard(
                      proposal: proposal,
                      totalMembers: memberCount,
                    ),
                  );
                })
              else if (agentRes.intent == 'personal_event' && agentRes.createdEvent != null)
                EventCreatedCard(event: agentRes.createdEvent!),
              // Only show available slots when no proposal was created
              // (i.e. the AI couldn't find a matching slot and is offering alternatives).
              if (agentRes.eventProposal == null &&
                  agentRes.intent == 'group_planning' &&
                  agentRes.proposedSlots.isNotEmpty)
                ProposedSlotsCard(
                  slots: agentRes.proposedSlots,
                  groupName: agentRes.groupName,
                  onSlotTap: onSlotSelected != null
                      ? (slot) => onSlotSelected!(slot, agentRes)
                      : null,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Pulsing recording dot
// =============================================================================

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(color: Color(0xFFEF5350), shape: BoxShape.circle),
      ),
    );
  }
}
