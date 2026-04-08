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
