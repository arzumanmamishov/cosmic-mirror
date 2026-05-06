import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/core/network/api_endpoints.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/features/onboarding/data/models/birth_profile_model.dart';
import 'package:cosmic_mirror/features/onboarding/domain/entities/birth_profile.dart';
import 'package:cosmic_mirror/features/onboarding/presentation/widgets/birth_date_picker.dart';
import 'package:cosmic_mirror/features/onboarding/presentation/widgets/birth_time_picker.dart';
import 'package:cosmic_mirror/features/onboarding/presentation/widgets/birthplace_search.dart';
import 'package:cosmic_mirror/features/chart/presentation/screens/chart_screen.dart'
    show chartProvider;
import 'package:cosmic_mirror/features/human_design/presentation/providers/human_design_providers.dart'
    show humanDesignProvider;
import 'package:cosmic_mirror/features/profile/presentation/providers/profile_providers.dart';
import 'package:cosmic_mirror/features/vedic_chart/presentation/providers/vedic_providers.dart'
    show
        activeChartProvider,
        vedicAshtakavargaProvider,
        vedicDashaProvider,
        vedicRasiProvider,
        vedicShadbalaProvider,
        vedicYogasProvider;
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _kGold = Color(0xFFD4B16A);

/// Targeted birth-data editor — pre-populates with the user's existing
/// profile and PUTs only this slice, instead of forcing them through
/// the full onboarding flow. Returns to the previous screen on save.
class EditBirthDataScreen extends ConsumerStatefulWidget {
  const EditBirthDataScreen({super.key});

  @override
  ConsumerState<EditBirthDataScreen> createState() =>
      _EditBirthDataScreenState();
}

class _EditBirthDataScreenState extends ConsumerState<EditBirthDataScreen> {
  DateTime? _birthDate;
  DateTime? _birthTime;
  bool _birthTimeKnown = true;
  String? _birthPlace;
  double? _latitude;
  double? _longitude;
  String? _timezone;

  bool _saving = false;
  bool _initialized = false;
  String? _error;

  void _hydrate(BirthProfile profile) {
    if (_initialized) return;
    _initialized = true;
    setState(() {
      _birthDate = profile.birthDate;
      _birthTime = profile.birthTime;
      _birthTimeKnown = profile.birthTimeKnown;
      _birthPlace = profile.birthPlace;
      _latitude = profile.latitude;
      _longitude = profile.longitude;
      _timezone = profile.timezone;
    });
  }

  bool get _canSave =>
      _birthDate != null &&
      _birthPlace != null &&
      _latitude != null &&
      _longitude != null &&
      _timezone != null &&
      (!_birthTimeKnown || _birthTime != null);

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final model = BirthProfileModel(
      birthDate: _birthDate!,
      birthTime: _birthTimeKnown ? _birthTime : null,
      birthTimeKnown: _birthTimeKnown,
      birthPlace: _birthPlace!,
      latitude: _latitude!,
      longitude: _longitude!,
      timezone: _timezone!,
    );

    try {
      final client = ref.read(apiClientProvider);
      await client.put<dynamic>(
        ApiEndpoints.birthProfile,
        data: model.toJson(),
      );
      ref
        ..invalidate(birthProfileProvider)
        // Every chart depends on the same backend birth profile — drop
        // their cached values so the next view re-fetches against the
        // new data instead of showing yesterday's chart.
        ..invalidate(chartProvider)
        ..invalidate(humanDesignProvider)
        ..invalidate(activeChartProvider)
        ..invalidate(vedicRasiProvider)
        ..invalidate(vedicDashaProvider)
        ..invalidate(vedicYogasProvider)
        ..invalidate(vedicShadbalaProvider)
        ..invalidate(vedicAshtakavargaProvider);
      // Sun/moon/rising are derived from birth data and arrive via the
      // session response, so refresh the user state too.
      try {
        await ref.read(currentUserProvider.notifier).bootstrapSession();
      } catch (_) {/* non-fatal */}
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final profileAsync = ref.watch(birthProfileProvider);
    profileAsync.whenData((profile) {
      if (profile != null) _hydrate(profile);
    });

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).editBirthDataTitle,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: profileAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kGold)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              "Couldn't load your birth data: $e",
              style: TextStyle(color: p.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (_) {
          if (!_initialized) {
            return const Center(child: CircularProgressIndicator(color: _kGold));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _SectionLabel(
                label: AppLocalizations.of(context).editBirthDateLabel,
                palette: p,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: BirthDatePicker(
                  selectedDate: _birthDate,
                  onDateChanged: (d) => setState(() => _birthDate = d),
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel(
                label: AppLocalizations.of(context).editBirthTimeLabel,
                palette: p,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 250,
                child: BirthTimePicker(
                  selectedTime: _birthTime,
                  birthTimeKnown: _birthTimeKnown,
                  onTimeChanged: (t) => setState(() => _birthTime = t),
                  onKnownChanged: (k) =>
                      setState(() => _birthTimeKnown = k),
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel(
                label: AppLocalizations.of(context).editBirthPlaceLabel,
                palette: p,
              ),
              const SizedBox(height: 8),
              BirthplaceSearch(
                selectedPlace: _birthPlace,
                onPlaceSelected: (place, lat, lng, tz) {
                  setState(() {
                    _birthPlace = place;
                    _latitude = lat;
                    _longitude = lng;
                    _timezone = tz;
                  });
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: p.error.withValues(alpha: 0.32),
                    ),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: p.error, fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _SaveButton(
                enabled: _canSave && !_saving,
                loading: _saving,
                onTap: _save,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.palette});
  final String label;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        color: palette.textTertiary,
        fontSize: 11,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            color: enabled ? _kGold : _kGold.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    AppLocalizations.of(context).editSaveChanges,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
