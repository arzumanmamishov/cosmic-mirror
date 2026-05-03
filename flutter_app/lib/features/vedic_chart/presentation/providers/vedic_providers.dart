import 'package:cosmic_mirror/features/vedic_chart/data/repositories/vedic_repository.dart';
import 'package:cosmic_mirror/features/vedic_chart/domain/entities/dasha.dart';
import 'package:cosmic_mirror/features/vedic_chart/domain/entities/vedic_chart.dart';
import 'package:cosmic_mirror/features/vedic_chart/domain/entities/yoga.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Globally selected ayanamsa. Default Lahiri (modern Vedic standard).
/// Changing this invalidates every Vedic data provider via family keying.
final selectedAyanamsaProvider = StateProvider<Ayanamsa>(
  (ref) => Ayanamsa.lahiri,
);

/// Repository singleton. Keeps the API client wiring out of provider
/// definitions and allows easy stubbing in tests.
final vedicRepositoryProvider = Provider<VedicRepository>(
  (ref) => VedicRepository(ref.read(apiClientProvider)),
);

/// Rasi (D1) chart for the currently selected ayanamsa.
final vedicRasiProvider = FutureProvider.autoDispose<VedicChart>((ref) async {
  final ayanamsa = ref.watch(selectedAyanamsaProvider);
  return ref.read(vedicRepositoryProvider).fetchRasi(ayanamsa);
});

/// Divisional chart for a specific divisor (D2..D60). Family-keyed by divisor
/// so different vargas can be cached independently for the same ayanamsa.
final vedicDivisionalProvider =
    FutureProvider.autoDispose.family<VedicChart, int>((ref, divisor) async {
  final ayanamsa = ref.watch(selectedAyanamsaProvider);
  return ref.read(vedicRepositoryProvider).fetchDivisional(ayanamsa, divisor);
});

/// Currently selected varga in the UI (defaults to Rasi/D1).
final selectedVargaProvider = StateProvider<int>((ref) => 1);

/// Returns whichever chart corresponds to [selectedVargaProvider]: D1 from
/// [vedicRasiProvider], otherwise the matching divisional family.
final activeChartProvider = FutureProvider.autoDispose<VedicChart>((ref) async {
  final divisor = ref.watch(selectedVargaProvider);
  if (divisor == 1) {
    return ref.watch(vedicRasiProvider.future);
  }
  return ref.watch(vedicDivisionalProvider(divisor).future);
});

/// Vimshottari Dasha tree (3 levels by default).
final vedicDashaProvider = FutureProvider.autoDispose<DashaTree>((ref) async {
  final ayanamsa = ref.watch(selectedAyanamsaProvider);
  return ref.read(vedicRepositoryProvider).fetchDasha(ayanamsa);
});

/// Active classical yogas.
final vedicYogasProvider =
    FutureProvider.autoDispose<List<VedicYoga>>((ref) async {
  final ayanamsa = ref.watch(selectedAyanamsaProvider);
  return ref.read(vedicRepositoryProvider).fetchYogas(ayanamsa);
});

/// Six-fold strength per planet.
final vedicShadbalaProvider =
    FutureProvider.autoDispose<Map<String, ShadbalaBreakdown>>((ref) async {
  final ayanamsa = ref.watch(selectedAyanamsaProvider);
  return ref.read(vedicRepositoryProvider).fetchShadbala(ayanamsa);
});

/// Sarva + Bhinn Ashtakavarga.
final vedicAshtakavargaProvider =
    FutureProvider.autoDispose<Ashtakavarga>((ref) async {
  final ayanamsa = ref.watch(selectedAyanamsaProvider);
  return ref.read(vedicRepositoryProvider).fetchAshtakavarga(ayanamsa);
});
