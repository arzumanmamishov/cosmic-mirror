import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EditSpaceScreen extends ConsumerStatefulWidget {
  const EditSpaceScreen({required this.spaceId, super.key});
  final String spaceId;

  @override
  ConsumerState<EditSpaceScreen> createState() => _EditSpaceScreenState();
}

class _EditSpaceScreenState extends ConsumerState<EditSpaceScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  bool _busy = false;
  bool _initialized = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(communityRepositoryProvider).updateSpace(
            widget.spaceId,
            name: _name.text.trim(),
            description: _description.text.trim(),
          );
      ref.invalidate(spaceDetailProvider(widget.spaceId));
      ref.invalidate(spacesProvider);
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this space?'),
        content: const Text('All posts and comments will be permanently lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(communityRepositoryProvider).deleteSpace(widget.spaceId);
      ref.invalidate(spacesProvider);
      if (mounted) {
        context
          ..pop()
          ..pop();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final spaceAsync = ref.watch(spaceDetailProvider(widget.spaceId));

    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Edit Space'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _save,
            child: Text(
              _busy ? 'Saving…' : 'Save',
              style: TextStyle(
                color: p.primary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CosmicStarfield(
              color: p.textPrimary,
              starCount: 50,
              intensity: 0.6,
            ),
          ),
          spaceAsync.when(
            loading: () => const ShimmerList(itemCount: 3),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () =>
                  ref.invalidate(spaceDetailProvider(widget.spaceId)),
            ),
            data: (s) {
              if (!_initialized) {
                _name.text = s.space.name;
                _description.text = s.space.description ?? '';
                _initialized = true;
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 32),
                children: [
                  _readOnly(p, 'HANDLE', '@${s.space.handle}'),
                  const SizedBox(height: 14),
                  _editable(p, 'NAME', _name),
                  const SizedBox(height: 14),
                  _editable(p, 'DESCRIPTION', _description, maxLines: 4),
                  const SizedBox(height: 32),
                  TextButton.icon(
                    onPressed: _busy ? null : _delete,
                    style: TextButton.styleFrom(foregroundColor: p.error),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete space'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: TextStyle(color: p.error, fontSize: 12)),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _readOnly(AppPalette p, String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: p.textTertiary, fontSize: 14)),
        ],
      );

  Widget _editable(AppPalette p, String label, TextEditingController c,
          {int maxLines = 1}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.glassBorder),
            ),
            child: TextField(
              controller: c,
              maxLines: maxLines,
              style: TextStyle(color: p.textPrimary, fontSize: 14),
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
        ],
      );
}
