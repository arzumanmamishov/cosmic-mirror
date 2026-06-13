import 'package:cosmic_mirror/core/error/exceptions.dart';
import 'package:cosmic_mirror/core/network/api_client.dart';
import 'package:cosmic_mirror/core/network/api_endpoints.dart';
import 'package:cosmic_mirror/features/ai_chat/data/models/chat_models.dart';
import 'package:cosmic_mirror/features/ai_chat/domain/entities/chat_entities.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatThreadsProvider =
    FutureProvider.autoDispose<List<ChatThread>>((ref) async {
  final client = ref.read(apiClientProvider);
  final data = await client.get<Map<String, dynamic>>(
    ApiEndpoints.chatThreads,
  );
  // Backend may return null for an empty list; treat it as []
  final raw = data['threads'] as List<dynamic>? ?? const [];
  return raw
      .map((t) => ChatThreadModel.fromJson(t as Map<String, dynamic>))
      .toList();
});

/// User's AI-chat consumption for today. Refresh by invalidating this
/// provider after each successful send (or after a 429) so the counter
/// stays in sync with the server.
final chatUsageProvider = FutureProvider.autoDispose<ChatUsage>((ref) async {
  final client = ref.read(apiClientProvider);
  final data = await client.get<Map<String, dynamic>>(
    ApiEndpoints.chatUsage,
  );
  return ChatUsage.fromJson(data);
});

final chatMessagesProvider = FutureProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, threadId) async {
  final client = ref.read(apiClientProvider);
  final data = await client.get<Map<String, dynamic>>(
    ApiEndpoints.chatMessages(threadId),
  );
  // Backend may return null for an empty list; treat it as []
  final raw = data['messages'] as List<dynamic>? ?? const [];
  return raw
      .map((m) => ChatMessageModel.fromJson(m as Map<String, dynamic>))
      .toList();
});

final chatInputProvider =
    StateNotifierProvider.autoDispose<ChatInputNotifier, ChatInputState>((ref) {
  return ChatInputNotifier(ref);
});

class ChatInputState {
  const ChatInputState({
    this.isSending = false,
    this.error,
    this.limitReached = false,
  });

  final bool isSending;
  final String? error;

  /// True when the last send was rejected with a 429 (daily cap hit).
  /// Use this to render the paywall card without re-querying state.
  final bool limitReached;
}

class ChatInputNotifier extends StateNotifier<ChatInputState> {
  ChatInputNotifier(this._ref)
      : _client = _ref.read(apiClientProvider),
        super(const ChatInputState());

  final Ref _ref;
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

  /// Deletes a thread on the backend. Returns null on success or the
  /// raw exception on failure so the caller can run it through
  /// FriendlyError.from(...) and show a localized snackbar.
  Future<Object?> deleteThread(String threadId) async {
    try {
      await _client.delete(ApiEndpoints.chatThread(threadId));
      return null;
    } catch (e) {
      state = ChatInputState(error: e.toString());
      return e;
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
      // Bump the usage counter so the UI updates immediately.
      _ref.invalidate(chatUsageProvider);
      return ChatMessageModel.fromJson(data);
    } on RateLimitException catch (e) {
      state = ChatInputState(
        error: e.message,
        limitReached: true,
      );
      // Refresh usage so the counter shows the cap.
      _ref.invalidate(chatUsageProvider);
      return null;
    } catch (e) {
      state = ChatInputState(error: e.toString());
      return null;
    }
  }

  void clearLimitReached() {
    if (state.limitReached) {
      state = const ChatInputState();
    }
  }
}
