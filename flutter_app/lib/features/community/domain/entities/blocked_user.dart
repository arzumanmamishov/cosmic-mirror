import 'package:equatable/equatable.dart';

/// One entry of GET /api/v1/users/me/blocks — someone the current user
/// blocked (Settings → Blocked users).
class BlockedUser extends Equatable {
  const BlockedUser({
    required this.userId,
    required this.name,
    required this.blockedAt,
    this.avatarUrl,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      blockedAt: DateTime.tryParse(json['blocked_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String userId;
  final String name;
  final String? avatarUrl;
  final DateTime blockedAt;

  @override
  List<Object?> get props => [userId];
}
