import 'package:cosmic_mirror/features/community/domain/entities/post.dart';
import 'package:cosmic_mirror/features/community/domain/entities/space.dart';
import 'package:equatable/equatable.dart';

/// Public community-profile of a user — display info, joined spaces, and
/// recent posts. Returned by GET /api/v1/community/users/{id|me}.
class UserCommunityProfile extends Equatable {
  const UserCommunityProfile({
    required this.userId,
    required this.name,
    required this.joinedSpaces,
    required this.recentPosts,
    this.isBlockedByMe = false,
  });

  factory UserCommunityProfile.fromJson(Map<String, dynamic> json) {
    return UserCommunityProfile(
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      joinedSpaces: ((json['joined_spaces'] as List<dynamic>?) ?? const [])
          .map((e) => SpaceWithMeta.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentPosts: ((json['recent_posts'] as List<dynamic>?) ?? const [])
          .map((e) => PostWithMeta.fromJson(e as Map<String, dynamic>))
          .toList(),
      isBlockedByMe: json['is_blocked_by_me'] as bool? ?? false,
    );
  }

  final String userId;
  final String name;
  final List<SpaceWithMeta> joinedSpaces;
  final List<PostWithMeta> recentPosts;

  /// The viewer has blocked this user. When either side blocked the
  /// other, the server returns empty spaces / posts.
  final bool isBlockedByMe;

  @override
  List<Object?> get props => [userId, joinedSpaces, recentPosts, isBlockedByMe];
}
