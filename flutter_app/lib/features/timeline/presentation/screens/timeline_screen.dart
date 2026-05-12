import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/core/network/api_endpoints.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:cosmic_mirror/shared/widgets/premium_gate.dart';
import 'package:cosmic_mirror/shared/widgets/staggered_fade_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final timelineProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, type) async {
  final client = ref.read(apiClientProvider);
  return client.get<Map<String, dynamic>>(
    ApiEndpoints.timeline,
    queryParameters: {'type': type},
  );
});

/// Transit Forecast — gradient hero with pill-tab window picker, then
/// a timeline rail with energy-coded dots and glass period cards.
/// Palette-aware, FadeSlideIn entrance on each card.
class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  static const _types = ['30d', '3m', '12m'];
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final labels = [l.transit30Days, l.transit3Months, l.transit12Months];

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(title: Text(l.transitHeroTitle)),
      body: PremiumGate(
        featureName: 'Timeline Forecasts',
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: FadeSlideIn(
                child: _TimelineHero(
                  labels: labels,
                  selectedIndex: _selected,
                  onSelect: (i) => setState(() => _selected = i),
                ),
              ),
            ),
            Expanded(child: _TimelineTab(type: _types[_selected])),
          ],
        ),
      ),
    );
  }
}

class _TimelineHero extends StatelessWidget {
  const _TimelineHero({
    required this.labels,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            p.primary.withValues(alpha: 0.20),
            p.accent.withValues(alpha: 0.14),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: p.gold.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wb_twilight_rounded, color: p.gold, size: 16),
              const SizedBox(width: 6),
              Text(
                l.transitHeroTitle.toUpperCase(),
                style: TextStyle(
                  color: p.gold,
                  fontSize: 11,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l.transitHeroSubtitle,
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: p.background.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: p.glassBorder),
            ),
            child: Row(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(
                    child: _PillTab(
                      label: labels[i],
                      active: i == selectedIndex,
                      onTap: () => onSelect(i),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  const _PillTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [
                    Color(0xFFE9D49A),
                    Color(0xFFD4B16A),
                    Color(0xFF9F7637),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(100),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: p.gold.withValues(alpha: 0.35),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFF1A1F2E) : p.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _TimelineTab extends ConsumerWidget {
  const _TimelineTab({required this.type});

  final String type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final dataAsync = ref.watch(timelineProvider(type));

    return dataAsync.when(
      loading: () => const ShimmerList(),
      error: (e, _) => ErrorView(
        error: e,
        onRetry: () => ref.invalidate(timelineProvider(type)),
      ),
      data: (data) {
        final periods = (data['periods'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();
        if (periods.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                l.transitNoData,
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textSecondary),
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          itemCount: periods.length,
          itemBuilder: (context, index) {
            return FadeSlideIn(
              delay: Duration(milliseconds: 80 + index * 60),
              child: _TimelinePeriod(
                period: periods[index],
                isFirst: index == 0,
                isLast: index == periods.length - 1,
              ),
            );
          },
        );
      },
    );
  }
}

class _TimelinePeriod extends StatelessWidget {
  const _TimelinePeriod({
    required this.period,
    required this.isFirst,
    required this.isLast,
  });

  final Map<String, dynamic> period;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final title = period['title'] as String? ?? '';
    final description = period['description'] as String? ?? '';
    final dateRange = period['date_range'] as String? ?? '';
    final energy = period['energy'] as String? ?? 'neutral';
    final color = _energyColor(p, energy);
    final icon = _energyIcon(energy);
    final energyLabel = _energyLabel(l, energy);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline rail — colored dot with glow + connecting line.
          SizedBox(
            width: 28,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(width: 2, color: p.glassBorder),
                  )
                else
                  const SizedBox(height: 6),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.background, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.55),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: p.glassBorder),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Period card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: p.glassBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: color.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 11, color: color),
                              const SizedBox(width: 4),
                              Text(
                                energyLabel,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (dateRange.isNotEmpty)
                          Text(
                            dateRange,
                            style: TextStyle(
                              color: p.textTertiary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    if (title.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          color: p.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _energyColor(AppPalette p, String energy) {
  switch (energy) {
    case 'positive':
      return p.success;
    case 'challenging':
      return p.warning;
    case 'intense':
      return p.error;
    default:
      return p.primary;
  }
}

IconData _energyIcon(String energy) {
  switch (energy) {
    case 'positive':
      return Icons.trending_up_rounded;
    case 'challenging':
      return Icons.warning_amber_rounded;
    case 'intense':
      return Icons.bolt_rounded;
    default:
      return Icons.circle_outlined;
  }
}

String _energyLabel(AppLocalizations l, String energy) {
  switch (energy) {
    case 'positive':
      return l.transitEnergyPositive;
    case 'challenging':
      return l.transitEnergyChallenging;
    case 'intense':
      return l.transitEnergyIntense;
    default:
      return l.transitEnergyNeutral;
  }
}
