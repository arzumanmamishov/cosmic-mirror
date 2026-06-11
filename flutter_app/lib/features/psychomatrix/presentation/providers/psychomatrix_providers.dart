import 'package:cosmic_mirror/features/psychomatrix/data/repositories/psychomatrix_repository.dart';
import 'package:cosmic_mirror/features/psychomatrix/domain/entities/psychomatrix.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final psychomatrixRepositoryProvider = Provider<PsychomatrixRepository>(
  (ref) => PsychomatrixRepository(ref.read(apiClientProvider)),
);

/// Full Pythagoras Square (psychomatrix) reading. AutoDispose so it
/// re-fetches when the user navigates back into the screen.
final psychomatrixReadingProvider =
    FutureProvider.autoDispose<PsychomatrixReading>((ref) async {
  return ref.read(psychomatrixRepositoryProvider).getReading();
});
