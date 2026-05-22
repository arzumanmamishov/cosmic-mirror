import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:flutter/material.dart';

/// The Lively primary call-to-action — a gold pill with an inner top
/// highlight and a soft outer glow. Press shrinks it to 0.97.
///
/// [ghost] renders a transparent variant with a gold hairline border —
/// used for secondary actions.
class GoldButton extends StatefulWidget {
  const GoldButton({
    required this.label,
    required this.onPressed,
    this.full = true,
    this.small = false,
    this.ghost = false,
    this.loading = false,
    this.trailingArrow = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool full;
  final bool small;
  final bool ghost;
  final bool loading;

  /// Draws a "→" after the label (used on onboarding / welcome CTAs).
  final bool trailingArrow;

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final disabled = widget.onPressed == null || widget.loading;
    final fg = widget.ghost ? p.primary : p.onPrimary;

    final padding = widget.small
        ? const EdgeInsets.symmetric(horizontal: 18, vertical: 11)
        : const EdgeInsets.symmetric(horizontal: 22, vertical: 16);

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _down = true),
      onTapUp: disabled ? null : (_) => setState(() => _down = false),
      onTapCancel: disabled ? null : () => setState(() => _down = false),
      onTap: disabled ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Opacity(
          opacity: disabled && !widget.loading ? 0.5 : 1.0,
          child: Container(
            width: widget.full ? double.infinity : null,
            padding: padding,
            decoration: BoxDecoration(
              color: widget.ghost ? Colors.transparent : p.primary,
              borderRadius: BorderRadius.circular(999),
              border: widget.ghost
                  ? Border.all(color: p.glassBorder)
                  : Border.all(color: p.primaryHi.withValues(alpha: 0.9), width: 0.8),
              boxShadow: widget.ghost
                  ? null
                  : [
                      BoxShadow(
                        color: p.primary.withValues(alpha: 0.22),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: widget.full ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.loading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation(fg),
                    ),
                  )
                else ...[
                  Text(
                    widget.label,
                    style: LivelyType.button(
                      fg,
                      size: widget.small ? 14 : 16,
                    ),
                  ),
                  if (widget.trailingArrow) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, color: fg, size: 18),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
