import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/widgets/cosmic_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_shimmer.dart';

final savedPeopleProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(apiClientProvider);
  final data = await client.get<Map<String, dynamic>>(ApiEndpoints.people);
  return (data['people'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
});

class CompatibilityScreen extends ConsumerWidget {
  const CompatibilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peopleAsync = ref.watch(savedPeopleProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Compatibility')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/compatibility/add'),
        backgroundColor: CosmicColors.primary,
        child: const Icon(Icons.person_add),
      ),
      body: peopleAsync.when(
        loading: () => const ShimmerList(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(savedPeopleProvider),
        ),
        data: (people) {
          if (people.isEmpty) {
            return EmptyState(
              title: 'No people added yet',
              subtitle: 'Add someone to discover your cosmic compatibility',
              icon: Icons.people_outline,
              actionLabel: 'Add Person',
              onAction: () => context.push('/compatibility/add'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: people.length,
            itemBuilder: (context, index) {
              final person = people[index];
              final name = person['name'] as String;
              final score = person['compatibility_score'] as int?;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CosmicCard(
                  onTap: () =>
                      context.push('/compatibility/${person['id']}'),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: CosmicColors.accent.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            name[0].toUpperCase(),
                            style: CosmicTypography.headlineMedium.copyWith(
                              color: CosmicColors.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: CosmicTypography.titleMedium),
                            if (score != null)
                              Text('$score% compatibility',
                                  style: CosmicTypography.bodySmall),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: CosmicColors.textSecondary),
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
