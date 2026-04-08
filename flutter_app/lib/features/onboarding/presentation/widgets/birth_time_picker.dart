import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';

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
    return Column(
      children: [
        // Unknown time toggle
        GestureDetector(
          onTap: () => onKnownChanged(!birthTimeKnown),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: !birthTimeKnown
                  ? CosmicColors.primary.withOpacity(0.15)
                  : CosmicColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: !birthTimeKnown
                    ? CosmicColors.primary
                    : CosmicColors.glassBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  !birthTimeKnown
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: !birthTimeKnown
                      ? CosmicColors.primary
                      : CosmicColors.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "I don't know my birth time",
                        style: CosmicTypography.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "We'll use approximate calculations. Your Rising sign may differ.",
                        style: CosmicTypography.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Time picker
        if (birthTimeKnown)
          Expanded(
            child: CupertinoTheme(
              data: const CupertinoThemeData(
                brightness: Brightness.dark,
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: TextStyle(
                    color: CosmicColors.textPrimary,
                    fontSize: 22,
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: selectedTime ?? DateTime(2000, 1, 1, 12),
                use24hFormat: true,
                onDateTimeChanged: onTimeChanged,
                backgroundColor: Colors.transparent,
              ),
            ),
          )
        else
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 48,
                    color: CosmicColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No worries! We can still create a meaningful\nchart using your date and location.',
                    style: CosmicTypography.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
