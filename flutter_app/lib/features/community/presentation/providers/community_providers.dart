import 'package:cosmic_mirror/features/community/data/repositories/community_repository.dart';
import 'package:cosmic_mirror/features/community/domain/entities/notification.dart';
import 'package:cosmic_mirror/features/community/domain/entities/post.dart';
import 'package:cosmic_mirror/features/community/domain/entities/space.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => CommunityRepository(ref.read(apiClientProvider)),
);

/// Currently selected filter on the spaces list (All vs Joined).
final spaceFilterProvider = StateProvider<SpaceFilter>(
  (ref) => SpaceFilter.all,
);

/// Currently typed search query on the spaces list.
final spaceSearchQueryProvider = StateProvider<String>((ref) => '');

/// Currently selected category id on the spaces list (null = no filter).
final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);

/// Spaces list — keys off all three filter states so changing any rebuilds it.
final spacesProvider =
    FutureProvider.autoDispose<List<SpaceWithMeta>>((ref) async {
  final repo = ref.read(communityRepositoryProvider);
  return repo.listSpaces(
    filter: ref.watch(spaceFilterProvider),
    categoryId: ref.watch(selectedCategoryIdProvider),
    query: ref.watch(spaceSearchQueryProvider),
  );
});

/// Single space detail — family by spaceId.
final spaceDetailProvider =
    FutureProvider.autoDispose.family<SpaceWithMeta, String>((ref, id) async {
  return ref.read(communityRepositoryProvider).getSpace(id);
});

/// Posts feed for a space.
final spacePostsProvider = FutureProvider.autoDispose
    .family<List<PostWithMeta>, String>((ref, spaceId) async {
  return ref.read(communityRepositoryProvider).listPostsBySpace(spaceId);
});

/// Single post detail.
final postDetailProvider =
    FutureProvider.autoDispose.family<PostWithMeta, String>((ref, id) async {
  return ref.read(communityRepositoryProvider).getPost(id);
});

/// Comments for a post.
final commentsProvider = FutureProvider.autoDispose
    .family<List<CommentWithMeta>, String>((ref, postId) async {
  return ref.read(communityRepositoryProvider).listComments(postId);
});

/// Members of a space.
final spaceMembersProvider = FutureProvider.autoDispose
    .family<List<SpaceMember>, String>((ref, spaceId) async {
  return ref.read(communityRepositoryProvider).listMembers(spaceId);
});

/// Activity feed.
final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationWithMeta>>((ref) async {
  return ref.read(communityRepositoryProvider).listNotifications();
});

/// Lightweight unread counter for the bell badge. Polled by the bell widget;
/// invalidated whenever a notification is marked read.
final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  return ref.read(communityRepositoryProvider).unreadCount();
});

/// Categories (seeded — rarely changes, cache for the lifetime of the app).
final categoriesProvider = FutureProvider<List<SpaceCategory>>((ref) async {
  return ref.read(communityRepositoryProvider).listCategories();
});

/// Trending hashtags.
final popularHashtagsProvider =
    FutureProvider.autoDispose<List<Hashtag>>((ref) async {
  return ref.read(communityRepositoryProvider).popularHashtags();
});
