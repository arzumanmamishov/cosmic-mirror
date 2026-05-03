import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/life_timeline/data/life_timeline_data.dart';
import 'package:cosmic_mirror/features/life_timeline/presentation/widgets/add_event_sheet.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:cosmic_mirror/shared/widgets/staggered_fade_in.dart';

/// LifeTimelineScreen — a vertical timeline of the user's life mapped against
/// the astrological transits that were active at each moment. The longer they
/// use Lively, the more irreplaceable this view becomes.
class LifeTimelineScreen extends StatefulWidget {
  const LifeTimelineScreen({super.key});

  @override
  State<LifeTimelineScreen> createState() => _LifeTimelineScreenState();
}

class _LifeTimelineScreenState extends State<LifeTimelineScreen> {
  late List<LifeEvent> _events;

  @override
  void initState() {
    super.initState();
    // Most recent first
    _events = [...mockLifeEvents]..sort((a, b) => b.date.compareTo(a.date));
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
        _events = [..._events, newEvent]
          ..sort((a, b) => b.date.compareTo(a.date));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

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
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Moment',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CosmicStarfield(
              color: p.textPrimary,
              starCount: 60,
              intensity: 0.7,
            ),
          ),
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 90, 20, 100),
            itemCount: _events.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return FadeSlideIn(child: _Header(count: _events.length));
              }
              final event = _events[i - 1];
              final isFirst = i == 1;
              final isLast = i == _events.length;
              return FadeSlideIn(
                delay: Duration(milliseconds: 80 + i * 50),
                child: _TimelineItem(
                  event: event,
                  isFirst: isFirst,
                  isLast: isLast,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// =================== Header ===================

class _Header extends StatelessWidget {
  const _Header({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
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
              '$count moments mapped',
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
            'Your Cosmic Timeline',
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your life mapped against the sky.\n'
            'Add moments. See what was happening above.',
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
    final color = event.category.color;
    final dateLabel = DateFormat('MMM d, yyyy').format(event.date);

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
                                event.category.label,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                            'felt ${event.mood!.toLowerCase()}',
                            style: TextStyle(
                              color: p.textTertiary,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      event.description,
                      style: TextStyle(
                        color: p.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
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
                'WHAT THE SKY WAS DOING',
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
