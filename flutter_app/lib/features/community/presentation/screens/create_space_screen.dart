import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateSpaceScreen extends ConsumerStatefulWidget {
  const CreateSpaceScreen({super.key});

  @override
  ConsumerState<CreateSpaceScreen> createState() => _CreateSpaceScreenState();
}

class _CreateSpaceScreenState extends ConsumerState<CreateSpaceScreen> {
  final _name = TextEditingController();
  final _handle = TextEditingController();
  final _description = TextEditingController();
  String? _selectedCategoryId;
  bool _isSpicy = false;
  bool _busy = false;
  String? _error;

  bool get _canSave =>
      _name.text.trim().isNotEmpty && _handle.text.trim().length >= 3;

  @override
  void dispose() {
    _name.dispose();
    _handle.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_canSave || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(communityRepositoryProvider);
      final space = await repo.createSpace(
        handle: _handle.text.trim().toLowerCase(),
        name: _name.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        categoryId: _selectedCategoryId,
        isSpicy: _isSpicy,
      );
      ref.invalidate(spacesProvider);
      if (mounted) {
        context
          ..pop()
          ..push('/community/${space.id}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final categoriesAsync = ref.watch(categoriesProvider);
    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('New Space'),
        actions: [
          TextButton(
            onPressed: _canSave && !_busy ? _save : null,
            child: Text(
              _busy ? 'Saving…' : 'Create',
              style: TextStyle(
                color: _canSave ? p.primary : p.textTertiary,
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
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 32),
            children: [
              _Field(
                label: 'Name',
                controller: _name,
                hint: 'e.g. Stargazers Club',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              _Field(
                label: 'Handle',
                controller: _handle,
                hint: 'stargazers',
                prefix: '@',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              _Field(
                label: 'Description',
                controller: _description,
                hint: 'What is this space about?',
                maxLines: 4,
              ),
              const SizedBox(height: 18),
              Text(
                'CATEGORY',
                style: TextStyle(
                  color: p.textSecondary,
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              categoriesAsync.maybeWhen(
                orElse: () => const SizedBox.shrink(),
                data: (cats) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in cats)
                      GestureDetector(
                        onTap: () => setState(() {
                          _selectedCategoryId =
                              _selectedCategoryId == c.id ? null : c.id;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: _selectedCategoryId == c.id
                                ? p.primaryGradient
                                : null,
                            color: _selectedCategoryId == c.id
                                ? null
                                : p.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: p.glassBorder),
                          ),
                          child: Text(
                            c.name,
                            style: TextStyle(
                              color: _selectedCategoryId == c.id
                                  ? Colors.white
                                  : p.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isSpicy,
                onChanged: (v) => setState(() => _isSpicy = v),
                title: Text(
                  'Spicy',
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  'Mature topics — shown with a Spicy badge.',
                  style: TextStyle(color: p.textSecondary, fontSize: 12),
                ),
                activeColor: p.warning,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: p.error, fontSize: 12)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.prefix,
    this.maxLines = 1,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? prefix;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (prefix != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 14, right: 4),
                  child: Text(
                    prefix!,
                    style: TextStyle(
                      color: p.textTertiary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: maxLines,
                  onChanged: onChanged,
                  style: TextStyle(color: p.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: p.textTertiary, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
