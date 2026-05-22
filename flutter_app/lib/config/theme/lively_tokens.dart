/// Lively spacing + radius scales — the design system's 4px-base spacing
/// ramp and the corner-radius set. Use these instead of bare literals so
/// every screen stays on the same rhythm.
///
/// From the design handoff:
/// ```
/// LivelySpace  xs 4 · sm 8 · md 12 · lg 16 · xl 24 · xl2 32 · xl3 48 · xl4 64
/// LivelyRadius sm 8 · md 12 · lg 16 · xl 20 · xl2 28
/// ```
abstract final class LivelySpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xl2 = 32;
  static const double xl3 = 48;
  static const double xl4 = 64;
}

abstract final class LivelyRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xl2 = 28;
  static const double full = 999;
}

/// Motion guidelines — durations + curves the design handoff specifies so
/// transitions feel consistent across screens.
abstract final class LivelyMotion {
  /// Screen push-in.
  static const Duration screenEnter = Duration(milliseconds: 420);

  /// Screen pop-out.
  static const Duration screenExit = Duration(milliseconds: 250);

  /// StepProgress segment width tween, field focus, chip select.
  static const Duration quick = Duration(milliseconds: 250);

  /// Button press scale.
  static const Duration press = Duration(milliseconds: 110);
}
