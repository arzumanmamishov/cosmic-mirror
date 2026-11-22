import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/space_card.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Spaces filtered by a single category. Reads its own
/// [categorySpacesProvider] family: the old approach rewrote the global
/// category / search filters on entry and restored them on dispose, which
/// briefly showed unfiltered spaces, inherited the All/Joined toggle, and
/// wiped the main list's search while this screen was open.
class CategoryDetailScreen extends ConsumerStatefulWidget {
  const CategoryDetailScreen({required this.categoryId, super.key});
  final String categoryId;

  @override
  ConsumerState<CategoryDetailScreen> createState() =>
      _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final spacesProvider = categorySpacesProvider(widget.categoryId);
    final spacesAsync = ref.watch(spacesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    // Unknown id / empty list → generic title (previously showed another
    // category's name, or threw while building).
    final categoryName = categoriesAsync.maybeWhen(
      orElse: () => l.communityCategoryFallback,
      data: (cats) {
        for (final c in cats) {
          if (c.id == widget.categoryId) return c.name;
        }
        return l.communityCategoryFallback;
      },
    );
    // The app bar is transparent over the body; keep content below it.
    final topPad = MediaQuery.paddingOf(context).top + kToolbarHeight + 12;
    Future<void> refresh() async {
      ref.invalidate(spacesProvider);
      try {
        await ref.read(spacesProvider.future);
      } catch (_) {/* shown by the error state */}
    }

    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(categoryName),
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
          spacesAsync.when(
            loading: () => const ShimmerList(itemCount: 4),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () => ref.invalidate(spacesProvider),
            ),
            data: (spaces) => RefreshIndicator(
              color: p.primary,
              backgroundColor: p.surface,
              edgeOffset: topPad,
              onRefresh: refresh,
              child: spaces.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(32, topPad + 80, 32, 32),
                      children: [
                        Text(
                          l.communityCategoryEmpty,
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: p.textSecondary, fontSize: 13),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(20, topPad, 20, 32),
                      itemCount: spaces.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => SpaceCard(
                        key: ValueKey(spaces[i].space.id),
                        space: spaces[i],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
