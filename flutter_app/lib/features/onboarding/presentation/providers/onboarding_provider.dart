import 'package:cosmic_mirror/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:cosmic_mirror/features/onboarding/domain/entities/birth_profile.dart';
import 'package:cosmic_mirror/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepositoryImpl(apiClient: ref.read(apiClientProvider));
});

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(ref.read(onboardingRepositoryProvider));
});

class OnboardingState {
  const OnboardingState({
    this.currentStep = 0,
    this.birthDate,
    this.birthTime,
    this.birthTimeKnown = true,
    this.birthPlace,
    this.latitude,
    this.longitude,
    this.timezone,
    this.name = '',
    this.focusAreas = const [],
    this.chartReveal,
    this.isLoading = false,
    this.error,
  });

  final int currentStep;
  final DateTime? birthDate;
  final DateTime? birthTime;
  final bool birthTimeKnown;
  final String? birthPlace;
  final double? latitude;
  final double? longitude;
  final String? timezone;
  final String name;
  final List<String> focusAreas;
  final Map<String, dynamic>? chartReveal;
  final bool isLoading;
  final String? error;

  static const int totalSteps = 6;

  bool get canProceed {
    switch (currentStep) {
      case 0:
        return birthDate != null;
      case 1:
        return !birthTimeKnown || birthTime != null;
      case 2:
        return birthPlace != null && latitude != null;
      case 3:
        return name.trim().length >= 2;
      case 4:
        return true; // Focus areas are optional
      case 5:
        return chartReveal != null;
      default:
        return false;
    }
  }

  OnboardingState copyWith({
    int? currentStep,
    DateTime? birthDate,
    DateTime? birthTime,
    bool? birthTimeKnown,
    String? birthPlace,
    double? latitude,
    double? longitude,
    String? timezone,
    String? name,
    List<String>? focusAreas,
    Map<String, dynamic>? chartReveal,
    bool? isLoading,
    String? error,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      birthDate: birthDate ?? this.birthDate,
      birthTime: birthTimeKnown == false ? null : (birthTime ?? this.birthTime),
      birthTimeKnown: birthTimeKnown ?? this.birthTimeKnown,
      birthPlace: birthPlace ?? this.birthPlace,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timezone: timezone ?? this.timezone,
      name: name ?? this.name,
      focusAreas: focusAreas ?? this.focusAreas,
      chartReveal: chartReveal ?? this.chartReveal,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier(this._repository)
      : super(
          OnboardingState(
            birthDate: DateTime(1995, 6, 15),
            // Matches the time wheel's initial position, so "Next" is
            // enabled for someone born at noon without nudging the wheel.
            birthTime: _defaultBirthTime,
          ),
        );

  /// The focus-areas step copy reads "{count} of 3 selected".
  static const int maxFocusAreas = 3;

  static final DateTime _defaultBirthTime = DateTime(2000, 1, 1, 12);

  final OnboardingRepository _repository;

  void setBirthDate(DateTime date) {
    state = state.copyWith(birthDate: date);
  }

  void setBirthTime(DateTime? time) {
    state = state.copyWith(birthTime: time);
  }

  void setBirthTimeKnown({required bool known}) {
    // copyWith drops the time when unknown; when switching back to known,
    // re-seed it with the value the wheel shows so the step stays valid.
    state = state.copyWith(
      birthTimeKnown: known,
      birthTime: known ? (state.birthTime ?? _defaultBirthTime) : null,
    );
  }

  void setBirthPlace({
    required String place,
    required double lat,
    required double lng,
    required String tz,
  }) {
    state = state.copyWith(
      birthPlace: place,
      latitude: lat,
      longitude: lng,
      timezone: tz,
    );
  }

  /// Drops the selected birthplace — called when the user edits the
  /// search text after picking a place, so "Next" can't submit a place
  /// that no longer matches what's on screen.
  void clearBirthPlace() {
    if (state.birthPlace == null && state.latitude == null) return;
    final s = state;
    state = OnboardingState(
      currentStep: s.currentStep,
      birthDate: s.birthDate,
      birthTime: s.birthTime,
      birthTimeKnown: s.birthTimeKnown,
      name: s.name,
      focusAreas: s.focusAreas,
      chartReveal: s.chartReveal,
      isLoading: s.isLoading,
    );
  }

  void setName(String name) {
    state = state.copyWith(name: name);
  }

  void toggleFocusArea(String area) {
    final areas = List<String>.from(state.focusAreas);
    if (areas.contains(area)) {
      areas.remove(area);
    } else if (areas.length < maxFocusAreas) {
      areas.add(area);
    } else {
      return;
    }
    state = state.copyWith(focusAreas: areas);
  }

  void nextStep() {
    if (state.currentStep < OnboardingState.totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  Future<bool> submitBirthProfile() async {
    state = state.copyWith(isLoading: true);
    final profile = BirthProfile(
      birthDate: state.birthDate!,
      birthTime: state.birthTimeKnown ? state.birthTime : null,
      birthTimeKnown: state.birthTimeKnown,
      birthPlace: state.birthPlace!,
      latitude: state.latitude!,
      longitude: state.longitude!,
      timezone: state.timezone!,
    );

    final result = await _repository.saveBirthProfile(profile);
    return result.when(
      success: (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
      failure: (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
    );
  }

  Future<bool> submitName() async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.saveName(state.name);
    return result.when(
      success: (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
      failure: (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
    );
  }

  /// Best-effort save of the optional focus areas.
  Future<bool> submitFocusAreas() async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.saveFocusAreas(state.focusAreas);
    state = state.copyWith(isLoading: false);
    return result.when(success: (_) => true, failure: (_) => false);
  }

  Future<bool> loadChartReveal() async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.getChartReveal();
    return result.when(
      success: (data) {
        state = state.copyWith(isLoading: false, chartReveal: data);
        return true;
      },
      failure: (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
    );
  }
}
