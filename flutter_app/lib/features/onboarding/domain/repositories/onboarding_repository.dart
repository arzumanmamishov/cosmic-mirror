import '../../../../core/utils/result.dart';
import '../entities/birth_profile.dart';

abstract class OnboardingRepository {
  Future<Result<void>> saveBirthProfile(BirthProfile profile);
  Future<Result<void>> saveName(String name);
  Future<Result<void>> saveFocusAreas(List<String> areas);
  Future<Result<Map<String, dynamic>>> getChartReveal();
}
