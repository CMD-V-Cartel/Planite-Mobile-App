import 'package:cursor_hack/features/ai_chat/models/agent_response.dart';

enum MessageType { text, voice, loading, system }

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.type = MessageType.text,
    this.agentResponse,
  });

  final String text;
  final bool isUser;
  final MessageType type;
  final AgentResponse? agentResponse;

  bool get isLoading => type == MessageType.loading;
}
