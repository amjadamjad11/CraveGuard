import '../services/api_service.dart';
import '../services/demo_service.dart';

/// Repository that abstracts chat / AI-coach data access.
/// Returns demo data when [isDemoMode] is true, otherwise calls the real API.
class ChatRepository {
  final ApiService api;
  final DemoService demo;
  final bool isDemoMode;

  ChatRepository({
    required this.api,
    required this.demo,
    required this.isDemoMode,
  });

  /// Returns chat messages for the current conversation.
  /// In API mode, [conversationId] is used to fetch from the backend.
  Future<List<Map<String, dynamic>>> getMessages({int? conversationId}) async {
    if (isDemoMode) {
      return demo.chatMessages;
    }
    if (conversationId == null) {
      // Create a new conversation first.
      final resp = await api.post('/chat/conversations');
      conversationId = resp.data['id'] as int;
    }
    final resp =
        await api.get('/chat/conversations/$conversationId/messages');
    return List<Map<String, dynamic>>.from(resp.data);
  }

  /// Sends a user message and returns the assistant's response.
  /// In demo mode, returns a fallback response from [DemoService].
  Future<Map<String, dynamic>> sendMessage(
    String message, {
    int? conversationId,
  }) async {
    if (isDemoMode) {
      return {
        'id': DateTime.now().millisecondsSinceEpoch,
        'role': 'assistant',
        'content': demo.getFallbackChatResponse(message),
        'created_at': DateTime.now().toIso8601String(),
      };
    }
    if (conversationId == null) {
      final resp = await api.post('/chat/conversations');
      conversationId = resp.data['id'] as int;
    }
    final resp = await api.post(
      '/chat/conversations/$conversationId/messages',
      data: {'content': message},
    );
    return Map<String, dynamic>.from(resp.data);
  }

  /// Clears the current conversation history.
  Future<void> clearConversation({int? conversationId}) async {
    if (isDemoMode) {
      return;
    }
    if (conversationId != null) {
      await api.delete('/chat/conversations/$conversationId');
    }
  }
}
