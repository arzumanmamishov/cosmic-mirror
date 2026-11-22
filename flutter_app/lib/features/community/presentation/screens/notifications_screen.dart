import 'dart:async';

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/core/error/error_message.dart';
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

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _markingAll = false;

  Future<void> _markAllRead() async {
    if (_markingAll) return;
    setState(() => _markingAll = true);
    try {
      await ref.read(communityRepositoryProvider).markAllNotificationsRead();
      ref
        ..invalidate(notificationsProvider)
        ..invalidate(unreadCountProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(FriendlyError.from(context, e).body)),
        );
      }
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(unreadCountProvider);
    try {
      ref.invalidate(notificationsProvider);
      await ref.read(notificationsProvider.future);
    } catch (_) {/* shown by the provider's error state */}
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final notifsAsync = ref.watch(notificationsProvider);
    final hasUnread = notifsAsync.valueOrNull
            ?.any((n) => n.notification.isUnread) ??
        false;
    // The app bar is transparent over the body; keep content below it.
    final topPad = MediaQuery.paddingOf(context).top + kToolbarHeight + 12;
    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: Text(l.communityNotifications),
        actions: [
          TextButton(
            // Disabled while in flight or when everything is already read.
            onPressed: _markingAll || !hasUnread ? null : _markAllRead,
            child: Text(
              l.communityMarkAllRead,
              style: TextStyle(
                color: _markingAll || !hasUnread ? p.textDim : p.primary,
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
                // Still pull-to-refreshable so new activity can be fetched.
                return RefreshIndicator(
                  color: p.primary,
                  backgroundColor: p.surface,
                  edgeOffset: topPad,
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(32, topPad + 80, 32, 32),
                    children: [
                      Text(
                        l.notifEmptyBlurb,
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: p.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }
              final groups = _groupByDay(l, entries);
              return RefreshIndicator(
                color: p.primary,
                backgroundColor: p.surface,
                edgeOffset: topPad,
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(20, topPad, 20, 32),
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
      // Navigate right away; a failed mark-read must not block (or
      // silently swallow) the tap.
      unawaited(
        ref
            .read(communityRepositoryProvider)
            .markNotificationRead(n.id)
            .then((_) {
          if (!mounted) return;
          ref
            ..invalidate(notificationsProvider)
            ..invalidate(unreadCountProvider);
        }).catchError((Object _) {}),
      );
    }
    if (!context.mounted) return;
    switch (n.targetType) {
      case 'space':
        // A "requested to join your space" notification is for the
        // owner — route them straight to the manage-requests screen
        // instead of the space, since the space is something they can
        // already open from any list and the actionable item here is
        // the request itself.
        if (n.type == 'space_join_requested') {
          unawaited(context.push('/community/${n.targetId}/requests'));
        } else {
          unawaited(context.push('/community/${n.targetId}'));
        }
      case 'post':
        // We don't know the spaceId from a notification — push the post
        // route and let it self-resolve from the post object.
        unawaited(context.push('/community/post/${n.targetId}'));
      case 'comment':
        // For now route to the actor's profile since we don't have a
        // direct comment-deep-link route.
        if (n.actorId != null) {
          unawaited(context.push('/community/user/${n.actorId}'));
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
