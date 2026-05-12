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

final yearlyForecastProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final client = ref.read(apiClientProvider);
  return client.get<Map<String, dynamic>>(ApiEndpoints.yearlyForecast);
});

/// Modernized Yearly Forecast — large gradient hero card carrying the
/// year theme + overview, then four quarter cards each badged with a
/// season icon and gold accent. Palette-aware, FadeSlideIn entrance
/// on each block.
class YearlyForecastScreen extends ConsumerWidget {
  const YearlyForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final forecastAsync = ref.watch(yearlyForecastProvider);

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        title: Text(l.yearlyForecastTitle),
      ),
      body: PremiumGate(
        featureName: 'Yearly Forecast',
        child: forecastAsync.when(
          loading: () => const ShimmerList(itemCount: 5),
          error: (e, _) => ErrorView(
            error: e,
            onRetry: () => ref.invalidate(yearlyForecastProvider),
          ),
          data: (data) {
            final theme = data['theme'] as String? ?? '';
            final overview = data['overview'] as String? ?? '';
            final quarters =
                (data['quarters'] as List<dynamic>? ?? const [])
                    .cast<Map<String, dynamic>>();

            if (theme.isEmpty && quarters.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    l.yfNoData,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.textSecondary),
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                FadeSlideIn(child: _YearHero(theme: theme, overview: overview)),
                const SizedBox(height: 22),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_view_month_rounded,
                        color: p.gold,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l.yfQuarterBreakdown.toUpperCase(),
                        style: TextStyle(
                          color: p.gold,
                          fontSize: 11,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                for (var i = 0; i < quarters.length; i++)
                  FadeSlideIn(
                    delay: Duration(milliseconds: 180 + i * 80),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _QuarterCard(index: i, quarter: quarters[i]),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _YearHero extends StatelessWidget {
  const _YearHero({required this.theme, required this.overview});
  final String theme;
  final String overview;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [
            p.primary.withValues(alpha: 0.22),
            p.accent.withValues(alpha: 0.16),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: p.gold.withValues(alpha: 0.36)),
        boxShadow: [
          BoxShadow(
            color: p.gold.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: p.gold, size: 16),
              const SizedBox(width: 6),
              Text(
                l.yfYearTheme,
                style: TextStyle(
                  color: p.gold,
                  fontSize: 11,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            theme.isNotEmpty ? theme : DateTime.now().year.toString(),
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              height: 1.1,
            ),
          ),
          if (overview.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              overview,
              style: TextStyle(
                color: p.textSecondary,
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            l.yfHeroSubtitle,
            style: TextStyle(
              color: p.textTertiary,
              fontSize: 12,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuarterCard extends StatelessWidget {
  const _QuarterCard({required this.index, required this.quarter});
  final int index;
  final Map<String, dynamic> quarter;

  static const _quarterIcons = [
    Icons.local_florist_rounded, // Q1 — spring
    Icons.wb_sunny_rounded, // Q2 — summer
    Icons.eco_rounded, // Q3 — autumn
    Icons.ac_unit_rounded, // Q4 — winter
  ];

  static const _quarterColors = [
    Color(0xFF7BB68A), // spring sage
    Color(0xFFF4C542), // summer gold
    Color(0xFFC25450), // autumn terracotta
    Color(0xFF5C7AAF), // winter slate
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final accent = _quarterColors[index.clamp(0, 3)];
    final icon = _quarterIcons[index.clamp(0, 3)];
    final label = quarter['label'] as String? ?? l.yfQuarterLabel(index + 1);
    final description = quarter['description'] as String? ?? '';
    final months = (quarter['months'] as List<dynamic>? ?? const [])
        .cast<String>()
        .take(3)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.yfQuarterLabel(index + 1),
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (months.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: [
                for (final m in months)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Text(
                      m,
                      style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                color: p.textSecondary,
                fontSize: 13,
                height: 1.55,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
