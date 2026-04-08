import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/widgets/cosmic_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_shimmer.dart';

final journalEntriesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(apiClientProvider);
  final data = await client.get<Map<String, dynamic>>(ApiEndpoints.journal);
  return (data['entries'] as List<dynamic>).cast<Map<String, dynamic>>();
});

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(journalEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Journal')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/journal/new'),
        backgroundColor: CosmicColors.primary,
        child: const Icon(Icons.edit_outlined),
      ),
      body: entriesAsync.when(
        loading: () => const ShimmerList(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(journalEntriesProvider),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return EmptyState(
              title: 'Your journal is empty',
              subtitle: 'Start writing to capture your cosmic reflections',
              icon: Icons.book_outlined,
              actionLabel: 'Write Entry',
              onAction: () => context.push('/journal/new'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final date = DateTime.tryParse(
                entry['entry_date'] as String? ?? '',
              );
              final content = entry['content'] as String? ?? '';
              final mood = entry['mood'] as String?;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CosmicCard(
                  onTap: () => context.push('/journal/${entry['id']}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (date != null)
                            Text(
                              CosmicDateUtils.formatFull(date),
                              style: CosmicTypography.caption,
                            ),
                          const Spacer(),
                          if (mood != null)
                            Text(mood, style: const TextStyle(fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        content,
                        style: CosmicTypography.bodyMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
