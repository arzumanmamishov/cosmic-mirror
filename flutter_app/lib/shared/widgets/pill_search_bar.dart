import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kGold = Color(0xFFD4B16A);
const _kSurface = Color(0xFF1A1F2E);
const _kBorder = Color(0xFF2A2F3E);
const _kTextPrimary = Colors.white;
const _kTextTertiary = Color(0xFF7E8290);

/// Universal pill-shaped search field. Uses the same dark surface +
/// subtle outline as auth and onboarding inputs, so every search field
/// across the app reads as the same component (single shape, single
/// color, no inherited Material InputDecorationTheme bleed).
class PillSearchBar extends StatelessWidget {
  const PillSearchBar({
    required this.hint,
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.trailing,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool readOnly;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          const SizedBox(width: 18),
          const Icon(Icons.search_rounded, color: _kTextTertiary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              onTap: onTap,
              readOnly: readOnly,
              cursorColor: _kGold,
              style: GoogleFonts.poppins(
                color: _kTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                hoverColor: Colors.transparent,
                focusColor: Colors.transparent,
                hintText: hint,
                hintStyle: GoogleFonts.poppins(
                  color: _kTextTertiary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: trailing,
            ),
          ] else
            const SizedBox(width: 16),
        ],
      ),
    );
  }
}
