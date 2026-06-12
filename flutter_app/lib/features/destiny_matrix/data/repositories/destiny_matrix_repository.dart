import 'package:cosmic_mirror/core/network/api_client.dart';
import 'package:cosmic_mirror/core/network/api_endpoints.dart';
import 'package:cosmic_mirror/features/destiny_matrix/domain/entities/destiny_matrix.dart';

class DestinyMatrixRepository {
  DestinyMatrixRepository(this._client);
  final ApiClient _client;

  Future<DestinyMatrixReading> getReading() async {
    return _client.get<DestinyMatrixReading>(
      ApiEndpoints.destinyMatrix,
      fromJson: (raw) =>
          DestinyMatrixReading.fromJson(raw as Map<String, dynamic>),
    );
  }
}
