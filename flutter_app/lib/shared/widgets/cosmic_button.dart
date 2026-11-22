import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:flutter/material.dart';

class CosmicButton extends StatelessWidget {
  const CosmicButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.icon,
    this.gradient = true,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool gradient;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    // Palette-driven so the label stays readable in both themes (the old
    // fixed cream text vanished on the light theme and on a disabled,
    // transparent gradient button).
    final p = context.palette;
    final filled = gradient && onPressed != null;
    final fg = filled
        ? p.onPrimary
        : onPressed == null
            ? p.textTertiary
            : p.textPrimary;
    final child = Container(
      padding: fullWidth ? null : const EdgeInsets.symmetric(horizontal: 24),
      width: fullWidth ? double.infinity : null,
      height: 52,
      decoration: filled
          ? BoxDecoration(
              gradient: p.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: p.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : null,
      child: Material(
        color: filled ? Colors.transparent : p.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(fg),
                    ),
                  )
                : Row(
                    mainAxisSize:
                        fullWidth ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20, color: fg),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: fg,
                          ),
                        ),
                      ),
                      if (!fullWidth && icon != null)
                        const SizedBox(width: 8),
                    ],
                  ),
          ),
        ),
      ),
    );

    return child;
  }
}

class CosmicOutlinedButton extends StatelessWidget {
  const CosmicOutlinedButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: context.palette.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}
