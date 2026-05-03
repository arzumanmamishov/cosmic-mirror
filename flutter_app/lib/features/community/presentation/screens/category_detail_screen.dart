import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/space_card.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Spaces filtered by a single category. We push the categoryId into the
/// existing `selectedCategoryIdProvider` on entry, then read `spacesProvider`
/// (which keys off it). On pop we clear the filter so the main list isn't
/// stuck on this category.
class CategoryDetailScreen extends ConsumerStatefulWidget {
  const CategoryDetailScreen({required this.categoryId, super.key});
  final String categoryId;

  @override
  ConsumerState<CategoryDetailScreen> createState() =>
      _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  String? _previousCategory;
  String? _previousQuery;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _previousCategory = ref.read(selectedCategoryIdProvider);
      _previousQuery = ref.read(spaceSearchQueryProvider);
      ref.read(selectedCategoryIdProvider.notifier).state = widget.categoryId;
      ref.read(spaceSearchQueryProvider.notifier).state = '';
    });
  }

  @override
  void dispose() {
    Future.microtask(() {
      ref.read(selectedCategoryIdProvider.notifier).state = _previousCategory;
      ref.read(spaceSearchQueryProvider.notifier).state =
          _previousQuery ?? '';
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final spacesAsync = ref.watch(spacesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final categoryName = categoriesAsync.maybeWhen(
      orElse: () => 'Category',
      data: (cats) => cats
          .firstWhere(
            (c) => c.id == widget.categoryId,
            orElse: () => cats.isNotEmpty
                ? cats.first
                : (throw StateError('no categories')),
          )
          .name,
    );

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
              message: e.toString(),
              onRetry: () => ref.invalidate(spacesProvider),
            ),
            data: (spaces) => spaces.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No spaces in this category yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: p.textSecondary, fontSize: 13),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 100, 20, 32),
                    itemCount: spaces.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => SpaceCard(space: spaces[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
