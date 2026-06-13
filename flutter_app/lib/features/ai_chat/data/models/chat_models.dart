import 'package:cosmic_mirror/features/ai_chat/domain/entities/chat_entities.dart';

class ChatThreadModel extends ChatThread {
  const ChatThreadModel({
    required super.id,
    required super.createdAt,
    super.title,
    super.lastMessage,
    super.updatedAt,
  });

  factory ChatThreadModel.fromJson(Map<String, dynamic> json) {
    return ChatThreadModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String?,
      lastMessage: json['last_message'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
              DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }
}

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.threadId,
    required super.role,
    required super.content,
    required super.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String? ?? '',
      threadId: json['thread_id'] as String? ?? '',
      role: json['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
      content: json['content'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
              DateTime.now(),
    );
  }
}
