import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/birth_profile.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../models/birth_profile_model.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Result<void>> saveBirthProfile(BirthProfile profile) async {
    try {
      final model = BirthProfileModel(
        birthDate: profile.birthDate,
        birthTime: profile.birthTime,
        birthTimeKnown: profile.birthTimeKnown,
        birthPlace: profile.birthPlace,
        latitude: profile.latitude,
        longitude: profile.longitude,
        timezone: profile.timezone,
      );
      await _apiClient.post<dynamic>(
        ApiEndpoints.birthProfile,
        data: model.toJson(),
      );
      return const Success(null);
    } on ServerException catch (e) {
      return Err(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Err(NetworkFailure());
    }
  }

  @override
  Future<Result<void>> saveName(String name) async {
    try {
      await _apiClient.put<dynamic>(
        ApiEndpoints.me,
        data: {'name': name},
      );
      return const Success(null);
    } on ServerException catch (e) {
      return Err(ServerFailure(message: e.message));
    } on NetworkException {
      return const Err(NetworkFailure());
    }
  }

  @override
  Future<Result<void>> saveFocusAreas(List<String> areas) async {
    try {
      await _apiClient.put<dynamic>(
        ApiEndpoints.preferences,
        data: {'focus_areas': areas},
      );
      return const Success(null);
    } on ServerException catch (e) {
      return Err(ServerFailure(message: e.message));
    } on NetworkException {
      return const Err(NetworkFailure());
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getChartReveal() async {
    try {
      final data = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.chartSummary,
      );
      return Success(data);
    } on ServerException catch (e) {
      return Err(ServerFailure(message: e.message));
    } on NetworkException {
      return const Err(NetworkFailure());
    }
  }
}
