import 'package:cosmic_mirror/core/network/api_client.dart';
import 'package:cosmic_mirror/core/network/api_endpoints.dart';
import 'package:cosmic_mirror/features/human_design/domain/entities/human_design.dart';

class HumanDesignRepository {
  HumanDesignRepository(this._client);
  final ApiClient _client;

  Future<HumanDesignChart> getChart() async {
    return _client.get<HumanDesignChart>(
      ApiEndpoints.humanDesign,
      fromJson: (raw) =>
          HumanDesignChart.fromJson(raw as Map<String, dynamic>),
    );
  }
}
