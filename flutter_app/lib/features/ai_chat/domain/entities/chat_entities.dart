import 'package:equatable/equatable.dart';

class ChatThread extends Equatable {
  const ChatThread({
    required this.id,
    required this.createdAt,
    this.title,
    this.lastMessage,
    this.updatedAt,
  });

  final String id;
  final String? title;
  final String? lastMessage;
  final DateTime createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id];
}

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String threadId;
  final MessageRole role;
  final String content;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id];
}

enum MessageRole { user, assistant }

/// User's AI-chat consumption for the day. The free tier has a daily
/// cap; premium subscribers are unlimited (`isPremium` true and `limit`
/// effectively informational).
class ChatUsage extends Equatable {
  const ChatUsage({
    required this.used,
    required this.limit,
    required this.isPremium,
    required this.resetAt,
  });

  factory ChatUsage.fromJson(Map<String, dynamic> json) {
    return ChatUsage(
      used: (json['used'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      isPremium: json['is_premium'] as bool? ?? false,
      resetAt: DateTime.tryParse(json['reset_at'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }

  final int used;
  final int limit;
  final bool isPremium;
  final DateTime resetAt;

  bool get atLimit => !isPremium && used >= limit;
  int get remaining => isPremium ? -1 : (limit - used).clamp(0, limit);

  @override
  List<Object?> get props => [used, limit, isPremium, resetAt];
}
