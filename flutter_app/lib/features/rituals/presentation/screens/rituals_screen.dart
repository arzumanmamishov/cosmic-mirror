import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:cosmic_mirror/core/error/error_message.dart';
import 'package:cosmic_mirror/features/rituals/presentation/providers/rituals_provider.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/widgets/premium_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RitualsScreen extends ConsumerStatefulWidget {
  const RitualsScreen({super.key});

  @override
  ConsumerState<RitualsScreen> createState() => _RitualsScreenState();
}

class _RitualsScreenState extends ConsumerState<RitualsScreen> {
  /// Ritual types with a completion request in flight — guards against
  /// double-taps posting the same completion twice.
  final Set<String> _pending = {};

  Future<void> _complete(String type) async {
    if (_pending.contains(type)) return;
    setState(() => _pending.add(type));
    try {
      await completeRitual(ref, type);
    } catch (e) {
      // Used to fail silently (unawaited future); tell the user.
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(FriendlyError.from(context, e).body)),
          );
      }
    } finally {
      if (mounted) setState(() => _pending.remove(type));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final todayAsync = ref.watch(ritualsTodayProvider);
    final today = todayAsync.valueOrNull;

    bool done(String type) => today?.isCompleted(type) ?? false;

    Widget card({
      required String type,
      required String title,
      required String description,
      required IconData icon,
      required Color color,
    }) {
      return _RitualCard(
        title: title,
        description: description,
        icon: icon,
        color: color,
        isCompleted: done(type),
        isBusy: _pending.contains(type),
        // Not tappable until today's state is known, so a completed
        // ritual can't be re-posted while loading.
        onComplete: today == null ? null : () => _complete(type),
      );
    }

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        title: Text(l.ritualsTitle),
      ),
      body: PremiumGate(
        featureName: l.ritualsDailyRitualsFeature,
        child: RefreshIndicator(
          color: p.primary,
          onRefresh: () => ref.refresh(ritualsTodayProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.ritualsTodayHeading,
                  style: LivelyType.h1(p.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  l.ritualsTodaySubtitle,
                  style: LivelyType.small(p.textMuted),
                ),
                if (today != null && today.streak > 0) ...[
                  const SizedBox(height: 10),
                  Text(
                    l.ritualsStreak(today.streak),
                    style: LivelyType.small(p.primary)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
                if (todayAsync.isLoading && today == null) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    color: p.primary,
                    backgroundColor: p.line,
                  ),
                ],
                if (todayAsync.hasError && !todayAsync.isLoading) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          FriendlyError.from(context, todayAsync.error).body,
                          style: LivelyType.small(p.error),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(ritualsTodayProvider),
                        child: Text(l.errRetry),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                card(
                  type: 'morning_intention',
                  title: l.ritualMorningTitle,
                  description: l.ritualMorningDesc,
                  icon: Icons.wb_sunny_outlined,
                  color: p.gold,
                ),
                const SizedBox(height: 12),
                card(
                  type: 'affirmation',
                  title: l.ritualAffirmationTitle,
                  description: l.ritualAffirmationDesc,
                  icon: Icons.auto_awesome,
                  color: p.primary,
                ),
                const SizedBox(height: 12),
                card(
                  type: 'evening_reflection',
                  title: l.ritualEveningTitle,
                  description: l.ritualEveningDesc,
                  icon: Icons.nightlight_round,
                  color: p.accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RitualCard extends StatelessWidget {
  const _RitualCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isCompleted,
    required this.isBusy,
    required this.onComplete,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isCompleted;
  final bool isBusy;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    // Palette-driven card: the old CosmicCard / CosmicTypography pair was
    // dark-only, so headings rendered cream-on-white in the light theme.
    final p = context.palette;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isCompleted || isBusy ? null : onComplete,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.glassBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isCompleted ? 0.05 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: isBusy
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    : Icon(
                        isCompleted ? Icons.check_circle : icon,
                        color: isCompleted ? p.success : color,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: LivelyType.h2(p.textPrimary).copyWith(
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(description, style: LivelyType.small(p.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
