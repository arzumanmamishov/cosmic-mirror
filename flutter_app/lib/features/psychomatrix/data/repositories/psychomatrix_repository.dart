import 'package:cosmic_mirror/core/network/api_client.dart';
import 'package:cosmic_mirror/core/network/api_endpoints.dart';
import 'package:cosmic_mirror/features/psychomatrix/domain/entities/psychomatrix.dart';

class PsychomatrixRepository {
  PsychomatrixRepository(this._client);
  final ApiClient _client;

  Future<PsychomatrixReading> getReading() async {
    return _client.get<PsychomatrixReading>(
      ApiEndpoints.psychomatrix,
      fromJson: (raw) =>
          PsychomatrixReading.fromJson(raw as Map<String, dynamic>),
    );
  }
}
