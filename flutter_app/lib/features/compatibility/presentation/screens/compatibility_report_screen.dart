import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/core/network/api_endpoints.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_pulse.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:cosmic_mirror/shared/widgets/staggered_fade_in.dart';

final compatibilityReportProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, personId) async {
  final client = ref.read(apiClientProvider);
  return client.get<Map<String, dynamic>>(
    ApiEndpoints.compatibility(personId),
  );
});

class CompatibilityReportScreen extends ConsumerWidget {
  const CompatibilityReportScreen({required this.personId, super.key});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(compatibilityReportProvider(personId));
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
              final report = reportAsync.valueOrNull;
              if (report != null) {
                final name = report['person_name'] as String? ?? 'Someone';
                final score = (report['overall_score'] as num?)?.toInt() ?? 0;
                Share.share(
                  'My cosmic compatibility with $name is $score%! '
                  'Check yours on Lively.',
                );
              }
            },
          ),
        ],
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
          reportAsync.when(
            loading: () => const ShimmerList(itemCount: 4),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () =>
                  ref.invalidate(compatibilityReportProvider(personId)),
            ),
            data: (report) => _ReportBody(report: report),
          ),
        ],
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report});
  final Map<String, dynamic> report;

  @override
  Widget build(BuildContext context) {
    final name = report['person_name'] as String? ?? 'Someone';
    final overall = (report['overall_score'] as num?)?.toInt() ?? 0;
    final emotional = (report['emotional_score'] as num?)?.toInt() ?? 0;
    final communication =
        (report['communication_score'] as num?)?.toInt() ?? 0;
    final chemistry = (report['chemistry_score'] as num?)?.toInt() ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 90, 20, 40),
      children: [
        FadeSlideIn(
          child: _Hero(name: name, overallScore: overall),
        ),
        const SizedBox(height: 24),
        FadeSlideIn(
          delay: const Duration(milliseconds: 120),
          child: _ScoreRow(
            emotional: emotional,
            communication: communication,
            chemistry: chemistry,
          ),
        ),
        const SizedBox(height: 24),
        if (report['summary'] != null) ...[
          FadeSlideIn(
            delay: const Duration(milliseconds: 180),
            child: _ReportSection(
              title: 'Summary',
              icon: Icons.auto_awesome_rounded,
              iconColor: const Color(0xFF7B61FF),
              content: report['summary'] as String,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (report['conflict_patterns'] != null) ...[
          FadeSlideIn(
            delay: const Duration(milliseconds: 240),
            child: _ReportSection(
              title: 'Conflict Patterns',
              icon: Icons.bolt_rounded,
              iconColor: const Color(0xFFF07C82),
              content: report['conflict_patterns'] as String,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (report['advice'] != null) ...[
          FadeSlideIn(
            delay: const Duration(milliseconds: 300),
            child: _ReportSection(
              title: 'Advice',
              icon: Icons.lightbulb_rounded,
              iconColor: const Color(0xFFB8860B),
              content: report['advice'] as String,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

// =================== Hero ===================

class _Hero extends StatelessWidget {
  const _Hero({required this.name, required this.overallScore});

  final String name;
  final int overallScore;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = overallScore >= 75
        ? p.success
        : overallScore >= 50
            ? p.gold
            : p.warning;
    return Column(
      children: [
        // Two-circle avatar with cosmic pulse between
        SizedBox(
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CosmicPulse(
                color: p.primary,
                maxRadius: 80,
                duration: const Duration(seconds: 4),
                child: const SizedBox(width: 0, height: 0),
              ),
              Positioned(
                left: MediaQuery.sizeOf(context).width / 2 - 90,
                child: _Avatar(label: 'You', glyph: '☉'),
              ),
              Positioned(
                right: MediaQuery.sizeOf(context).width / 2 - 90,
                child: _Avatar(label: name, glyph: '☽'),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: color, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$overallScore',
                      style: TextStyle(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '%',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'You & $name',
          style: TextStyle(
            color: p.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _qualitativeLabel(overallScore),
          style: TextStyle(
            color: p.textSecondary,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  static String _qualitativeLabel(int score) {
    if (score >= 85) return 'A magnetic alignment';
    if (score >= 70) return 'Easy, generative energy';
    if (score >= 55) return 'Worth the work';
    if (score >= 40) return 'Friction with potential';
    return 'A study in opposites';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.label, required this.glyph});
  final String label;
  final String glyph;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: p.primaryGradient,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: p.surface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              glyph,
              style: TextStyle(
                color: p.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: p.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// =================== Score row ===================

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.emotional,
    required this.communication,
    required this.chemistry,
  });

  final int emotional;
  final int communication;
  final int chemistry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ScoreCard(
            label: 'Emotional',
            score: emotional,
            color: const Color(0xFFE14B8A),
            icon: Icons.favorite_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ScoreCard(
            label: 'Communication',
            score: communication,
            color: const Color(0xFF7B61FF),
            icon: Icons.forum_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ScoreCard(
            label: 'Chemistry',
            score: chemistry,
            color: const Color(0xFFB8860B),
            icon: Icons.auto_fix_high_rounded,
          ),
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.label,
    required this.score,
    required this.color,
    required this.icon,
  });

  final String label;
  final int score;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.glassBorder),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    backgroundColor: p.surfaceElevated,
                    valueColor: AlwaysStoppedAnimation(color),
                    strokeWidth: 4,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Icon(icon, color: color, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$score',
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: p.textTertiary,
              fontSize: 10,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// =================== Report section ===================

class _ReportSection extends StatelessWidget {
  const _ReportSection({
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
