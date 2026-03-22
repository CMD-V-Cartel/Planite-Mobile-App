import 'package:cursor_hack/features/ai_chat/models/chat_message.dart';
import 'package:cursor_hack/features/ai_chat/widgets/group_selector_sheet.dart';
import 'package:cursor_hack/features/ai_chat/widgets/member_availability_card.dart';
import 'package:cursor_hack/features/ai_chat/widgets/voice_record_button.dart';
import 'package:cursor_hack/features/groups/data/demo_groups.dart';
import 'package:cursor_hack/features/groups/models/group_model.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _messageController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  final List<ChatMessage> _messages = <ChatMessage>[
    const ChatMessage(
      text: 'Hi! I\'m your AI planning assistant. '
          'Ask me to plan events, check member availability, '
          'or send messages to your groups. Tap the mic to use voice!',
      isUser: false,
    ),
  ];

  bool _speechAvailable = false;
  bool _isListening = false;
  String _liveTranscript = '';
  Group? _targetGroup;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speechToText.initialize(
      onError: (error) {
        debugPrint('SpeechToText error: ${error.errorMsg}');
        if (mounted) setState(() => _isListening = false);
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) {
            setState(() => _isListening = false);
            if (_liveTranscript.trim().isNotEmpty) {
              _messageController.text = _liveTranscript.trim();
              _liveTranscript = '';
            }
          }
        }
      },
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _messageController.dispose();
    _speechToText.stop();
    super.dispose();
  }

  void _toggleListening() {
    if (_isListening) {
      _speechToText.stop();
      setState(() {
        _isListening = false;
        if (_liveTranscript.trim().isNotEmpty) {
          _messageController.text = _liveTranscript.trim();
          _liveTranscript = '';
        }
      });
    } else if (_speechAvailable) {
      setState(() {
        _isListening = true;
        _liveTranscript = '';
      });
      _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition not available on this device'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _liveTranscript = result.recognizedWords;
    });
    if (result.finalResult && _liveTranscript.trim().isNotEmpty) {
      _messageController.text = _liveTranscript.trim();
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: _messageController.text.length),
      );
      setState(() {
        _isListening = false;
        _liveTranscript = '';
      });
    }
  }

  void _openGroupSelector() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GroupSelectorSheet(
        groups: demoGroups,
        selectedGroup: _targetGroup,
        onSelected: (Group? group) {
          setState(() => _targetGroup = group);
        },
      ),
    );
  }

  void _sendMessage() {
    final String text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        targetGroup: _targetGroup,
        type: MessageType.text,
      ));
      _messageController.clear();
    });

    _generateAiResponse(text);
  }

  void _generateAiResponse(String userText) {
    final String lower = userText.toLowerCase();
    final bool isAvailabilityQuery = lower.contains('availab') ||
        lower.contains('schedule') ||
        lower.contains('busy') ||
        lower.contains('free') ||
        lower.contains('conflict');

    if (_targetGroup != null && isAvailabilityQuery) {
      _showAvailabilityResponse(_targetGroup!);
      return;
    }

    if (_targetGroup != null) {
      Future<void>.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          _messages.add(ChatMessage(
            text: 'Got it! I\'ll relay your message to "${_targetGroup!.name}". '
                'Would you like me to check member availability before scheduling?',
            isUser: false,
            targetGroup: _targetGroup,
          ));
        });
      });
      return;
    }

    if (isAvailabilityQuery) {
      Future<void>.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          _messages.add(const ChatMessage(
            text: 'Which group would you like me to check availability for? '
                'Tap the group icon below to select one.',
            isUser: false,
          ));
        });
      });
      return;
    }

    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _messages.add(const ChatMessage(
          text: 'Thanks for the message! I can help you plan events, '
              'check member schedules, and coordinate with your groups. '
              'Try selecting a group and asking about availability.',
          isUser: false,
        ));
      });
    });
  }

  void _showAvailabilityResponse(Group group) {
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;

      final Map<String, List<MemberScheduleSlot>> schedules =
          _buildDemoSchedules(group);

      setState(() {
        _messages.add(ChatMessage(
          text: 'Here\'s the availability for ${group.name}:',
          isUser: false,
        ));
        _messages.add(ChatMessage(
          text: '',
          isUser: false,
          type: MessageType.availability,
          targetGroup: group,
          memberSchedules: schedules,
        ));

        final int busyCount = schedules.values
            .where((slots) => slots.any((s) => s.isBusy))
            .length;
        final int freeCount = schedules.length - busyCount;

        _messages.add(ChatMessage(
          text: '$freeCount member(s) are completely free. '
              '$busyCount member(s) have conflicts. '
              'Would you like to find a time that works for everyone?',
          isUser: false,
        ));
      });
    });
  }

  Map<String, List<MemberScheduleSlot>> _buildDemoSchedules(Group group) {
    final Map<String, List<MemberScheduleSlot>> schedules = {};
    for (int i = 0; i < group.members.length; i++) {
      final member = group.members[i];
      final label = 'User #${member.userId}';
      switch (i % 4) {
        case 0:
          schedules[label] = const [
            MemberScheduleSlot(title: 'Team standup', timeRange: '9:00 – 9:30 AM'),
            MemberScheduleSlot(title: 'Design review', timeRange: '2:00 – 3:00 PM'),
          ];
        case 1:
          schedules[label] = const [];
        case 2:
          schedules[label] = const [
            MemberScheduleSlot(title: 'Client call', timeRange: '11:00 AM – 12:00 PM'),
          ];
        case 3:
          schedules[label] = const [];
      }
    }
    return schedules;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: <Widget>[
        _buildHeader(),
        const Divider(height: 1, thickness: 0.5, color: Color(0xFFE8EAF0)),
        if (_targetGroup != null) _buildGroupBanner(),
        if (_isListening) _buildLiveTranscriptBanner(),
        Expanded(child: _buildMessageList()),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF6C63FF), Color(0xFF3D5AFE)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'AI Planner',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _openGroupSelector,
            icon: const Icon(Icons.group_add_outlined),
            color: const Color(0xFF3D5AFE),
            tooltip: 'Select group',
          ),
        ],
      ),
    );
  }

  Widget _buildGroupBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _targetGroup!.avatarColor.withValues(alpha: 0.1),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: _targetGroup!.avatarColor,
            radius: 12,
            child: Text(
              _targetGroup!.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Messaging ${_targetGroup!.name}  •  ${_targetGroup!.members.length} members',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _targetGroup = null),
            child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF8E95A4)),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTranscriptBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFFFF3E0),
      child: Row(
        children: <Widget>[
          const _PulsingDot(),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _liveTranscript.isEmpty ? 'Listening…' : _liveTranscript,
              style: TextStyle(
                fontSize: 13,
                fontStyle:
                    _liveTranscript.isEmpty ? FontStyle.italic : FontStyle.normal,
                color: const Color(0xFF4B5563),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      reverse: true,
      itemCount: _messages.length,
      itemBuilder: (BuildContext context, int index) {
        final ChatMessage msg = _messages[_messages.length - 1 - index];
        if (msg.type == MessageType.availability &&
            msg.memberSchedules != null) {
          return MemberAvailabilityCard(
            groupName: msg.targetGroup?.name ?? 'Group',
            schedules: msg.memberSchedules!,
          );
        }
        return _ChatBubble(message: msg);
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE8EAF0), width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            VoiceRecordButton(
              isListening: _isListening,
              onTap: _toggleListening,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _messageController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: _targetGroup != null
                      ? 'Message ${_targetGroup!.name}…'
                      : 'Ask anything…',
                  hintStyle: const TextStyle(
                    color: Color(0xFFB0B5C0),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF2F3F7),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
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
                onTap: _sendMessage,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 10,
          left: isUser ? 48 : 0,
          right: isUser ? 0 : 48,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            if (isUser && message.targetGroup != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.group_rounded,
                      size: 12,
                      color: message.targetGroup!.avatarColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      message.targetGroup!.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: message.targetGroup!.avatarColor,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
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
                  color: isUser ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
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
        decoration: const BoxDecoration(
          color: Color(0xFFEF5350),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
