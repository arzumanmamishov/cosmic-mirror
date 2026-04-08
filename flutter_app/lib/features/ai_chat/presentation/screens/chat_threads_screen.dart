import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../providers/chat_provider.dart';

class ChatThreadsScreen extends ConsumerWidget {
  const ChatThreadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(chatThreadsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Astrologer')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final threadId =
              await ref.read(chatInputProvider.notifier).createThread();
          if (threadId != null && context.mounted) {
            context.push('/chat/$threadId');
          }
        },
        backgroundColor: CosmicColors.primary,
        child: const Icon(Icons.add),
      ),
      body: threadsAsync.when(
        loading: () => const ShimmerList(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(chatThreadsProvider),
        ),
        data: (threads) {
          if (threads.isEmpty) {
            return EmptyState(
              title: 'No conversations yet',
              subtitle: 'Start a conversation with your AI astrologer',
              icon: Icons.chat_bubble_outline,
              actionLabel: 'Start Chat',
              onAction: () async {
                final threadId =
                    await ref.read(chatInputProvider.notifier).createThread();
                if (threadId != null && context.mounted) {
                  context.push('/chat/$threadId');
                }
              },
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: threads.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final thread = threads[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: CosmicColors.glassBorder),
                ),
                tileColor: CosmicColors.surface,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: CosmicColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: CosmicColors.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  thread.title ?? 'New Conversation',
                  style: CosmicTypography.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  thread.lastMessage ?? 'Tap to continue',
                  style: CosmicTypography.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  CosmicDateUtils.timeAgo(
                    thread.updatedAt ?? thread.createdAt,
                  ),
                  style: CosmicTypography.caption,
                ),
                onTap: () => context.push('/chat/${thread.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
