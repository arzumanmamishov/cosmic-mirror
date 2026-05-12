import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/numerology/domain/entities/numerology.dart';
import 'package:cosmic_mirror/features/numerology/presentation/providers/numerology_providers.dart';
import 'package:cosmic_mirror/features/numerology/presentation/widgets/number_card.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Standalone Name Numerology Calculator. Enter any name → see its
/// Expression / Soul Urge / Personality numbers, hidden passion, karmic
/// lessons, and the letter-by-letter trace that produced the totals.
///
/// No birth profile required — works for partners, friends, business
/// names, characters. Backed by `POST /api/v1/numerology/name`.
class NumerologyNameCalculatorScreen extends ConsumerStatefulWidget {
  const NumerologyNameCalculatorScreen({super.key});

  @override
  ConsumerState<NumerologyNameCalculatorScreen> createState() =>
      _NumerologyNameCalculatorScreenState();
}

class _NumerologyNameCalculatorScreenState
    extends ConsumerState<NumerologyNameCalculatorScreen> {
  final _controller = TextEditingController();
  String _submitted = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _calculate() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    setState(() => _submitted = value);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: Text(l.numerologyNameCalculatorTitle),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CosmicStarfield(
              color: p.textPrimary,
              starCount: 50,
              intensity: 0.6,
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
            children: [
              Text(
                l.numerologyNameCalculatorBlurb,
                style: TextStyle(
                  color: p.textSecondary,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              _NameInput(
                controller: _controller,
                hintText: l.numerologyNameInputHint,
                onSubmitted: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _calculate,
                  icon: const Icon(Icons.calculate_rounded),
                  label: Text(l.numerologyNameCalculate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_submitted.isNotEmpty) _Results(name: _submitted),
            ],
          ),
        ],
      ),
    );
  }
}

class _NameInput extends StatelessWidget {
  const _NameInput({
    required this.controller,
    required this.hintText,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.glassBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.go,
        onSubmitted: onSubmitted,
        style: TextStyle(color: p.textPrimary, fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: p.textTertiary),
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.name});
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final asyncValue = ref.watch(numerologyNameAnalysisProvider(name));

    return asyncValue.when(
      loading: () => const ShimmerList(itemCount: 3),
      error: (e, _) => ErrorView(
        error: e,
        onRetry: () =>
            ref.invalidate(numerologyNameAnalysisProvider(name)),
      ),
      data: (analysis) {
        if (analysis == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              analysis.name,
              style: TextStyle(
                color: p.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            NumberCard(
              title: l.numerologyCoreExpression,
              number: analysis.expression,
              icon: Icons.campaign_rounded,
            ),
            NumberCard(
              title: l.numerologyCoreSoulUrge,
              number: analysis.soulUrge,
              icon: Icons.favorite_rounded,
            ),
            NumberCard(
              title: l.numerologyCorePersonality,
              number: analysis.personality,
              icon: Icons.face_rounded,
            ),
            const SizedBox(height: 20),
            _LetterBreakdownPanel(letters: analysis.letters),
            const SizedBox(height: 16),
            _PassionAndKarmaPanel(analysis: analysis),
          ],
        );
      },
    );
  }
}

class _LetterBreakdownPanel extends StatelessWidget {
  const _LetterBreakdownPanel({required this.letters});
  final List<NumerologyLetter> letters;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.numerologyNameLetterBreakdown.toUpperCase(),
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final letter in letters)
                _LetterChip(letter: letter),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _LegendDot(color: p.gold, label: l.numerologyNameVowels),
              const SizedBox(width: 12),
              _LegendDot(color: p.primary, label: l.numerologyNameConsonants),
            ],
          ),
        ],
      ),
    );
  }
}

class _LetterChip extends StatelessWidget {
  const _LetterChip({required this.letter});
  final NumerologyLetter letter;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final accent = letter.isVowel ? p.gold : p.primary;
    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            letter.letter,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          Text(
            '${letter.value}',
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: p.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class _PassionAndKarmaPanel extends StatelessWidget {
  const _PassionAndKarmaPanel({required this.analysis});
  final NumerologyNameAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row(
            label: l.numerologyNameHiddenPassion,
            value: '${analysis.hiddenPassion}',
            valueColor: p.gold,
          ),
          const SizedBox(height: 12),
          Text(
            l.numerologyNameKarmicLessons.toUpperCase(),
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (analysis.karmicLessons.isEmpty)
            Text(
              l.numerologyNameKarmicLessonsNone,
              style: TextStyle(color: p.textSecondary, fontSize: 13),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final n in analysis.karmicLessons)
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.warning.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: p.warning.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      '$n',
                      style: TextStyle(
                        color: p.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
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

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
