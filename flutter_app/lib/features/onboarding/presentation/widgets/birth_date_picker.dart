import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Birth-date wheel — a Cupertino date picker framed in a Lively glass
/// card with a gold-tinted selection band, per the design system.
class BirthDatePicker extends StatelessWidget {
  const BirthDatePicker({
    required this.onDateChanged,
    super.key,
    this.selectedDate,
  });

  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? p.surfaceGlass : p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.line),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Gold selection band — sits behind the wheel text, drawn at
          // the centre row where the picker's own selection lands.
          IgnorePointer(
            child: GoldSelectionBand(palette: p),
          ),
          CupertinoTheme(
            data: CupertinoThemeData(
              brightness: isDark ? Brightness.dark : Brightness.light,
              textTheme: CupertinoTextThemeData(
                dateTimePickerTextStyle: LivelyType.h1(p.textPrimary)
                    .copyWith(fontWeight: FontWeight.w400),
              ),
            ),
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: selectedDate ?? DateTime(1995, 6, 15),
              minimumDate: DateTime(1900),
              maximumDate: DateTime.now(),
              backgroundColor: Colors.transparent,
              onDateTimeChanged: (date) {
                HapticFeedback.selectionClick();
                onDateChanged(date);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The gold-tinted center band that marks a wheel picker's selected row.
/// Shared by the date + time pickers.
class GoldSelectionBand extends StatelessWidget {
  const GoldSelectionBand({required this.palette, this.height = 40, super.key});

  final AppPalette palette;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.glassBorder),
      ),
    );
  }
}
