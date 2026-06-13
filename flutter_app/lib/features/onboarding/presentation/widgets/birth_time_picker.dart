import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:cosmic_mirror/features/onboarding/presentation/widgets/birth_date_picker.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Birth-time step body — an "I don't know" toggle, a framed Cupertino
/// time wheel with the gold selection band, and a why-it-matters info
/// card. All Lively design-system tokens.
class BirthTimePicker extends StatelessWidget {
  const BirthTimePicker({
    required this.onTimeChanged,
    required this.onKnownChanged,
    super.key,
    this.selectedTime,
    this.birthTimeKnown = true,
  });

  final DateTime? selectedTime;
  final bool birthTimeKnown;
  final ValueChanged<DateTime> onTimeChanged;
  final ValueChanged<bool> onKnownChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // "I don't know" toggle
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onKnownChanged(!birthTimeKnown);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: !birthTimeKnown
                  ? p.primary.withValues(alpha: 0.12)
                  : (isDark ? p.surfaceGlass : p.surface),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: !birthTimeKnown ? p.primary : p.line,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  !birthTimeKnown
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: !birthTimeKnown ? p.primary : p.textMuted,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.onboardingDontKnowTime,
                        style: LivelyType.h2(p.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.onboardingDontKnowTimeHelp,
                        style: LivelyType.small(p.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (birthTimeKnown) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? p.surfaceGlass : p.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.line),
            ),
            child: SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IgnorePointer(child: GoldSelectionBand(palette: p)),
                  CupertinoTheme(
                    data: CupertinoThemeData(
                      brightness:
                          isDark ? Brightness.dark : Brightness.light,
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: LivelyType.h1(p.textPrimary)
                            .copyWith(fontWeight: FontWeight.w400),
                      ),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      initialDateTime:
                          selectedTime ?? DateTime(2000, 1, 1, 12),
                      use24hFormat: true,
                      backgroundColor: Colors.transparent,
                      onDateTimeChanged: (time) {
                        HapticFeedback.selectionClick();
                        onTimeChanged(time);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Why birth time matters.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: isDark ? 0.07 : 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.glassBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_rounded, color: p.primary, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.onboardingDontKnowTimeHelp,
                    style: LivelyType.small(p.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ] else
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.brightness_5_rounded,
                      size: 44, color: p.primary.withValues(alpha: 0.7),),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      l10n.onboardingNoTimeNote,
                      style: LivelyType.body(p.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
