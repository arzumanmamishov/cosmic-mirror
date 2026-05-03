import 'package:equatable/equatable.dart';

class SpaceCategory extends Equatable {
  const SpaceCategory({
    required this.id,
    required this.name,
    this.icon,
    this.sortOrder = 0,
  });

  factory SpaceCategory.fromJson(Map<String, dynamic> json) {
    return SpaceCategory(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String name;
  final String? icon;
  final int sortOrder;

  @override
  List<Object?> get props => [id];
}

class Space extends Equatable {
  const Space({
    required this.id,
    required this.handle,
    required this.name,
    required this.createdBy,
    required this.memberCount,
    required this.isVerified,
    required this.isSpicy,
    required this.createdAt,
    this.description,
    this.avatarUrl,
    this.categoryId,
  });

  factory Space.fromJson(Map<String, dynamic> json) {
    return Space(
      id: json['id'] as String? ?? '',
      handle: json['handle'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      categoryId: json['category_id'] as String?,
      createdBy: json['created_by'] as String? ?? '',
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      isSpicy: json['is_spicy'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final String handle;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String? categoryId;
  final String createdBy;
  final int memberCount;
  final bool isVerified;
  final bool isSpicy;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, handle, memberCount];
}

/// List-response variant: Space + per-viewer flag + joined category name.
class SpaceWithMeta extends Equatable {
  const SpaceWithMeta({
    required this.space,
    required this.isJoined,
    this.categoryName,
  });

  factory SpaceWithMeta.fromJson(Map<String, dynamic> json) {
    return SpaceWithMeta(
      space: Space.fromJson(json),
      isJoined: json['is_joined'] as bool? ?? false,
      categoryName: json['category_name'] as String?,
    );
  }

  final Space space;
  final bool isJoined;
  final String? categoryName;

  @override
  List<Object?> get props => [space, isJoined];
}

class SpaceMember extends Equatable {
  const SpaceMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.userName,
    this.userAvatarUrl,
  });

  factory SpaceMember.fromJson(Map<String, dynamic> json) {
    return SpaceMember(
      userId: json['user_id'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      joinedAt: DateTime.tryParse(json['joined_at'] as String? ?? '') ??
          DateTime.now(),
      userName: json['user_name'] as String? ?? '',
      userAvatarUrl: json['user_avatar_url'] as String?,
    );
  }

  final String userId;
  final String role;
  final DateTime joinedAt;
  final String userName;
  final String? userAvatarUrl;

  @override
  List<Object?> get props => [userId, role];
}
