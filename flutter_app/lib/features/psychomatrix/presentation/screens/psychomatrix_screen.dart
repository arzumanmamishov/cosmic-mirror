import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/psychomatrix/domain/entities/psychomatrix.dart';
import 'package:cosmic_mirror/features/psychomatrix/presentation/providers/psychomatrix_providers.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/lively/lively_backdrop.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The visual grid layout, in display rows. The psychomatrix is stored
/// column-major (col1: 1,2,3 | col2: 4,5,6 | col3: 7,8,9) but rendered as
/// rows: [1,4,7], [2,5,8], [3,6,9].
const _gridRows = [
  [1, 4, 7],
  [2, 5, 8],
  [3, 6, 9],
];

class PsychomatrixScreen extends ConsumerWidget {
  const PsychomatrixScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final readingAsync = ref.watch(psychomatrixReadingProvider);
    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('Pythagoras Square'),
      ),
      body: LivelyBackdrop(
        seed: 41,
        intensity: 0.6,
        child: readingAsync.when(
          loading: () => const ShimmerList(itemCount: 5),
          error: (e, _) => ErrorView(
            error: e,
            onRetry: () => ref.invalidate(psychomatrixReadingProvider),
          ),
          data: (reading) => _Body(reading: reading),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.reading});
  final PsychomatrixReading reading;

  @override
  Widget build(BuildContext context) {
    // Build the staggered children list, then fade each in on entry.
    final children = <Widget>[
      _Hero(reading: reading),
      const SizedBox(height: 20),
      const _SectionLabel('Your Matrix'),
      const SizedBox(height: 12),
      _Grid(reading: reading),
      const SizedBox(height: 8),
      _GridHint(),
      const SizedBox(height: 24),
      const _SectionLabel('Lines & Strengths'),
      const SizedBox(height: 12),
      ...reading.lines.map((l) => _LineCard(line: l)),
      const SizedBox(height: 40),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 0),
      itemCount: children.length,
      itemBuilder: (context, i) => _FadeIn(
        delayMs: 40 * i,
        child: children[i],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero — the four working numbers.
// ---------------------------------------------------------------------------

class _Hero extends StatelessWidget {
  const _Hero({required this.reading});
  final PsychomatrixReading reading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final w = reading.workingNumbers;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [p.primary, p.accent]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WORKING NUMBERS',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (reading.birthDate.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Birth date ${reading.birthDate}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _WorkingChip(label: 'W1', value: w.first),
              const SizedBox(width: 10),
              _WorkingChip(label: 'W2', value: w.second),
              const SizedBox(width: 10),
              _WorkingChip(label: 'W3', value: w.third),
              const SizedBox(width: 10),
              _WorkingChip(label: 'W4', value: w.fourth),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkingChip extends StatelessWidget {
  const _WorkingChip({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grid — the 3x3 centerpiece.
// ---------------------------------------------------------------------------

class _Grid extends StatelessWidget {
  const _Grid({required this.reading});
  final PsychomatrixReading reading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          for (final row in _gridRows)
            Row(
              children: [
                for (final digit in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: _GridCell(
                        cell: reading.cellFor(digit) ??
                            PsychomatrixCell(
                              digit: digit,
                              count: 0,
                              repeated: '',
                              title: '',
                              meaning: '',
                            ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({required this.cell});
  final PsychomatrixCell cell;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final empty = cell.isEmpty;
    return AspectRatio(
      aspectRatio: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showCellSheet(context, cell),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: empty
                ? p.surfaceElevated.withValues(alpha: 0.35)
                : p.gold.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: empty
                  ? p.textTertiary.withValues(alpha: 0.18)
                  : p.gold.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: FittedBox(
                    child: Text(
                      empty ? '${cell.digit}' : cell.repeated,
                      style: TextStyle(
                        color: empty
                            ? p.textTertiary.withValues(alpha: 0.5)
                            : p.gold,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                cell.title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: empty ? p.textTertiary : p.textSecondary,
                  fontSize: 9.5,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Text(
      'Tap any cell to read its meaning.',
      textAlign: TextAlign.center,
      style: TextStyle(color: p.textTertiary, fontSize: 12),
    );
  }
}

void _showCellSheet(BuildContext context, PsychomatrixCell cell) {
  final p = context.palette;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: p.surface,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.gold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${cell.digit}',
                      style: TextStyle(
                        color: p.gold,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cell.title,
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cell.count == 0
                              ? 'Absent'
                              : '${cell.repeated}  ·  ${cell.count}x',
                          style: TextStyle(
                            color: p.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                cell.meaning,
                style: TextStyle(
                  color: p.textSecondary,
                  fontSize: 14.5,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Lines.
// ---------------------------------------------------------------------------

class _LineCard extends StatelessWidget {
  const _LineCard({required this.line});
  final PsychomatrixLine line;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.textTertiary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  line.title,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StrengthPill(strength: line.strength),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Cells ${line.cells.join(' · ')}',
            style: TextStyle(
              color: p.textTertiary,
              fontSize: 11,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            line.meaning,
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StrengthPill extends StatelessWidget {
  const _StrengthPill({required this.strength});
  final int strength;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final Color c;
    if (strength <= 1) {
      c = p.textTertiary;
    } else if (strength <= 4) {
      c = p.accent;
    } else {
      c = p.gold;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$strength',
        style: TextStyle(
          color: c,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chrome helpers.
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Text(
      text,
      style: TextStyle(
        color: p.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

/// Simple entry fade+slide used to stagger the body children.
class _FadeIn extends StatefulWidget {
  const _FadeIn({required this.child, required this.delayMs});
  final Widget child;
  final int delayMs;

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(_fade);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
