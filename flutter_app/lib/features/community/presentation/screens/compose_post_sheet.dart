import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/compose_post_field.dart';
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
  void dispose() {
    _content.dispose();
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
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 18 + bottomInset),
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: p.glassBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'New post',
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
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Post',
                          style: TextStyle(
                            color: _content.text.trim().isEmpty
                                ? p.textSecondary
                                : Colors.white,
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
    );
  }
}
