import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/colors.dart';

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
    return CupertinoTheme(
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
        mode: CupertinoDatePickerMode.date,
        initialDateTime: selectedDate ?? DateTime(1995, 6, 15),
        minimumDate: DateTime(1900),
        maximumDate: DateTime.now(),
        onDateTimeChanged: onDateChanged,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
