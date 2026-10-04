import 'package:equatable/equatable.dart';

class Post extends Equatable {
  const Post({
    required this.id,
    required this.spaceId,
    required this.authorId,
    required this.content,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    required this.updatedAt,
    this.linkUrl,
    this.hiddenAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String? ?? '',
      spaceId: json['space_id'] as String? ?? '',
      authorId: json['author_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      linkUrl: json['link_url'] as String?,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
      hiddenAt: DateTime.tryParse(json['hidden_at'] as String? ?? ''),
    );
  }

  final String id;
  final String spaceId;
  final String authorId;
  final String content;
  final String? linkUrl;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Set when moderation hid the post (auto-hide after repeated reports,
  /// or a moderator). The server only returns hidden posts to their
  /// author, so the UI shows an "under review" note.
  final DateTime? hiddenAt;
  bool get isHidden => hiddenAt != null;

  @override
  List<Object?> get props => [id, likeCount, commentCount, hiddenAt];
}

/// Feed-shape variant: Post + author / space metadata + per-viewer flag.
class PostWithMeta extends Equatable {
  const PostWithMeta({
    required this.post,
    required this.authorName,
    required this.spaceHandle,
    required this.spaceName,
    required this.isLikedByMe,
    this.authorAvatarUrl,
  });

  factory PostWithMeta.fromJson(Map<String, dynamic> json) {
    return PostWithMeta(
      post: Post.fromJson(json),
      authorName: json['author_name'] as String? ?? '',
      authorAvatarUrl: json['author_avatar_url'] as String?,
      spaceHandle: json['space_handle'] as String? ?? '',
      spaceName: json['space_name'] as String? ?? '',
      isLikedByMe: json['is_liked_by_me'] as bool? ?? false,
    );
  }

  final Post post;
  final String authorName;
  final String? authorAvatarUrl;
  final String spaceHandle;
  final String spaceName;
  final bool isLikedByMe;

  @override
  List<Object?> get props => [post, isLikedByMe];
}

class Comment extends Equatable {
  const Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    required this.likeCount,
    required this.createdAt,
    required this.updatedAt,
    this.parentCommentId,
    this.hiddenAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String? ?? '',
      postId: json['post_id'] as String? ?? '',
      parentCommentId: json['parent_comment_id'] as String?,
      authorId: json['author_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
      hiddenAt: DateTime.tryParse(json['hidden_at'] as String? ?? ''),
    );
  }

  final String id;
  final String postId;
  final String? parentCommentId;
  final String authorId;
  final String content;
  final int likeCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// See [Post.hiddenAt].
  final DateTime? hiddenAt;
  bool get isHidden => hiddenAt != null;

  @override
  List<Object?> get props => [id, likeCount, hiddenAt];
}

class CommentWithMeta extends Equatable {
  const CommentWithMeta({
    required this.comment,
    required this.authorName,
    required this.isLikedByMe,
    this.authorAvatarUrl,
  });

  factory CommentWithMeta.fromJson(Map<String, dynamic> json) {
    return CommentWithMeta(
      comment: Comment.fromJson(json),
      authorName: json['author_name'] as String? ?? '',
      authorAvatarUrl: json['author_avatar_url'] as String?,
      isLikedByMe: json['is_liked_by_me'] as bool? ?? false,
    );
  }

  final Comment comment;
  final String authorName;
  final String? authorAvatarUrl;
  final bool isLikedByMe;

  @override
  List<Object?> get props => [comment, isLikedByMe];
}
