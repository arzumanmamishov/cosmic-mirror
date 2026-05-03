import 'package:cosmic_mirror/core/network/api_client.dart';
import 'package:cosmic_mirror/core/network/api_endpoints.dart';
import 'package:cosmic_mirror/features/vedic_chart/domain/entities/dasha.dart';
import 'package:cosmic_mirror/features/vedic_chart/domain/entities/vedic_chart.dart';
import 'package:cosmic_mirror/features/vedic_chart/domain/entities/yoga.dart';

/// User-selectable ayanamsa. Backend default is Lahiri.
enum Ayanamsa {
  lahiri('lahiri', 'Lahiri'),
  raman('raman', 'Raman'),
  krishnamurti('krishnamurti', 'Krishnamurti'),
  faganBradley('fagan-bradley', 'Fagan-Bradley');

  const Ayanamsa(this.queryValue, this.label);
  final String queryValue;
  final String label;
}

/// All Vedic API access goes through this repository so the screen / providers
/// stay decoupled from Dio specifics.
class VedicRepository {
  VedicRepository(this._client);

  final ApiClient _client;

  Future<VedicChart> fetchRasi(Ayanamsa ayanamsa) async {
    return _client.get<VedicChart>(
      ApiEndpoints.vedicChart,
      queryParameters: {'ayanamsa': ayanamsa.queryValue},
      fromJson: (raw) => VedicChart.fromJson(raw as Map<String, dynamic>),
    );
  }

  Future<VedicChart> fetchDivisional(Ayanamsa ayanamsa, int divisor) async {
    return _client.get<VedicChart>(
      ApiEndpoints.vedicDivisional(divisor),
      queryParameters: {'ayanamsa': ayanamsa.queryValue},
      fromJson: (raw) => VedicChart.fromJson(raw as Map<String, dynamic>),
    );
  }

  Future<DashaTree> fetchDasha(Ayanamsa ayanamsa, {int levels = 3}) async {
    return _client.get<DashaTree>(
      ApiEndpoints.vedicDasha,
      queryParameters: {
        'ayanamsa': ayanamsa.queryValue,
        'levels': '$levels',
      },
      fromJson: (raw) => DashaTree.fromJson(raw as Map<String, dynamic>),
    );
  }

  Future<List<VedicYoga>> fetchYogas(Ayanamsa ayanamsa) async {
    return _client.get<List<VedicYoga>>(
      ApiEndpoints.vedicYogas,
      queryParameters: {'ayanamsa': ayanamsa.queryValue},
      fromJson: (raw) {
        final map = raw as Map<String, dynamic>;
        final list = (map['yogas'] as List<dynamic>?) ?? const [];
        return list
            .map((e) => VedicYoga.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<Map<String, ShadbalaBreakdown>> fetchShadbala(
    Ayanamsa ayanamsa,
  ) async {
    return _client.get<Map<String, ShadbalaBreakdown>>(
      ApiEndpoints.vedicShadbala,
      queryParameters: {'ayanamsa': ayanamsa.queryValue},
      fromJson: (raw) {
        final map = raw as Map<String, dynamic>;
        final inner = (map['shadbala'] as Map<String, dynamic>?) ?? const {};
        return inner.map(
          (k, v) => MapEntry(
            k,
            ShadbalaBreakdown.fromJson(v as Map<String, dynamic>),
          ),
        );
      },
    );
  }

  Future<Ashtakavarga> fetchAshtakavarga(Ayanamsa ayanamsa) async {
    return _client.get<Ashtakavarga>(
      ApiEndpoints.vedicAshtakavarga,
      queryParameters: {'ayanamsa': ayanamsa.queryValue},
      fromJson: (raw) => Ashtakavarga.fromJson(raw as Map<String, dynamic>),
    );
  }
}
