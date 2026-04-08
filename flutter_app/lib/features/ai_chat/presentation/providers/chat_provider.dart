import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../data/models/chat_models.dart';
import '../../domain/entities/chat_entities.dart';

final chatThreadsProvider =
    FutureProvider.autoDispose<List<ChatThread>>((ref) async {
  final client = ref.read(apiClientProvider);
  final data = await client.get<Map<String, dynamic>>(
    ApiEndpoints.chatThreads,
  );
  final threads = (data['threads'] as List<dynamic>)
      .map((t) => ChatThreadModel.fromJson(t as Map<String, dynamic>))
      .toList();
  return threads;
});

final chatMessagesProvider = FutureProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, threadId) async {
  final client = ref.read(apiClientProvider);
  final data = await client.get<Map<String, dynamic>>(
    ApiEndpoints.chatMessages(threadId),
  );
  final messages = (data['messages'] as List<dynamic>)
      .map((m) => ChatMessageModel.fromJson(m as Map<String, dynamic>))
      .toList();
  return messages;
});

final chatInputProvider =
    StateNotifierProvider.autoDispose<ChatInputNotifier, ChatInputState>((ref) {
  return ChatInputNotifier(ref.read(apiClientProvider));
});

class ChatInputState {
  const ChatInputState({
    this.isSending = false,
    this.error,
  });

  final bool isSending;
  final String? error;
}

class ChatInputNotifier extends StateNotifier<ChatInputState> {
  ChatInputNotifier(this._client) : super(const ChatInputState());

  final ApiClient _client;

  Future<String?> createThread() async {
    try {
      final data = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.chatThreads,
      );
      return data['id'] as String;
    } catch (e) {
      state = ChatInputState(error: e.toString());
      return null;
    }
  }

  Future<ChatMessage?> sendMessage(String threadId, String content) async {
    state = const ChatInputState(isSending: true);
    try {
      final data = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.chatMessages(threadId),
        data: {'content': content},
      );
      state = const ChatInputState();
      return ChatMessageModel.fromJson(data);
    } catch (e) {
      state = ChatInputState(error: e.toString());
      return null;
    }
  }
}
