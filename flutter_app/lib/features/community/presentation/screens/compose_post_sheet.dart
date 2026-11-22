import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/core/error/error_message.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/compose_post_field.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modal bottom sheet for composing a new post in a space. Mirrors the
/// "What's on your mind?" composer in screenshot 2.
class ComposePostSheet extends ConsumerStatefulWidget {
  const ComposePostSheet({required this.spaceId, super.key});

  final String spaceId;

  @override
  ConsumerState<ComposePostSheet> createState() => _ComposePostSheetState();
}

class _ComposePostSheetState extends ConsumerState<ComposePostSheet> {
  final _content = TextEditingController();
  final _link = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Rebuild whenever the user types so the Post button enables/disables.
    _content.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _content
      ..removeListener(_onChanged)
      ..dispose();
    _link.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final text = _content.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(communityRepositoryProvider);
      await repo.createPost(
        spaceId: widget.spaceId,
        content: text,
        linkUrl: _link.text.trim().isEmpty ? null : _link.text.trim(),
      );
      // Pop with `true` so the caller only refetches on a real post.
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = FriendlyError.from(context, e).body);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    // Clear the keyboard when it's up, otherwise the home indicator.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottomInset = keyboard > safeBottom ? keyboard : safeBottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 18 + bottomInset),
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: p.glassBorder),
      ),
      // Scrollable so the 8-line composer + link row never overflow on a
      // small phone with the keyboard up.
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l.communityNewPostTitle,
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _busy ? null : _post,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: _content.text.trim().isEmpty
                        ? null
                        : p.primaryGradient,
                    color: _content.text.trim().isEmpty
                        ? p.surfaceElevated
                        : null,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _busy
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: p.onPrimary,
                          ),
                        )
                      : Text(
                          l.communityPostSubmit,
                          style: TextStyle(
                            color: _content.text.trim().isEmpty
                                ? p.textSecondary
                                : p.onPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ComposePostField(
            controller: _content,
            linkController: _link,
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: TextStyle(color: p.error, fontSize: 12),
            ),
          ],
        ],
        ),
      ),
    );
  }
}
