import 'package:cosmic_mirror/core/network/api_endpoints.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Today's ritual state: which ritual types are completed, and the current
/// streak. Keyed by the backend ritual_type
/// (morning_intention / affirmation / evening_reflection).
class RitualsToday {
  const RitualsToday({required this.completedByType, required this.streak});

  final Map<String, bool> completedByType;
  final int streak;

  bool isCompleted(String type) => completedByType[type] ?? false;
}

/// Fetches today's rituals + streak from the backend.
final ritualsTodayProvider =
    FutureProvider.autoDispose<RitualsToday>((ref) async {
  final client = ref.read(apiClientProvider);
  final data = await client.get<Map<String, dynamic>>(ApiEndpoints.ritualsToday);
  final list = data['rituals'] as List<dynamic>? ?? const [];
  final completed = <String, bool>{};
  for (final raw in list) {
    final m = raw as Map<String, dynamic>;
    final type = m['type'] as String? ?? '';
    if (type.isNotEmpty) {
      completed[type] = m['completed'] as bool? ?? false;
    }
  }
  return RitualsToday(
    completedByType: completed,
    streak: (data['streak'] as num?)?.toInt() ?? 0,
  );
});

/// Marks a ritual complete on the backend, then refreshes today's state.
Future<void> completeRitual(WidgetRef ref, String type) async {
  final client = ref.read(apiClientProvider);
  await client.post<dynamic>(ApiEndpoints.ritualComplete(type));
  ref.invalidate(ritualsTodayProvider);
}
