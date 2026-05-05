import 'package:cosmic_mirror/core/network/api_endpoints.dart';
import 'package:cosmic_mirror/features/onboarding/data/models/birth_profile_model.dart';
import 'package:cosmic_mirror/features/onboarding/domain/entities/birth_profile.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads the user's stored birth profile so the profile screen can render
/// real birth date / time / place rather than placeholder dashes. Refresh
/// after onboarding edits by invalidating this provider.
final birthProfileProvider =
    FutureProvider.autoDispose<BirthProfile?>((ref) async {
  final client = ref.read(apiClientProvider);
  try {
    final data = await client.get<Map<String, dynamic>>(
      ApiEndpoints.birthProfile,
    );
    return BirthProfileModel.fromJson(data);
  } catch (_) {
    // 404 (no profile yet) or any error → render the empty state.
    return null;
  }
});

/// Engagement snapshot for the profile stats row.
class UserStats {
  const UserStats({
    required this.streak,
    required this.journalEntries,
    required this.aiChats,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      journalEntries: (json['journal_entries'] as num?)?.toInt() ?? 0,
      aiChats: (json['ai_chats'] as num?)?.toInt() ?? 0,
    );
  }

  final int streak;
  final int journalEntries;
  final int aiChats;
}

/// Loads the profile stats. Auto-disposed so the next visit fetches a
/// fresh snapshot.
final userStatsProvider = FutureProvider.autoDispose<UserStats>((ref) async {
  final client = ref.read(apiClientProvider);
  final data = await client.get<Map<String, dynamic>>(ApiEndpoints.userStats);
  return UserStats.fromJson(data);
});
