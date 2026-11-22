import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/core/utils/string_utils.dart';
import 'package:cosmic_mirror/features/life_timeline/data/life_timeline_data.dart';
import 'package:cosmic_mirror/features/life_timeline/data/life_timeline_storage.dart';
import 'package:cosmic_mirror/features/life_timeline/presentation/widgets/add_event_sheet.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:cosmic_mirror/shared/widgets/lively/lively_backdrop.dart';
import 'package:cosmic_mirror/shared/widgets/staggered_fade_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// LifeTimelineScreen — a vertical timeline of the user's life mapped against
/// the astrological transits that were active at each moment. The longer they
/// use Lively, the more irreplaceable this view becomes.
class LifeTimelineScreen extends ConsumerStatefulWidget {
  const LifeTimelineScreen({super.key});

  @override
  ConsumerState<LifeTimelineScreen> createState() => _LifeTimelineScreenState();
}

class _LifeTimelineScreenState extends ConsumerState<LifeTimelineScreen> {
  /// The user's own moments (persisted on device). Null while loading.
  List<LifeEvent>? _events;
  late final LifeTimelineStorage _storage =
      LifeTimelineStorage(ref.read(currentUserProvider).id);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await _storage.load();
    if (!mounted) return;
    setState(() {
      // Most recent first.
      _events = loaded..sort((a, b) => b.date.compareTo(a.date));
    });
  }

  Future<void> _persist() async {
    final ok = await _storage.save(_events ?? const []);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).errGenericBody),
        ),
      );
    }
  }

  Future<void> _addEvent() async {
    final newEvent = await showModalBottomSheet<LifeEvent>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddEventSheet(),
    );
    if (newEvent != null && mounted) {
      setState(() {
        _events = [...?_events, newEvent]
          ..sort((a, b) => b.date.compareTo(a.date));
      });
      await _persist();
    }
  }

  Future<void> _deleteEvent(LifeEvent event) async {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l.cmsLifeDeleteTitle,
          style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          l.cmsLifeDeleteBody(event.title),
          style: TextStyle(color: p.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel, style: TextStyle(color: p.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: p.error),
            child: Text(l.cmsLifeDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _events = [...?_events]..removeWhere((e) => e.id == event.id);
    });
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final own = _events ?? const <LifeEvent>[];
    // Until the user adds a moment, show the localized samples — clearly
    // labelled as examples rather than passed off as the user's own life.
    final showingExamples = _events != null && own.isEmpty;
    final events = showingExamples
        ? (mockLifeEvents(AppLocalizations.of(context))
          ..sort((a, b) => b.date.compareTo(a.date)))
        : own;

    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEvent,
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          AppLocalizations.of(context).lifeTimelineAddMoment,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: LivelyBackdrop(
        seed: 25,
        intensity: 0.6,
        child: _events == null
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
                  20,
                  100,
                ),
                itemCount: events.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return FadeSlideIn(
                      child: _Header(
                        count: own.length,
                        showingExamples: showingExamples,
                      ),
                    );
                  }
                  final event = events[i - 1];
                  final isFirst = i == 1;
                  final isLast = i == events.length;
                  return FadeSlideIn(
                    delay: Duration(
                      milliseconds: 80 + (i * 50).clamp(0, 400),
                    ),
                    child: GestureDetector(
                      // Long-press to delete one of the user's own moments.
                      onLongPress:
                          showingExamples ? null : () => _deleteEvent(event),
                      child: Opacity(
                        opacity: showingExamples ? 0.6 : 1,
                        child: _TimelineItem(
                          event: event,
                          isFirst: isFirst,
                          isLast: isLast,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// =================== Header ===================

class _Header extends StatelessWidget {
  const _Header({required this.count, this.showingExamples = false});
  final int count;
  final bool showingExamples;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              l.lifeTimelineMomentsMapped(count),
              style: TextStyle(
                color: p.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l.lifeTimelineHeaderTitle,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.lifeTimelineHeaderSubtitle,
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
          if (showingExamples) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.glassBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: p.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.cmsLifeExamplesBanner,
                      style: TextStyle(
                        color: p.textSecondary,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =================== Timeline item ===================

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.event,
    required this.isFirst,
    required this.isLast,
  });

  final LifeEvent event;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final color = event.category.color;
    final dateLabel = DateFormat(
      'MMM d, yyyy',
      Localizations.localeOf(context).toString(),
    ).format(event.date);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Spine: dot + connecting line
          SizedBox(
            width: 36,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: p.glassBorder,
                    ),
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
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: p.glassBorder,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Container(
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                event.category.icon,
                                color: color,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                event.category.label(l),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Spacer(),
                        Text(
                          dateLabel,
                          style: TextStyle(
                            color: p.textTertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      event.title,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (event.mood != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.lens_blur_rounded,
                            size: 12,
                            color: p.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l.lifeTimelineFelt(
                              lifeEventMoodLabel(l, event.mood!)
                                  .toLowerCaseLocale(
                                Localizations.localeOf(context).languageCode,
                              ),
                            ),
                            style: TextStyle(
                              color: p.textTertiary,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (event.description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        event.description,
                        style: TextStyle(
                          color: p.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                    if (event.transits.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _TransitStrip(transits: event.transits),
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

class _TransitStrip extends StatelessWidget {
  const _TransitStrip({required this.transits});
  final List<String> transits;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            p.primary.withValues(alpha: 0.10),
            p.accent.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 13,
                color: p.primary,
              ),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).lifeTimelineWhatSky,
                style: TextStyle(
                  color: p.primary,
                  fontSize: 9,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...transits.map(
            (t) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '·  ',
                    style: TextStyle(
                      color: p.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      t,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
