import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// A multi-segment progress rail. Completed and active segments are gold;
/// the **active** segment is wider than the rest and animates its width on
/// step change — a quiet "you are here" cue.
class StepProgress extends StatelessWidget {
  const StepProgress({
    required this.step,
    this.total = 5,
    super.key,
  });

  /// Zero-based index of the current step.
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: List.generate(total, (i) {
        final done = i < step;
        final active = i == step;
        return Padding(
          padding: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: active ? 22 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: (done || active) ? p.primary : p.line,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}
