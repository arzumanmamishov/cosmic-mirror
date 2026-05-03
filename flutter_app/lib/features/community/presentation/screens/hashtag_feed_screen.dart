import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stub feed for posts with a particular hashtag. The backend doesn't yet
/// expose a "list posts by hashtag" endpoint — that's a future enhancement.
/// For v1 we render a placeholder that confirms the tag was received.
class HashtagFeedScreen extends ConsumerWidget {
  const HashtagFeedScreen({required this.tag, super.key});
  final String tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('#$tag'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CosmicStarfield(
              color: p.textPrimary,
              starCount: 40,
              intensity: 0.5,
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: p.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Posts by hashtag are coming soon.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For now, browse spaces and discover hashtags inside posts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.textSecondary, fontSize: 12),
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
