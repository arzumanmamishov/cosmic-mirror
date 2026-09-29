import 'dart:async';

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_tokens.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:cosmic_mirror/config/theme/macos_colors.dart';
import 'package:cosmic_mirror/core/error/error_message.dart';
import 'package:cosmic_mirror/features/community/domain/entities/space.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/category_card.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/widgets/lively/gold_button.dart';
import 'package:cosmic_mirror/shared/widgets/lively/lively_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// New-space form. A live preview card at the top mirrors what the space
/// will look like in the Community list while the user types; the Create
/// button is pinned above the keyboard.
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

  /// True once the user types in the handle field themselves — until then
  /// the handle is derived from the name.
  bool _handleEdited = false;

  bool get _canSave =>
      _name.text.trim().isNotEmpty && _handle.text.trim().length >= 3;

  @override
  void dispose() {
    _name.dispose();
    _handle.dispose();
    _description.dispose();
    super.dispose();
  }

  static String _slugify(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp('[^a-z0-9_]'), '')
      .replaceAll(RegExp('_+'), '_');

  void _onNameChanged(String v) {
    if (!_handleEdited) _handle.text = _slugify(v.trim());
    setState(() {});
  }

  Future<void> _save() async {
    if (!_canSave || _busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(communityRepositoryProvider);
      final space = await repo.createSpace(
        handle: _handle.text.trim().toLowerCase(),
        name: _name.text.trim(),
        description:
            _description.text.trim().isEmpty ? null : _description.text.trim(),
        categoryId: _selectedCategoryId,
        isSpicy: _isSpicy,
      );
      ref.invalidate(spacesProvider);
      if (mounted) {
        context.pop();
        unawaited(context.push('/community/${space.id}'));
      }
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
    final categoriesAsync = ref.watch(categoriesProvider);
    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: p.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: LivelyBackdrop(
        seed: 23,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
                  children: [
                    Text(
                      l.communityNewSpace,
                      style: LivelyType.d2(p.textPrimary),
                    ),
                    const SizedBox(height: 20),
                    _PreviewCard(
                      name: _name.text.trim(),
                      nameHint: l.spaceNameHint,
                      handle: _handle.text.trim(),
                      handleHint: l.spaceHandleHint,
                      description: _description.text.trim(),
                      isSpicy: _isSpicy,
                    ),
                    const SizedBox(height: 28),
                    _Field(
                      label: l.editSpaceNameLabel,
                      controller: _name,
                      hint: l.spaceNameHint,
                      textCapitalization: TextCapitalization.words,
                      onChanged: _onNameChanged,
                    ),
                    const SizedBox(height: 16),
                    _Field(
                      label: l.editSpaceHandleLabel,
                      controller: _handle,
                      hint: l.spaceHandleHint,
                      prefix: '@',
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp('[a-zA-Z0-9_]'),
                        ),
                        LowerCaseTextFormatter(),
                      ],
                      onChanged: (_) => setState(() => _handleEdited = true),
                    ),
                    const SizedBox(height: 16),
                    _Field(
                      label: l.editSpaceDescLabel,
                      controller: _description,
                      hint: l.spaceDescriptionHint,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => setState(() {}),
                    ),
                    categoriesAsync.maybeWhen(
                      orElse: () => const SizedBox.shrink(),
                      data: (cats) => cats.isEmpty
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _Label(l.spaceCategoryLabel),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final c in cats)
                                        _CategoryChip(
                                          category: c,
                                          selected: _selectedCategoryId == c.id,
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            setState(() {
                                              _selectedCategoryId =
                                                  _selectedCategoryId == c.id
                                                      ? null
                                                      : c.id;
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),
                    _SpicyToggle(
                      value: _isSpicy,
                      onChanged: (v) => setState(() => _isSpicy = v),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!, style: LivelyType.small(p.error)),
                    ],
                  ],
                ),
              ),
              // Pinned CTA — sits above the keyboard (the Scaffold resizes).
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: GoldButton(
                  label: l.spaceCreateAction,
                  loading: _busy,
                  onPressed: _canSave && !_busy ? _save : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Live preview of the space as it will appear in the Community list.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.name,
    required this.nameHint,
    required this.handle,
    required this.handleHint,
    required this.description,
    required this.isSpicy,
  });

  final String name;
  final String nameHint;
  final String handle;
  final String handleHint;
  final String description;
  final bool isSpicy;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final hue = MacOSColors.of(context).hueFor(name.isEmpty ? nameHint : name);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return AnimatedContainer(
      duration: LivelyMotion.quick,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(LivelyRadius.xl),
        border: Border.all(color: p.line),
        gradient: LinearGradient(
          colors: [hue.withValues(alpha: 0.14), p.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: LivelyMotion.quick,
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(LivelyRadius.lg),
                  gradient: LinearGradient(
                    colors: [hue.withValues(alpha: 0.85), hue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name.isEmpty ? nameHint : name,
                            style: LivelyType.h2(
                              name.isEmpty ? p.textDim : p.textPrimary,
                            ).copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSpicy) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: p.warning.withValues(alpha: 0.16),
                              borderRadius:
                                  BorderRadius.circular(LivelyRadius.full),
                            ),
                            child: Text(
                              l.spaceSpicyLabel,
                              style: TextStyle(
                                color: p.warning,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${handle.isEmpty ? handleHint : handle}',
                      style: LivelyType.small(
                        handle.isEmpty ? p.textDim : p.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: LivelyType.small(p.textMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: LivelyType.kicker(context.palette.textMuted),
      );
}

class _Field extends StatefulWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.prefix,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? prefix;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final focused = _focus.hasFocus;
    final style = LivelyType.body(p.textPrimary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(widget.label),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: LivelyMotion.quick,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(LivelyRadius.lg),
            border: Border.all(
              color: focused ? p.primary.withValues(alpha: 0.7) : p.line,
            ),
            boxShadow: [
              if (focused)
                BoxShadow(
                  color: p.primary.withValues(alpha: 0.12),
                  blurRadius: 12,
                ),
            ],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            maxLines: widget.maxLines,
            minLines: 1,
            textCapitalization: widget.textCapitalization,
            inputFormatters: widget.inputFormatters,
            onChanged: widget.onChanged,
            cursorColor: p.primary,
            style: style,
            scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: style.copyWith(color: p.textDim),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              prefixIcon: widget.prefix == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Text(
                        widget.prefix!,
                        style: style.copyWith(
                          color: focused ? p.primary : p.textDim,
                        ),
                      ),
                    ),
              prefixIconConstraints: const BoxConstraints(),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final SpaceCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hue = MacOSColors.of(context).hueFor(category.name);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: LivelyMotion.quick,
        padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
        decoration: BoxDecoration(
          color: selected ? hue.withValues(alpha: 0.16) : p.surface,
          borderRadius: BorderRadius.circular(LivelyRadius.full),
          border: Border.all(color: selected ? hue : p.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : CategoryCard.iconFor(category.icon),
              size: 16,
              color: hue,
            ),
            const SizedBox(width: 6),
            Text(
              category.name,
              style: LivelyType.small(selected ? p.textPrimary : p.textMuted)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpicyToggle extends StatelessWidget {
  const _SpicyToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(LivelyRadius.lg),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(LivelyRadius.lg),
        child: AnimatedContainer(
          duration: LivelyMotion.quick,
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LivelyRadius.lg),
            border: Border.all(
              color: value ? p.warning.withValues(alpha: 0.6) : p.line,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.warning.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(LivelyRadius.md),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: p.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.spaceSpicyLabel,
                      style: LivelyType.body(p.textPrimary)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      l.spaceSpicyDescription,
                      style: LivelyType.small(p.textMuted),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeTrackColor: p.warning,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Forces handle input to lowercase as the user types.
class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      newValue.copyWith(text: newValue.text.toLowerCase());
}
