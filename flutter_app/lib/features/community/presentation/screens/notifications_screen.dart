import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/community/domain/entities/notification.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/notification_tile.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final notifsAsync = ref.watch(notificationsProvider);
    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: Text(AppLocalizations.of(context).communityNotifications),
        actions: [
          TextButton(
            onPressed: () async {
              await ref
                  .read(communityRepositoryProvider)
                  .markAllNotificationsRead();
              ref
                ..invalidate(notificationsProvider)
                ..invalidate(unreadCountProvider);
            },
            child: Text(
              AppLocalizations.of(context).communityMarkAllRead,
              style: TextStyle(
                color: p.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CosmicStarfield(
              color: p.textPrimary,
              starCount: 50,
              intensity: 0.6,
            ),
          ),
          notifsAsync.when(
            loading: () => const ShimmerList(itemCount: 6),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () => ref.invalidate(notificationsProvider),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      AppLocalizations.of(context).notifEmptyBlurb,
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: p.textSecondary, fontSize: 13),
                    ),
                  ),
                );
              }
              final groups = _groupByDay(AppLocalizations.of(context), entries);
              return RefreshIndicator(
                onRefresh: () async {
                  ref
                    ..invalidate(notificationsProvider)
                    ..invalidate(unreadCountProvider);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 100, 20, 32),
                  children: [
                    for (final entry in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            color: p.textSecondary,
                            fontSize: 11,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      for (final n in entry.value) ...[
                        NotificationTile(
                          entry: n,
                          onTap: () => _handleTap(context, ref, n),
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    NotificationWithMeta entry,
  ) async {
    final n = entry.notification;
    if (n.isUnread) {
      await ref.read(communityRepositoryProvider).markNotificationRead(n.id);
      ref
        ..invalidate(notificationsProvider)
        ..invalidate(unreadCountProvider);
    }
    if (!context.mounted) return;
    switch (n.targetType) {
      case 'space':
        context.push('/community/${n.targetId}');
      case 'post':
        // We don't know the spaceId from a notification — push the post
        // route and let it self-resolve from the post object.
        context.push('/community/post/${n.targetId}');
      case 'comment':
        // For now route to the actor's profile since we don't have a
        // direct comment-deep-link route.
        if (n.actorId != null) {
          context.push('/community/user/${n.actorId}');
        }
    }
  }

  Map<String, List<NotificationWithMeta>> _groupByDay(
    AppLocalizations l,
    List<NotificationWithMeta> entries,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final out = <String, List<NotificationWithMeta>>{};
    for (final e in entries) {
      final d = e.notification.createdAt;
      final dayStart = DateTime(d.year, d.month, d.day);
      String label;
      if (dayStart == today) {
        label = l.notifGroupToday;
      } else if (dayStart == yesterday) {
        label = l.notifGroupYesterday;
      } else if (today.difference(dayStart).inDays < 7) {
        label = l.notifGroupThisWeek;
      } else {
        label = l.notifGroupEarlier;
      }
      out.putIfAbsent(label, () => []).add(e);
    }
    return out;
  }
}
