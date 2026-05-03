import 'package:equatable/equatable.dart';

class CommunityNotification extends Equatable {
  const CommunityNotification({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.targetType,
    required this.targetId,
    required this.createdAt,
    this.actorId,
    this.snippet,
    this.readAt,
  });

  factory CommunityNotification.fromJson(Map<String, dynamic> json) {
    return CommunityNotification(
      id: json['id'] as String? ?? '',
      recipientId: json['recipient_id'] as String? ?? '',
      actorId: json['actor_id'] as String?,
      type: json['type'] as String? ?? '',
      targetType: json['target_type'] as String? ?? '',
      targetId: json['target_id'] as String? ?? '',
      snippet: json['snippet'] as String?,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'] as String)
          : null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final String recipientId;
  final String? actorId;
  final String type;
  final String targetType;
  final String targetId;
  final String? snippet;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isUnread => readAt == null;

  @override
  List<Object?> get props => [id, readAt];
}

class NotificationWithMeta extends Equatable {
  const NotificationWithMeta({
    required this.notification,
    this.actorName,
    this.actorAvatarUrl,
  });

  factory NotificationWithMeta.fromJson(Map<String, dynamic> json) {
    return NotificationWithMeta(
      notification: CommunityNotification.fromJson(json),
      actorName: json['actor_name'] as String?,
      actorAvatarUrl: json['actor_avatar_url'] as String?,
    );
  }

  final CommunityNotification notification;
  final String? actorName;
  final String? actorAvatarUrl;

  @override
  List<Object?> get props => [notification];
}

class Hashtag extends Equatable {
  const Hashtag({
    required this.id,
    required this.name,
    required this.useCount,
  });

  factory Hashtag.fromJson(Map<String, dynamic> json) {
    return Hashtag(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      useCount: (json['use_count'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String name;
  final int useCount;

  @override
  List<Object?> get props => [id];
}
