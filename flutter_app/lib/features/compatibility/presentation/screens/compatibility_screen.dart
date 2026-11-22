import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/core/error/error_message.dart';
import 'package:cosmic_mirror/core/network/api_endpoints.dart';
import 'package:cosmic_mirror/core/utils/string_utils.dart';
import 'package:cosmic_mirror/features/chart/presentation/astro_labels.dart';
import 'package:cosmic_mirror/features/compatibility/presentation/relationship_labels.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/lively/lively_backdrop.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:cosmic_mirror/shared/widgets/staggered_fade_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final savedPeopleProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(apiClientProvider);
  final data = await client.get<Map<String, dynamic>>(ApiEndpoints.people);
  final raw = data['people'] as List<dynamic>? ?? const [];
  return raw.cast<Map<String, dynamic>>();
});

/// Asks for confirmation, deletes the saved person and refreshes the list.
/// Returns true when the person was removed. Failures show a localized
/// snackbar.
Future<bool> confirmAndRemovePerson(
  BuildContext context,
  WidgetRef ref, {
  required String personId,
  String? name,
}) async {
  final p = context.palette;
  final l = AppLocalizations.of(context);
  final displayName =
      (name == null || name.trim().isEmpty) ? l.compatSomeone : name.trim();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        l.cmsCompatRemoveTitle(displayName),
        style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w700),
      ),
      content: Text(
        l.cmsCompatRemoveBody,
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
          child: Text(l.cmsCompatRemoveConfirm),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(apiClientProvider).delete(ApiEndpoints.person(personId));
  } catch (e) {
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(FriendlyError.from(context, e).body)),
      );
    }
    return false;
  }
  ref.invalidate(savedPeopleProvider);
  messenger.showSnackBar(
    SnackBar(content: Text(l.cmsCompatRemoved(displayName))),
  );
  return true;
}

class CompatibilityScreen extends ConsumerWidget {
  const CompatibilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peopleAsync = ref.watch(savedPeopleProvider);
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
        onPressed: () async {
          // Await the add flow, then refresh so a newly added person
          // shows up immediately instead of only after the autoDispose
          // provider is otherwise rebuilt.
          await context.push('/compatibility/add');
          if (context.mounted) ref.invalidate(savedPeopleProvider);
        },
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        icon: const Icon(Icons.person_add_rounded),
        label: Text(
          AppLocalizations.of(context).compatibilityAddPerson,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: LivelyBackdrop(
        seed: 27,
        intensity: 0.6,
        child: peopleAsync.when(
          loading: () => const ShimmerList(),
          error: (e, _) => ErrorView(
            error: e,
            onRetry: () => ref.invalidate(savedPeopleProvider),
          ),
          data: (people) {
            if (people.isEmpty) return _EmptyState();
            return ListView.separated(
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.paddingOf(context).top + kToolbarHeight + 12,
                20,
                100,
              ),
              itemCount: people.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return FadeSlideIn(
                    child: _Header(count: people.length),
                  );
                }
                final person = people[i - 1];
                final id = person['id']?.toString() ?? '';
                return FadeSlideIn(
                  delay: Duration(milliseconds: 80 + (i * 50).clamp(0, 400)),
                  child: Dismissible(
                    key: ValueKey('person-$id'),
                    direction: id.isEmpty
                        ? DismissDirection.none
                        : DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      decoration: BoxDecoration(
                        color: p.error.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: p.error.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: p.error,
                        size: 26,
                      ),
                    ),
                    // The list refresh (invalidate) removes the row; let
                    // the card snap back while the dialog is up.
                    confirmDismiss: (_) async {
                      await confirmAndRemovePerson(
                        context,
                        ref,
                        personId: id,
                        name: person['name'] as String?,
                      );
                      return false;
                    },
                    child: _PersonCard(person: person),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.compatibilityTitle,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.compatibilitySavedCount(count),
            style: TextStyle(color: p.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.person});
  final Map<String, dynamic> person;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rawName = (person['name'] as String?)?.trim() ?? '';
    final name = rawName.isEmpty ? '—' : rawName;
    final score = (person['compatibility_score'] as num?)?.toInt();
    final relation = (person['relationship'] as String?) ?? '';
    final sign = (person['sun_sign'] as String?) ?? '';
    final scoreColor = score == null
        ? p.textTertiary
        : score >= 75
            ? p.success
            : score >= 50
                ? p.gold
                : p.warning;

    return InkWell(
      onTap: () => context.push('/compatibility/${person['id']}'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.glassBorder),
        ),
        child: Row(
          children: [
            // Gradient avatar
            Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: p.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: p.surface,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  name.characters.first.toUpperCaseLocale(
                    Localizations.localeOf(context).languageCode,
                  ),
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (relation.isNotEmpty)
                        relationshipLabel(
                          AppLocalizations.of(context),
                          relation,
                        ),
                      if (sign.isNotEmpty)
                        chartSignName(AppLocalizations.of(context), sign),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (score != null) _ScoreRing(score: score, color: scoreColor),
          ],
        ),
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, required this.color});
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 3.5,
              backgroundColor: p.surfaceElevated,
              valueColor: AlwaysStoppedAnimation(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '$score',
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: p.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: p.primary.withValues(alpha: 0.3),
                    blurRadius: 22,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.favorite_rounded,
                color: p.onPrimary,
                size: 38,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).compatibilitySeeHow,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: p.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).compatibilityEmptyBlurb,
              style: TextStyle(
                color: p.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
