import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/core/utils/date_utils.dart';
import 'package:cosmic_mirror/features/ai_chat/domain/entities/chat_entities.dart';
import 'package:cosmic_mirror/features/ai_chat/presentation/providers/chat_provider.dart';
import 'package:cosmic_mirror/features/ai_chat/presentation/widgets/cosmic_memory_panel.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_pulse.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:cosmic_mirror/shared/widgets/staggered_fade_in.dart';

class ChatThreadsScreen extends ConsumerWidget {
  const ChatThreadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(chatThreadsProvider);
    final p = context.palette;

    Future<void> startNew() async {
      final threadId =
          await ref.read(chatInputProvider.notifier).createThread();
      if (threadId != null && context.mounted) {
        context.push('/chat/$threadId');
      }
    }

    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('Astrologer'),
      ),
      floatingActionButton: CosmicPulse(
        color: p.primary,
        maxRadius: 40,
        child: FloatingActionButton.extended(
          onPressed: startNew,
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
          label: const Text(
            'New Chat',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          extendedPadding: EdgeInsets.zero,
          shape: const StadiumBorder(),
        ).withGradient(p.primaryGradient),
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
          threadsAsync.when(
            loading: () => const ShimmerList(),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(chatThreadsProvider),
            ),
            data: (threads) {
              if (threads.isEmpty) {
                return _EmptyState(onStart: startNew);
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 100),
                itemCount: threads.length + 2,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return FadeSlideIn(
                      child: _Header(threadCount: threads.length),
                    );
                  }
                  if (i == 1) {
                    return const FadeSlideIn(
                      delay: Duration(milliseconds: 80),
                      child: CosmicMemoryPanel(),
                    );
                  }
                  final t = threads[i - 2];
                  return FadeSlideIn(
                    delay: Duration(milliseconds: 120 + i * 40),
                    child: _ThreadCard(
                      thread: t,
                      onOpen: () => context.push('/chat/${t.id}'),
                      onDelete: () async {
                        final confirmed =
                            await _confirmDelete(context, t.title);
                        if (!confirmed) return;
                        final ok = await ref
                            .read(chatInputProvider.notifier)
                            .deleteThread(t.id);
                        if (ok) {
                          ref.invalidate(chatThreadsProvider);
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not delete conversation'),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String? title) async {
    final p = context.palette;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete conversation?',
          style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '"${title ?? 'New Conversation'}" and all its messages will be removed. This cannot be undone.',
          style: TextStyle(color: p.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: p.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: p.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.threadCount});
  final int threadCount;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cosmic Conversations',
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$threadCount conversation${threadCount == 1 ? '' : 's'} · powered by your chart',
            style: TextStyle(color: p.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ThreadCard extends StatelessWidget {
  const _ThreadCard({
    required this.thread,
    required this.onOpen,
    required this.onDelete,
  });

  final ChatThread thread;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Dismissible(
      key: ValueKey(thread.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: p.error.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.error.withValues(alpha: 0.4)),
        ),
        child: Icon(Icons.delete_outline_rounded, color: p.error, size: 26),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // we control invalidation ourselves
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: p.glassBorder),
            ),
            child: Row(
              children: [
                // Gradient orb avatar
                Container(
                  width: 46,
                  height: 46,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: p.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: p.surface,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: p.primary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              thread.title ?? 'New Conversation',
                              style: TextStyle(
                                color: p.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            CosmicDateUtils.timeAgo(
                              thread.updatedAt ?? thread.createdAt,
                            ),
                            style: TextStyle(
                              color: p.textTertiary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        thread.lastMessage ?? 'Tap to continue your reading',
                        style: TextStyle(
                          color: p.textSecondary,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  splashRadius: 20,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: p.textTertiary,
                    size: 20,
                  ),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CosmicPulse(
              color: p.primary,
              maxRadius: 80,
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: p.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: p.primary.withValues(alpha: 0.4),
                      blurRadius: 24,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Begin a Cosmic Dialogue',
              style: TextStyle(
                color: p.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask anything about your chart, transits,\nor a moment you want to understand.',
              style: TextStyle(
                color: p.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Start a Conversation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: p.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper to layer a gradient behind a [FloatingActionButton.extended] without
/// rebuilding the whole widget. The FAB is set to transparent, and we wrap it
/// with a gradient container of the same shape.
extension _GradientFab on FloatingActionButton {
  Widget withGradient(Gradient gradient) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        gradient: gradient,
        shape: const StadiumBorder(),
      ),
      child: this,
    );
  }
}
