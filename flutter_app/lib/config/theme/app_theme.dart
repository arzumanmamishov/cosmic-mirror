import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:flutter/material.dart';

class CosmicTheme {
  CosmicTheme._();

  static ThemeData get darkTheme => _build(AppPalette.dark, Brightness.dark);
  static ThemeData get lightTheme => _build(AppPalette.light, Brightness.light);

  // Brand gold — used for text selection / cursor / handles so the
  // platform's default blue/purple selection chrome never leaks through.
  static const _gold = Color(0xFFD4B16A);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final baseTextTheme = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.background,
      extensions: [p],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: p.primary,
        // primary is gold in both themes — its foreground must be the
        // dark ink token, not white.
        onPrimary: p.onPrimary,
        secondary: p.accent,
        onSecondary: p.onPrimary,
        surface: p.surface,
        onSurface: p.textPrimary,
        error: p.error,
        onError: const Color(0xFFFFFFFF),
        surfaceContainerHighest: p.surfaceElevated,
        outline: p.glassBorder,
      ),
      // Bundled Geist family applied across the whole text theme — every
      // raw Text widget inherits the design-system UI font.
      textTheme: baseTextTheme.apply(
        fontFamily: 'Geist',
        bodyColor: p.textPrimary,
        displayColor: p.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: p.textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: 'Geist',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: p.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.glassBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: p.glassBorder),
          textStyle: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: _gold,
        selectionColor: _gold.withValues(alpha: 0.35),
        selectionHandleColor: _gold,
      ),
      // Neutral InputDecorationTheme — no fill, no border, transparent
      // hover/focus tints. Each search/text-field widget styles its own
      // wrapping Container with the universal "dark surface + subtle
      // outline" so we get a single shape and color everywhere.
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        hintStyle: TextStyle(color: p.textTertiary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surface,
        selectedItemColor: p.primary,
        unselectedItemColor: p.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: p.glassBorder,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surfaceElevated,
        contentTextStyle: TextStyle(color: p.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
