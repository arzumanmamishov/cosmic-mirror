import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/daily_reading/domain/entities/daily_reading.dart';
import 'package:cosmic_mirror/features/daily_reading/presentation/providers/daily_reading_provider.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_pulse.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:cosmic_mirror/shared/widgets/staggered_fade_in.dart';

class DailyReadingScreen extends ConsumerWidget {
  const DailyReadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingAsync = ref.watch(dailyReadingProvider);
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () {
              final reading = readingAsync.valueOrNull;
              if (reading != null) {
                Share.share(
                  '"${reading.affirmation}"\n\nMy lucky color today: '
                  '${reading.luckyColor}\n\n~ Lively',
                );
              }
            },
          ),
        ],
      ),
      body: readingAsync.when(
        loading: () => const ShimmerList(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(dailyReadingProvider),
        ),
        data: (reading) => _ReadingBody(reading: reading),
      ),
    );
  }
}

class _ReadingBody extends StatelessWidget {
  const _ReadingBody({required this.reading});

  final DailyReading reading;

  /// Wraps a child in a [FadeSlideIn] with a delay scaled by index, so the
  /// section cards cascade into view after the hero animates in.
  Widget _staggered(int index, Widget child) {
    return FadeSlideIn(
      delay: Duration(milliseconds: 240 + index * 70),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Hero(reading: reading)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
          sliver: SliverList.list(
            children: [
              _staggered(0, _SectionCard(
                title: 'Emotional',
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFFE14B8A),
                content: reading.emotional,
              )),
              const SizedBox(height: 12),
              _staggered(1, _SectionCard(
                title: 'Love & Connection',
                icon: Icons.auto_awesome_rounded,
                iconColor: const Color(0xFFC76E5E),
                content: reading.love,
              )),
              const SizedBox(height: 12),
              _staggered(2, _SectionCard(
                title: 'Career & Purpose',
                icon: Icons.work_rounded,
                iconColor: const Color(0xFFB8860B),
                content: reading.career,
              )),
              const SizedBox(height: 12),
              _staggered(3, _SectionCard(
                title: 'Health & Wellness',
                icon: Icons.spa_rounded,
                iconColor: const Color(0xFF5ED39A),
                content: reading.health,
              )),
              const SizedBox(height: 12),
              _staggered(4, _SectionCard(
                title: 'Caution',
                icon: Icons.shield_moon_rounded,
                iconColor: const Color(0xFFF2B66D),
                content: reading.caution,
              )),
              const SizedBox(height: 12),
              _staggered(5, _SectionCard(
                title: 'Action Steps',
                icon: Icons.bolt_rounded,
                iconColor: const Color(0xFF7B61FF),
                content: reading.action,
              )),
              const SizedBox(height: 24),
              _staggered(6, _AffirmationCard(text: reading.affirmation)),
              const SizedBox(height: 16),
              _staggered(7, _LuckyRow(
                color: reading.luckyColor,
                number: reading.luckyNumber,
              )),
            ],
          ),
        ),
      ],
    );
  }
}

/// Hero with date, sun/moon/rising signs, and a circular energy ring.
class _Hero extends StatelessWidget {
  const _Hero({required this.reading});

  final DailyReading reading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dateLine = DateFormat('EEEE, MMMM d').format(reading.readingDate);

    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          // Hero gradient background
          Container(
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  p.primary.withValues(alpha: 0.20),
                  p.background,
                ],
              ),
            ),
            child: const SizedBox.shrink(),
          ),
          // Twinkling stars overlay constrained to the hero area
          Positioned.fill(
            child: CosmicStarfield(
              color: p.textPrimary,
              starCount: 50,
              intensity: 0.8,
              seed: 17,
            ),
          ),
          // Foreground hero content with staggered entrance
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeSlideIn(
                  child: Text(
                    dateLine,
                    style: TextStyle(
                      color: p.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: Text(
                    'Your Daily Reading',
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  child: Row(
                    children: [
                      CosmicPulse(
                        color: _ringColor(p, reading.energyLevel),
                        maxRadius: 60,
                        child: _EnergyRing(level: reading.energyLevel),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (reading.sunSign != null)
                              _SignChip(label: 'Sun', sign: reading.sunSign!),
                            if (reading.moonSign != null) ...[
                              const SizedBox(height: 6),
                              _SignChip(label: 'Moon', sign: reading.moonSign!),
                            ],
                            if (reading.risingSign != null) ...[
                              const SizedBox(height: 6),
                              _SignChip(
                                label: 'Rising',
                                sign: reading.risingSign!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _ringColor(AppPalette p, int level) {
    if (level <= 3) return p.error;
    if (level <= 6) return p.gold;
    return p.success;
  }
}

class _EnergyRing extends StatelessWidget {
  const _EnergyRing({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = level <= 3
        ? p.error
        : level <= 6
            ? p.gold
            : p.success;

    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: CircularProgressIndicator(
              value: level / 10,
              strokeWidth: 6,
              backgroundColor: p.surfaceElevated,
              valueColor: AlwaysStoppedAnimation(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$level',
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              Text(
                'energy',
                style: TextStyle(
                  color: p.textSecondary,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignChip extends StatelessWidget {
  const _SignChip({required this.label, required this.sign});
  final String label;
  final String sign;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: p.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            sign,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.content,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final String content;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(18),
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _AffirmationCard extends StatelessWidget {
  const _AffirmationCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: p.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: p.primary.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.format_quote_rounded,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              height: 1.5,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'TODAY\'S AFFIRMATION',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LuckyRow extends StatelessWidget {
  const _LuckyRow({required this.color, required this.number});

  final String color;
  final int number;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: p.glassBorder),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _parseColor(color),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _parseColor(color).withValues(alpha: 0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'LUCKY COLOR',
                  style: TextStyle(
                    color: p.textTertiary,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  color,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: p.glassBorder),
            ),
            child: Column(
              children: [
                Text(
                  '$number',
                  style: TextStyle(
                    color: p.gold,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'LUCKY NUMBER',
                  style: TextStyle(
                    color: p.textTertiary,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Resonant',
                  style: TextStyle(
                    color: p.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Color _parseColor(String name) {
    final map = {
      'red': Colors.red,
      'blue': Colors.blue,
      'green': Colors.green,
      'purple': Colors.purple,
      'gold': const Color(0xFFF4C542),
      'amethyst': const Color(0xFF9966CC),
      'amethyst purple': const Color(0xFF9966CC),
      'pink': Colors.pink,
      'orange': Colors.orange,
      'white': Colors.white,
      'silver': const Color(0xFFC0C0C0),
      'teal': Colors.teal,
      'indigo': Colors.indigo,
      'lavender': const Color(0xFFE6E6FA),
      'rose': const Color(0xFFE14B8A),
      'emerald': const Color(0xFF50C878),
    };
    return map[name.toLowerCase()] ?? const Color(0xFF7B61FF);
  }
}
