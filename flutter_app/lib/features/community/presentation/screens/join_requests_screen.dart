import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/community/domain/entities/space.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Owner-only inbox of pending join requests for one space. Backend
/// returns 403 if the viewer isn't the owner — that bubbles through as
/// a provider error and ErrorView renders a "Members-only" message.
class JoinRequestsScreen extends ConsumerWidget {
  const JoinRequestsScreen({required this.spaceId, super.key});

  final String spaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final requestsAsync = ref.watch(spaceJoinRequestsProvider(spaceId));

    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: Text(l.spaceRequestsTitle),
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
          requestsAsync.when(
            loading: () => const ShimmerList(itemCount: 4),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () =>
                  ref.invalidate(spaceJoinRequestsProvider(spaceId)),
            ),
            data: (requests) {
              if (requests.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Text(
                      l.spaceRequestsEmpty,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.textSecondary, fontSize: 14),
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(spaceJoinRequestsProvider(spaceId));
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 100, 20, 32),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _RequestTile(
                    spaceId: spaceId,
                    request: requests[i],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends ConsumerStatefulWidget {
  const _RequestTile({required this.spaceId, required this.request});

  final String spaceId;
  final SpaceMember request;

  @override
  ConsumerState<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends ConsumerState<_RequestTile> {
  bool _busy = false;

  Future<void> _act({required bool accept}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final repo = ref.read(communityRepositoryProvider);
    try {
      if (accept) {
        await repo.approveJoinRequest(widget.spaceId, widget.request.userId);
      } else {
        await repo.declineJoinRequest(widget.spaceId, widget.request.userId);
      }
      // Drop the row optimistically by refetching the list. Refetch also
      // covers concurrent owner action from a second device.
      ref.invalidate(spaceJoinRequestsProvider(widget.spaceId));
      // Member count (and is_joined for the requester) changes on approve,
      // so blow away the space detail cache too.
      if (accept) {
        ref.invalidate(spaceDetailProvider(widget.spaceId));
        ref.invalidate(spaceMembersProvider(widget.spaceId));
      }
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final m = widget.request;
    final initial = m.userName.isNotEmpty ? m.userName[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: p.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              m.userName.isEmpty ? '—' : m.userName,
              style: TextStyle(
                color: p.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_busy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            _ActionButton(
              label: l.spaceRequestsDecline,
              primary: false,
              onPressed: () => _act(accept: false),
            ),
            const SizedBox(width: 6),
            _ActionButton(
              label: l.spaceRequestsAccept,
              primary: true,
              onPressed: () => _act(accept: true),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.primary,
    required this.onPressed,
  });

  final String label;
  final bool primary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: primary ? p.primaryGradient : null,
          color: primary ? null : p.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primary ? Colors.transparent : p.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: primary ? Colors.white : p.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
