import 'package:cosmic_mirror/core/network/api_client.dart';
import 'package:cosmic_mirror/core/network/api_endpoints.dart';
import 'package:cosmic_mirror/features/numerology/domain/entities/numerology.dart';

class NumerologyRepository {
  NumerologyRepository(this._client);
  final ApiClient _client;

  Future<NumerologyReading> getReading() async {
    return _client.get<NumerologyReading>(
      ApiEndpoints.numerology,
      fromJson: (raw) =>
          NumerologyReading.fromJson(raw as Map<String, dynamic>),
    );
  }

  /// Standalone Name Numerology Calculator — analyze any name without
  /// touching the user's stored birth profile.
  Future<NumerologyNameAnalysis> analyzeName(String name) async {
    return _client.post<NumerologyNameAnalysis>(
      ApiEndpoints.numerologyName,
      data: {'name': name},
      fromJson: (raw) =>
          NumerologyNameAnalysis.fromJson(raw as Map<String, dynamic>),
    );
  }

  Future<NumerologyCompatibility> compareWith({
    required String fullName,
    required DateTime birthDate,
  }) async {
    final iso = '${birthDate.year.toString().padLeft(4, '0')}-'
        '${birthDate.month.toString().padLeft(2, '0')}-'
        '${birthDate.day.toString().padLeft(2, '0')}';
    return _client.post<NumerologyCompatibility>(
      ApiEndpoints.numerologyCompatibility,
      data: {'full_name': fullName, 'birth_date': iso},
      fromJson: (raw) =>
          NumerologyCompatibility.fromJson(raw as Map<String, dynamic>),
    );
  }
}
