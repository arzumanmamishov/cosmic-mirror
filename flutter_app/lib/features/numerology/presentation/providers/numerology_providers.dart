import 'package:cosmic_mirror/features/numerology/data/repositories/numerology_repository.dart';
import 'package:cosmic_mirror/features/numerology/domain/entities/numerology.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final numerologyRepositoryProvider = Provider<NumerologyRepository>(
  (ref) => NumerologyRepository(ref.read(apiClientProvider)),
);

/// Full numerology reading (profile + cycles). AutoDispose so it re-fetches
/// when the user navigates back into the screen.
final numerologyReadingProvider =
    FutureProvider.autoDispose<NumerologyReading>((ref) async {
  return ref.read(numerologyRepositoryProvider).getReading();
});
