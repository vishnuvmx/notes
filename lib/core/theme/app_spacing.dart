import 'package:flutter/material.dart';

/// Central spacing, layout metrics, radii, elevation, and motion tokens for Tack.
/// Follows docs/design/07-design-system.md §4, §5, §8.
class AppSpacing {
  AppSpacing._();

  // ================= 4dp Base Spacing Scale (07-design-system.md §4.1) =================
  static const double s0 = 0.0;
  static const double s1 = 2.0;
  static const double s2 = 4.0;
  static const double s3 = 8.0;
  static const double s4 = 12.0;
  static const double s5 = 16.0;
  static const double s6 = 20.0;
  static const double s7 = 24.0;
  static const double s8 = 32.0;
  static const double s9 = 40.0;
  static const double s10 = 48.0;
  static const double s11 = 64.0;

  // Backwards-compatible named spacing tokens
  static const double xs = s2;   // 4dp
  static const double sm = s3;   // 8dp
  static const double md = s4;   // 12dp
  static const double lg = s5;   // 16dp
  static const double xl = s7;   // 24dp
  static const double xxl = s8;  // 32dp
  static const double xxxl = s10; // 48dp

  // ================= Layout & Touch Metrics (07-design-system.md §4.2) =================
  /// `touch/min` — Minimum 48x48dp touch target for all interactive controls.
  static const double minTouchTarget = 48.0;

  /// `gutter/screen` — 16dp on compact (< 600dp), 24dp on medium/expanded (>= 600dp).
  static const double gutterScreen = 16.0;
  static const double gutterScreenWide = 24.0;

  static double screenGutter(double screenWidth) =>
      screenWidth >= 600 ? gutterScreenWide : gutterScreen;

  /// Responsive Library / Board grid column count by Android window class (07-design-system.md §4.3).
  static int gridColumnsForWidth(double screenWidth) {
    if (screenWidth >= 840) return 4;
    if (screenWidth >= 600) return 3;
    if (screenWidth < 340) return 1;
    return 2;
  }

  /// `gap/grid` — 12dp gap between grid cards.
  static const double gapGrid = 12.0;
  static const double cardGridGap = gapGrid;

  /// `appbar/height` — 56dp standard app bar height.
  static const double appBarHeight = 56.0;

  /// `bottombar/height` — 64dp bottom navigation bar height (plus system inset).
  static const double bottomBarHeight = 64.0;

  /// `row/height` — 56dp minimum list row height (grows with text scale).
  static const double rowHeight = 56.0;

  /// `read/maxwidth` — 720dp readable column width in Read/Edit mode on wide screens.
  static const double readMaxWidth = 720.0;

  /// `sidebar/width` — 260dp navigation rail/sidebar width on tablet/desktop.
  static const double sidebarWidth = 260.0;

  /// Card object-color leading band width (6dp per 07-design-system.md §7).
  static const double cardColorBandWidth = 6.0;

  /// Card minimum height (intrinsic, min 120dp per 07-design-system.md §4.3).
  static const double cardMinHeight = 120.0;
  static const double cardMaxHeight = 200.0;

  // ================= Radii (07-design-system.md §5) =================
  /// `radius/xs` — 4dp (tags inside text, code chips)
  static const double radiusXs = 4.0;
  static const double rXs = radiusXs;

  /// `radius/sm` — 10dp (buttons, inputs, chips, property pills)
  static const double radiusSm = 10.0;
  static const double rSm = radiusSm;

  /// `radius/md` — 18dp (soft monochrome cards, menus, popovers — per 11-reference-ui-style.md)
  static const double radiusMd = 18.0;
  static const double rMd = radiusMd;

  /// `radius/lg` — 24dp (sheet top corners, hero cards, dialogs)
  static const double radiusLg = 24.0;
  static const double rLg = radiusLg;

  /// Legacy alias mapped to radiusLg
  static const double radiusXl = 24.0;

  /// `radius/pill` — 999dp (tags, floating nav bar, and the Capture button)
  static const double radiusPill = 999.0;

  static const BorderRadius roundedXs = BorderRadius.all(Radius.circular(radiusXs));
  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius roundedPill = BorderRadius.all(Radius.circular(radiusPill));
  static const BorderRadius sheetTopRadius =
      BorderRadius.vertical(top: Radius.circular(radiusLg));

  // ================= Elevation & Scrim (11-reference-ui-style.md §4) =================
  /// `elev/0` — Flat content separated by 1dp hairlines (no shadow).
  static const List<BoxShadow> elev0 = [];

  /// `elev/1` — Soft diffused shadow on white cards floating over #F3F4F6 canvas (blur 14, y 3, alpha 0.04-0.05).
  /// Sized specifically to prevent GPU offscreen buffer bounding-box clipping artifacts on Android.
  static List<BoxShadow> elev1([bool isDark = false]) => [
        BoxShadow(
          color: isDark ? const Color(0x38000000) : const Color(0x0C000000),
          blurRadius: 14,
          offset: const Offset(0, 3),
          spreadRadius: 0,
        ),
      ];

  /// `elev/2` — Bottom sheets, floating nav pill, dialogs (blur 20, y 6, alpha 0.08-0.10).
  static List<BoxShadow> elev2([bool isDark = false]) => [
        BoxShadow(
          color: isDark ? const Color(0x4D000000) : const Color(0x14000000),
          blurRadius: 20,
          offset: const Offset(0, 6),
          spreadRadius: 0,
        ),
      ];

  /// `scrim` — Black alpha 0.40 behind sheets and dialogs.
  static const Color scrim = Color(0x66000000);
  static const Color scrimColor = scrim;

  // Backwards-compatible shadow aliases
  static List<BoxShadow> get softShadowLight => elev0;
  static List<BoxShadow> get cardShadowLight => elev0;
  static List<BoxShadow> get floatingControlShadow => elev1();
  static List<BoxShadow> get softShadowDark => elev0;

  // ================= Motion (07-design-system.md §8) =================
  /// 100ms press response
  static const Duration pressAnim = Duration(milliseconds: 100);

  /// 150ms fade / scale transition
  static const Duration fastAnim = Duration(milliseconds: 150);
  static const Duration durationFast = fastAnim;

  /// 250ms sheet / page transition
  static const Duration normalAnim = Duration(milliseconds: 250);
  static const Duration durationNormal = normalAnim;

  static const Duration mediumAnim = Duration(milliseconds: 250);
  static const Duration slowAnim = Duration(milliseconds: 250);

  /// Single canonical easing curve (`easeOutCubic`; no bounce/spring).
  static const Curve smoothCurve = Curves.easeOutCubic;
  static const Curve curveStandard = smoothCurve;
  static const Curve bouncyCurve = Curves.easeOutCubic;
}
