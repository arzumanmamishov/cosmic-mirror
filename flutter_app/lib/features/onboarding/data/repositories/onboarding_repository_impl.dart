import 'package:cosmic_mirror/core/error/exceptions.dart';
import 'package:cosmic_mirror/core/error/failures.dart';
import 'package:cosmic_mirror/core/network/api_client.dart';
import 'package:cosmic_mirror/core/network/api_endpoints.dart';
import 'package:cosmic_mirror/core/utils/result.dart';
import 'package:cosmic_mirror/features/onboarding/data/models/birth_profile_model.dart';
import 'package:cosmic_mirror/features/onboarding/domain/entities/birth_profile.dart';
import 'package:cosmic_mirror/features/onboarding/domain/repositories/onboarding_repository.dart';

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
    } on AuthException catch (e) {
      return Err(AuthFailure(message: e.message));
    } on RateLimitException {
      return const Err(RateLimitFailure());
    } on NetworkException {
      return const Err(NetworkFailure());
    } catch (e) {
      return Err(ServerFailure(message: e.toString()));
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
    } on AuthException catch (e) {
      return Err(AuthFailure(message: e.message));
    } on RateLimitException {
      return const Err(RateLimitFailure());
    } on NetworkException {
      return const Err(NetworkFailure());
    } catch (e) {
      return Err(ServerFailure(message: e.toString()));
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
    } on AuthException catch (e) {
      return Err(AuthFailure(message: e.message));
    } on RateLimitException {
      return const Err(RateLimitFailure());
    } on NetworkException {
      return const Err(NetworkFailure());
    } catch (e) {
      return Err(ServerFailure(message: e.toString()));
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
    } on AuthException catch (e) {
      return Err(AuthFailure(message: e.message));
    } on RateLimitException {
      return const Err(RateLimitFailure());
    } on NetworkException {
      return const Err(NetworkFailure());
    } catch (e) {
      return Err(ServerFailure(message: e.toString()));
    }
  }
}
