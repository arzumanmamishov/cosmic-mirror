import 'package:cosmic_mirror/features/destiny_matrix/data/repositories/destiny_matrix_repository.dart';
import 'package:cosmic_mirror/features/destiny_matrix/domain/entities/destiny_matrix.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final destinyMatrixRepositoryProvider = Provider<DestinyMatrixRepository>(
  (ref) => DestinyMatrixRepository(ref.read(apiClientProvider)),
);

/// Full Matrix of Destiny (22-arcana octagram) reading. AutoDispose so it
/// re-fetches when the user navigates back into the screen.
final destinyMatrixReadingProvider =
    FutureProvider.autoDispose<DestinyMatrixReading>((ref) async {
  return ref.read(destinyMatrixRepositoryProvider).getReading();
});
