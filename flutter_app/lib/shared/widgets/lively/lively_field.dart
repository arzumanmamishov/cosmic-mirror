import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:flutter/material.dart';

/// Lively text field — an uppercase caption label above a rounded input
/// whose fill is the **page background** (per the design brief: no
/// contrasting fill). The border is a hairline that turns gold with a
/// soft focus ring when active.
class LivelyField extends StatefulWidget {
  const LivelyField({
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.trailing,
    this.obscure = false,
    this.large = false,
    this.autofocus = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? trailing;
  final bool obscure;
  final bool large;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<LivelyField> createState() => _LivelyFieldState();
}

class _LivelyFieldState extends State<LivelyField> {
  late final FocusNode _focus;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()..addListener(_onFocus);
  }

  void _onFocus() => setState(() => _focused = _focus.hasFocus);

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!.toUpperCase(),
            style: LivelyType.caption(p.textMuted).copyWith(letterSpacing: 1.1),
          ),
          const SizedBox(height: 8),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: widget.large ? 18 : 16,
            vertical: widget.large ? 6 : 4,
          ),
          decoration: BoxDecoration(
            color: p.background, // fill = page background, per brief
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _focused ? p.primary : p.line,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: p.primary.withValues(alpha: 0.18),
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              if (widget.prefixIcon != null) ...[
                Icon(widget.prefixIcon, color: p.textMuted, size: 18),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  autofocus: widget.autofocus,
                  obscureText: widget.obscure,
                  keyboardType: widget.keyboardType,
                  textCapitalization: widget.textCapitalization,
                  autofillHints: widget.autofillHints,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  cursorColor: p.primary,
                  style: widget.large
                      ? LivelyType.h1(p.textPrimary)
                      : LivelyType.h2(p.textPrimary)
                          .copyWith(fontWeight: FontWeight.w400),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: widget.large ? 14 : 14,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: (widget.large
                            ? LivelyType.h1(p.textDim)
                            : LivelyType.h2(p.textDim))
                        .copyWith(fontWeight: FontWeight.w400),
                  ),
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 8),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}
