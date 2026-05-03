import 'package:cosmic_mirror/core/network/api_client.dart';
import 'package:cosmic_mirror/core/network/api_endpoints.dart';
import 'package:cosmic_mirror/features/community/domain/entities/notification.dart';
import 'package:cosmic_mirror/features/community/domain/entities/post.dart';
import 'package:cosmic_mirror/features/community/domain/entities/space.dart';

/// Spaces filter mode for the list endpoint.
enum SpaceFilter {
  all('all'),
  joined('joined');

  const SpaceFilter(this.queryValue);
  final String queryValue;
}

/// Single repository for the entire Community feature. Centralizes the
/// URL→entity mapping so screens don't deal with raw `Map<String, dynamic>`.
class CommunityRepository {
  CommunityRepository(this._client);

  final ApiClient _client;

  // ===== Spaces =====

  Future<List<SpaceWithMeta>> listSpaces({
    SpaceFilter filter = SpaceFilter.all,
    String? categoryId,
    String? query,
    int limit = 20,
    int offset = 0,
  }) async {
    return _client.get<List<SpaceWithMeta>>(
      ApiEndpoints.spaces,
      queryParameters: {
        'filter': filter.queryValue,
        if (categoryId != null) 'category': categoryId,
        if (query != null && query.isNotEmpty) 'q': query,
        'limit': '$limit',
        'offset': '$offset',
      },
      fromJson: (raw) {
        final list = (raw as Map<String, dynamic>)['spaces'] as List<dynamic>?;
        return (list ?? const [])
            .map((e) => SpaceWithMeta.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<SpaceWithMeta> getSpace(String spaceId) async {
    return _client.get<SpaceWithMeta>(
      ApiEndpoints.space(spaceId),
      fromJson: (raw) => SpaceWithMeta.fromJson(raw as Map<String, dynamic>),
    );
  }

  Future<Space> createSpace({
    required String handle,
    required String name,
    String? description,
    String? categoryId,
    bool isSpicy = false,
  }) async {
    return _client.post<Space>(
      ApiEndpoints.spaces,
      data: {
        'handle': handle,
        'name': name,
        if (description != null) 'description': description,
        if (categoryId != null) 'category_id': categoryId,
        'is_spicy': isSpicy,
      },
      fromJson: (raw) => Space.fromJson(raw as Map<String, dynamic>),
    );
  }

  Future<void> updateSpace(
    String spaceId, {
    String? name,
    String? description,
    String? categoryId,
    bool? isSpicy,
  }) async {
    await _client.put<dynamic>(
      ApiEndpoints.space(spaceId),
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (categoryId != null) 'category_id': categoryId,
        if (isSpicy != null) 'is_spicy': isSpicy,
      },
    );
  }

  Future<void> deleteSpace(String spaceId) async {
    await _client.delete(ApiEndpoints.space(spaceId));
  }

  Future<void> joinSpace(String spaceId) async {
    await _client.post<dynamic>(ApiEndpoints.spaceJoin(spaceId));
  }

  Future<void> leaveSpace(String spaceId) async {
    await _client.delete(ApiEndpoints.spaceJoin(spaceId));
  }

  Future<List<SpaceMember>> listMembers(
    String spaceId, {
    int limit = 50,
    int offset = 0,
  }) async {
    return _client.get<List<SpaceMember>>(
      ApiEndpoints.spaceMembers(spaceId),
      queryParameters: {'limit': '$limit', 'offset': '$offset'},
      fromJson: (raw) {
        final list = (raw as Map<String, dynamic>)['members'] as List<dynamic>?;
        return (list ?? const [])
            .map((e) => SpaceMember.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  // ===== Posts =====

  Future<List<PostWithMeta>> listPostsBySpace(
    String spaceId, {
    int limit = 20,
    int offset = 0,
  }) async {
    return _client.get<List<PostWithMeta>>(
      ApiEndpoints.spacePosts(spaceId),
      queryParameters: {'limit': '$limit', 'offset': '$offset'},
      fromJson: (raw) {
        final list = (raw as Map<String, dynamic>)['posts'] as List<dynamic>?;
        return (list ?? const [])
            .map((e) => PostWithMeta.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<PostWithMeta> getPost(String postId) async {
    return _client.get<PostWithMeta>(
      ApiEndpoints.post(postId),
      fromJson: (raw) => PostWithMeta.fromJson(raw as Map<String, dynamic>),
    );
  }

  Future<Post> createPost({
    required String spaceId,
    required String content,
    String? linkUrl,
  }) async {
    return _client.post<Post>(
      ApiEndpoints.spacePosts(spaceId),
      data: {
        'content': content,
        if (linkUrl != null && linkUrl.isNotEmpty) 'link_url': linkUrl,
      },
      fromJson: (raw) => Post.fromJson(raw as Map<String, dynamic>),
    );
  }

  Future<void> updatePost(
    String postId, {
    String? content,
    String? linkUrl,
  }) async {
    await _client.put<dynamic>(
      ApiEndpoints.post(postId),
      data: {
        if (content != null) 'content': content,
        if (linkUrl != null) 'link_url': linkUrl,
      },
    );
  }

  Future<void> deletePost(String postId) async {
    await _client.delete(ApiEndpoints.post(postId));
  }

  Future<void> setPostLiked(String postId, {required bool liked}) async {
    if (liked) {
      await _client.post<dynamic>(ApiEndpoints.postLike(postId));
    } else {
      await _client.delete(ApiEndpoints.postLike(postId));
    }
  }

  // ===== Comments =====

  Future<List<CommentWithMeta>> listComments(String postId) async {
    return _client.get<List<CommentWithMeta>>(
      ApiEndpoints.postComments(postId),
      fromJson: (raw) {
        final list = (raw as Map<String, dynamic>)['comments'] as List<dynamic>?;
        return (list ?? const [])
            .map((e) => CommentWithMeta.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<Comment> createComment({
    required String postId,
    required String content,
    String? parentCommentId,
  }) async {
    return _client.post<Comment>(
      ApiEndpoints.postComments(postId),
      data: {
        'content': content,
        if (parentCommentId != null) 'parent_comment_id': parentCommentId,
      },
      fromJson: (raw) => Comment.fromJson(raw as Map<String, dynamic>),
    );
  }

  Future<void> updateComment(String commentId, String content) async {
    await _client.put<dynamic>(
      ApiEndpoints.comment(commentId),
      data: {'content': content},
    );
  }

  Future<void> deleteComment(String commentId) async {
    await _client.delete(ApiEndpoints.comment(commentId));
  }

  Future<void> setCommentLiked(String commentId, {required bool liked}) async {
    if (liked) {
      await _client.post<dynamic>(ApiEndpoints.commentLike(commentId));
    } else {
      await _client.delete(ApiEndpoints.commentLike(commentId));
    }
  }

  // ===== Notifications =====

  Future<List<NotificationWithMeta>> listNotifications({
    bool unreadOnly = false,
    int limit = 30,
    int offset = 0,
  }) async {
    return _client.get<List<NotificationWithMeta>>(
      ApiEndpoints.communityNotifications,
      queryParameters: {
        if (unreadOnly) 'unread': 'true',
        'limit': '$limit',
        'offset': '$offset',
      },
      fromJson: (raw) {
        final list = (raw as Map<String, dynamic>)['notifications']
            as List<dynamic>?;
        return (list ?? const [])
            .map((e) => NotificationWithMeta.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<int> unreadCount() async {
    return _client.get<int>(
      ApiEndpoints.communityNotificationsUnreadCount,
      fromJson: (raw) =>
          ((raw as Map<String, dynamic>)['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> markNotificationRead(String id) async {
    await _client.post<dynamic>(ApiEndpoints.communityNotificationRead(id));
  }

  Future<void> markAllNotificationsRead() async {
    await _client.post<dynamic>(ApiEndpoints.communityNotificationsReadAll);
  }

  // ===== Discovery =====

  Future<List<SpaceCategory>> listCategories() async {
    return _client.get<List<SpaceCategory>>(
      ApiEndpoints.spaceCategories,
      fromJson: (raw) {
        final list =
            (raw as Map<String, dynamic>)['categories'] as List<dynamic>?;
        return (list ?? const [])
            .map((e) => SpaceCategory.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<List<Hashtag>> popularHashtags({int limit = 20}) async {
    return _client.get<List<Hashtag>>(
      ApiEndpoints.popularHashtags,
      queryParameters: {'limit': '$limit'},
      fromJson: (raw) {
        final list =
            (raw as Map<String, dynamic>)['hashtags'] as List<dynamic>?;
        return (list ?? const [])
            .map((e) => Hashtag.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }
}
