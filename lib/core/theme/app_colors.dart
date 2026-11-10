import 'package:flutter/material.dart';

/// Central color tokens for Tack — Direction A ("Paper & Pin") Design System.
///
/// Principles (docs/design/07-design-system.md):
/// 1. Chrome is neutral; objects carry colour. Pastels colour notes and board nodes only.
/// 2. Brand red returns as `accentPin` (#D92D20 light / #FF6B5E dark).
/// 3. Primary buttons are ink (`actionPrimary`), never red.
/// 4. All text/background combinations satisfy WCAG 2.x AA (>= 4.5:1 for text, >= 3:1 for UI).
class AppColors {
  AppColors._();

  // ================= Light Semantic Tokens (Paper & Pin) =================
  /// `bg/canvas` — Warm paper app background (#F7F6F3)
  static const Color lightCanvas = Color(0xFFF7F6F3);

  /// `bg/surface` — Cards, sheets, inputs (#FFFFFF)
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// `bg/sunken` — Wells, code blocks, selected rows (#EFEDE8)
  static const Color lightSunken = Color(0xFFEFEDE8);

  /// `border/subtle` — 1dp hairlines on content (#E4E1DA)
  static const Color lightBorderSubtle = Color(0xFFE4E1DA);

  /// `border/strong` — Input outlines, visible dividers (#CFCBC2, >= 3:1 on canvas)
  static const Color lightBorderStrong = Color(0xFFCFCBC2);

  /// `text/primary` — Body, titles (#1B1A17, 16.1:1 on canvas)
  static const Color lightTextPrimary = Color(0xFF1B1A17);

  /// `text/secondary` — Supporting text (#55514A, 7.3:1 on canvas)
  static const Color lightTextSecondary = Color(0xFF55514A);

  /// `text/tertiary` — Timestamps, hints (#6B665D, 5.27:1 on canvas, 5.7:1 on white)
  static const Color lightTextTertiary = Color(0xFF6B665D);

  /// `accent/pin` — Pin motif, active-slot dot, brand moments (#D92D20)
  static const Color lightAccentPin = Color(0xFFD92D20);

  /// `accent/pin-text` — Red used as text/links (#C2271B, 5.4:1 on canvas)
  static const Color lightAccentPinText = Color(0xFFC2271B);

  /// `action/primary` — Primary button fill (#1B1A17 ink)
  static const Color lightActionPrimary = Color(0xFF1B1A17);

  // ================= Dark Semantic Tokens (Warm Charcoal) =================
  /// `bg/canvas` — Warm charcoal app background (#141311)
  static const Color darkCanvas = Color(0xFF141311);

  /// `bg/surface` — Cards, sheets, inputs (#1D1C19)
  static const Color darkSurface = Color(0xFF1D1C19);

  /// `bg/sunken` — Wells, code blocks, selected rows (#0E0D0C)
  static const Color darkSunken = Color(0xFF0E0D0C);

  /// `border/subtle` — 1dp hairlines on content (#2A2824)
  static const Color darkBorderSubtle = Color(0xFF2A2824);

  /// `border/strong` — Input outlines, visible dividers (#3B3833)
  static const Color darkBorderStrong = Color(0xFF3B3833);

  /// `text/primary` — Body, titles (#F2F0EB, 16.3:1 on canvas)
  static const Color darkTextPrimary = Color(0xFFF2F0EB);

  /// `text/secondary` — Supporting text (#B3AEA3, 8.4:1 on canvas)
  static const Color darkTextSecondary = Color(0xFFB3AEA3);

  /// `text/tertiary` — Timestamps, hints (#8F8A80, 5.41:1 on canvas, 4.96:1 on surface)
  static const Color darkTextTertiary = Color(0xFF8F8A80);

  /// `accent/pin` — Pin motif, active-slot dot, brand moments (#FF6B5E, 6.65:1 on dark canvas)
  static const Color darkAccentPin = Color(0xFFFF6B5E);

  /// `accent/pin-text` — Red used as text/links in dark mode (#FF6B5E)
  static const Color darkAccentPinText = Color(0xFFFF6B5E);

  /// `action/primary` — Primary button fill in dark mode (#F2F0EB)
  static const Color darkActionPrimary = Color(0xFFF2F0EB);

  // ================= State Tokens (Light & Dark) =================
  static const Color lightStateSuccess = Color(0xFF1A7F5A); // 4.97:1 on white
  static const Color darkStateSuccess = Color(0xFF4FC79A);

  static const Color lightStateWarning = Color(0xFFB54708); // 5.43:1 on white
  static const Color darkStateWarning = Color(0xFFF5A25D);

  static const Color lightStateInfo = Color(0xFF175CD3); // 5.99:1 on white
  static const Color darkStateInfo = Color(0xFF7FB0FF);

  static const Color lightStateDanger = Color(0xFFC2271B); // 5.83:1 white on it
  static const Color darkStateDanger = Color(0xFFFF6B5E);

  // ================= Backwards-Compatible Token Aliases =================
  static const Color primaryDark = lightActionPrimary;
  static const Color primaryLight = darkActionPrimary;
  static const Color accentPin = lightAccentPin;
  static const Color accentAmber = Color(0xFFFFD27A);
  static const Color accentOrange = Color(0xFFFFB59C);
  static const Color accentCyan = Color(0xFF8FD6E6);

  static const Color lightBackground = lightCanvas;
  static const Color lightSurfaceAlt = lightSunken;
  static const Color lightCard = lightSurface;
  static const Color lightBorder = lightBorderSubtle;
  static const Color lightTextMuted = lightTextTertiary;

  static const Color darkBackground = darkCanvas;
  static const Color darkSurfaceAlt = darkSunken;
  static const Color darkCard = darkSurface;
  static const Color darkBorder = darkBorderSubtle;
  static const Color darkTextMuted = darkTextTertiary;

  static const Color lightPillBackground = lightSunken;
  static const Color darkPillBackground = darkSunken;
  static const Color lightPillBorder = lightBorderSubtle;
  static const Color darkPillBorder = darkBorderSubtle;
  static const Color lightFocusBorder = lightActionPrimary;
  static const Color darkFocusBorder = darkActionPrimary;
  static const Color sheetScrim = Color(0x66000000);

  static const Color success = lightStateSuccess;
  static const Color warning = lightStateWarning;
  static const Color error = lightStateDanger;
  static const Color info = lightStateInfo;

  // ================= 8 Object Palette Tokens (07-design-system.md §2.2) =================
  // 1. amber — Warm Amber (#FFD27A light / #4A2F12 dark)
  static const Color objectAmber = pastelAmberLight;
  static const Color pastelAmberLight = Color(0xFFFFD27A);
  static const Color pastelAmberDark = Color(0xFF4A2F12);
  static const Color pastelAmberSoft = Color(0xFFFFF8E6);

  // 2. peach — Sunset Peach (#FFB59C light / #4A2418 dark)
  static const Color pastelPeachLight = Color(0xFFFFB59C);
  static const Color pastelPeachDark = Color(0xFF4A2418);
  static const Color pastelPeachSoft = Color(0xFFFFF1EC);

  // 3. coral — Coral Blush (#F2A6A6 light / #4A1E1E dark)
  static const Color pastelCoralLight = Color(0xFFF2A6A6);
  static const Color pastelCoralDark = Color(0xFF4A1E1E);
  static const Color pastelCoralSoft = Color(0xFFFDEDED);

  // 4. lavender — Lavender Mist (#C9B8F2 light / #2E2650 dark)
  static const Color pastelLavenderLight = Color(0xFFC9B8F2);
  static const Color pastelLavenderDark = Color(0xFF2E2650);
  static const Color pastelLavenderSoft = Color(0xFFF5F1FD);

  // 5. cyan — Cyan Breeze (#8FD6E6 light / #124049 dark)
  static const Color pastelCyanLight = Color(0xFF8FD6E6);
  static const Color pastelCyanDark = Color(0xFF124049);
  static const Color pastelCyanSoft = Color(0xFFECF8FB);

  // 6. lime — Lime Zing (#D6E88F light / #343F12 dark)
  static const Color pastelLimeLight = Color(0xFFD6E88F);
  static const Color pastelLimeDark = Color(0xFF343F12);
  static const Color pastelLimeSoft = Color(0xFFF6FAEB);

  // 7. rose — Rose Bubble (#F5B8D0 light / #4A1E33 dark)
  static const Color pastelRoseLight = Color(0xFFF5B8D0);
  static const Color pastelRoseDark = Color(0xFF4A1E33);
  static const Color pastelRoseSoft = Color(0xFFFDF0F5);

  // 8. slate — Slate Pure (#D9DEE6 light / #2F3440 dark)
  static const Color pastelSlateLight = Color(0xFFD9DEE6);
  static const Color pastelSlateDark = Color(0xFF2F3440);
  static const Color pastelSlateSoft = Color(0xFFF4F6F8);

  // Legacy aliases mapped to the canonical 8 palettes
  static const Color pastelTerracottaLight = pastelPeachLight;
  static const Color pastelTerracottaDark = pastelPeachDark;
  static const Color pastelTerracottaSoft = pastelPeachSoft;
  static const Color pastelYellowLight = pastelAmberLight;
  static const Color pastelYellowDark = pastelAmberDark;
  static const Color pastelYellowSoft = pastelAmberSoft;

  /// The 8 canonical object color palettes from docs/design/07-design-system.md §2.2.
  /// All light fills guarantee >= 8.9:1 with ink `#1B1A17`; all dark fills guarantee >= 9.8:1 with `#F2F0EB`.
  /// Text/bullet accents (`indexColor`) are WCAG AA compliant (>= 4.5:1 on white).
  static const List<TackColorPalette> presetPalettes = [
    TackColorPalette(
      id: 'amber',
      name: 'Warm Amber',
      lightColor: pastelAmberLight,
      darkColor: pastelAmberDark,
      softBackground: pastelAmberSoft,
      indexColor: Color(0xFF8A5200), // > 5.5:1 on white
      pinColor: lightAccentPin,
    ),
    TackColorPalette(
      id: 'peach',
      name: 'Sunset Peach',
      lightColor: pastelPeachLight,
      darkColor: pastelPeachDark,
      softBackground: pastelPeachSoft,
      indexColor: Color(0xFF9E3B18), // > 5.8:1 on white
      pinColor: lightAccentPin,
    ),
    TackColorPalette(
      id: 'coral',
      name: 'Coral Blush',
      lightColor: pastelCoralLight,
      darkColor: pastelCoralDark,
      softBackground: pastelCoralSoft,
      indexColor: Color(0xFFA12828), // > 6.2:1 on white
      pinColor: lightAccentPin,
    ),
    TackColorPalette(
      id: 'lavender',
      name: 'Lavender Mist',
      lightColor: pastelLavenderLight,
      darkColor: pastelLavenderDark,
      softBackground: pastelLavenderSoft,
      indexColor: Color(0xFF56399E), // > 7.1:1 on white
      pinColor: lightAccentPin,
    ),
    TackColorPalette(
      id: 'cyan',
      name: 'Cyan Breeze',
      lightColor: pastelCyanLight,
      darkColor: pastelCyanDark,
      softBackground: pastelCyanSoft,
      indexColor: Color(0xFF0B6472), // > 6.3:1 on white
      pinColor: lightAccentPin,
    ),
    TackColorPalette(
      id: 'lime',
      name: 'Lime Zing',
      lightColor: pastelLimeLight,
      darkColor: pastelLimeDark,
      softBackground: pastelLimeSoft,
      indexColor: Color(0xFF4B610B), // > 6.6:1 on white
      pinColor: lightAccentPin,
    ),
    TackColorPalette(
      id: 'rose',
      name: 'Rose Bubble',
      lightColor: pastelRoseLight,
      darkColor: pastelRoseDark,
      softBackground: pastelRoseSoft,
      indexColor: Color(0xFF9C2756), // > 6.1:1 on white
      pinColor: lightAccentPin,
    ),
    TackColorPalette(
      id: 'slate',
      name: 'Slate Pure',
      lightColor: pastelSlateLight,
      darkColor: pastelSlateDark,
      softBackground: pastelSlateSoft,
      indexColor: Color(0xFF3E4756), // > 8.4:1 on white
      pinColor: lightAccentPin,
    ),
  ];

  /// Normalizes legacy palette IDs (`terracotta -> peach`, `yellow -> amber`).
  static String normalizePaletteId(String? id) {
    if (id == null || id.isEmpty) return 'amber';
    switch (id.toLowerCase()) {
      case 'terracotta':
        return 'peach';
      case 'yellow':
        return 'amber';
      default:
        return id.toLowerCase();
    }
  }

  static TackColorPalette getPaletteById(String? id) {
    final normalized = normalizePaletteId(id);
    return presetPalettes.firstWhere(
      (p) => p.id == normalized,
      orElse: () => presetPalettes.firstWhere(
        (p) => p.id == 'peach',
        orElse: () => presetPalettes[0],
      ),
    );
  }

  static TackColorPalette getPaletteByColor(Color color) {
    for (final palette in presetPalettes) {
      if (palette.lightColor == color || palette.darkColor == color) {
        return palette;
      }
    }
    return presetPalettes[0];
  }

  /// Returns a translucent highlight background tint for markdown ==highlight==
  /// adapting to any of the 8 object color palettes.
  static Color getHighlightColor(String? paletteId, {required bool isDark}) {
    final palette = getPaletteById(paletteId);
    return isDark
        ? palette.lightColor.withValues(alpha: 0.30)
        : palette.lightColor.withValues(alpha: 0.45);
  }

  /// Parses a hex color string like #565656, #ff8f6b, #fff, or #80565656.
  static Color? tryParseHexColor(String? text) {
    if (text == null || !text.startsWith('#')) return null;
    final hex = text.substring(1).trim();
    if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex)) return null;

    if (hex.length == 3) {
      final r = hex[0];
      final g = hex[1];
      final b = hex[2];
      final val = int.tryParse('$r$r$g$g$b$b', radix: 16);
      if (val != null) return Color(0xFF000000 | val);
    } else if (hex.length == 6) {
      final val = int.tryParse(hex, radix: 16);
      if (val != null) return Color(0xFF000000 | val);
    } else if (hex.length == 8) {
      final val = int.tryParse(hex, radix: 16);
      if (val != null) return Color(val);
    }
    return null;
  }
}

/// Object color palette model for notes and board nodes.
class TackColorPalette {
  final String id;
  final String name;
  final Color lightColor;
  final Color darkColor;
  final Color softBackground;
  final Color indexColor;
  final Color pinColor;

  const TackColorPalette({
    required this.id,
    required this.name,
    required this.lightColor,
    required this.darkColor,
    required this.softBackground,
    required this.indexColor,
    required this.pinColor,
  });

  /// Full object fill (used for board nodes and card edge bands).
  Color resolveFill(bool isDarkMode) => isDarkMode ? darkColor : lightColor;

  /// Edge band color on white/charcoal cards: vibrant in both modes.
  Color resolveBandColor(bool isDarkMode) => isDarkMode ? lightColor : lightColor;

  Color resolveCardColor(bool isDarkMode) => isDarkMode ? darkColor : lightColor;
  Color resolveSoftBackground(bool isDarkMode) =>
      isDarkMode ? darkColor.withValues(alpha: 0.35) : softBackground;
  Color resolveTextColor(bool isDarkMode) =>
      isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  Color resolveAccentColor(bool isDarkMode) => isDarkMode ? lightColor : indexColor;

  /// WCAG AA compliant (>= 4.5:1) accent color for bullets and ordered lists.
  Color resolveBulletColor(bool isDarkMode) => isDarkMode ? lightColor : indexColor;
  Color resolveNumberPrefix(bool isDarkMode) => isDarkMode ? lightColor : indexColor;

  Color resolveTableHeaderBg(bool isDarkMode) => isDarkMode
      ? AppColors.darkSunken
      : AppColors.lightSunken;

  Color resolveTableBorder(bool isDarkMode) => isDarkMode
      ? AppColors.darkBorderStrong
      : AppColors.lightBorderStrong;

  Color resolveCodeBlockBg(bool isDarkMode) => isDarkMode
      ? AppColors.darkSunken
      : AppColors.lightSunken;

  Color resolveCodeHeaderBg(bool isDarkMode) => isDarkMode
      ? Color.alphaBlend(AppColors.darkBorderSubtle.withValues(alpha: 0.6), AppColors.darkSunken)
      : Color.alphaBlend(AppColors.lightBorderSubtle.withValues(alpha: 0.6), AppColors.lightSunken);

  Color resolveCodeAccent(bool isDarkMode) =>
      isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

  Color resolveInlineCodeBg(bool isDarkMode) => isDarkMode
      ? AppColors.darkSunken
      : AppColors.lightSunken;

  Color resolveInlineCodeText(bool isDarkMode) =>
      isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

  Color resolveQuoteBar(bool isDarkMode) => isDarkMode ? lightColor : indexColor;

  Color resolveQuoteBg(bool isDarkMode) => isDarkMode
      ? AppColors.darkSunken
      : AppColors.lightSunken;
}

/// ThemeExtension carrying all semantic tokens for Tack (docs/design/07-design-system.md §9).
@immutable
class TackTokens extends ThemeExtension<TackTokens> {
  final Color bgCanvas;
  final Color bgSurface;
  final Color bgSunken;
  final Color borderSubtle;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accentPin;
  final Color accentPinText;
  final Color actionPrimary;
  final Color onActionPrimary;
  final Color focusRing;
  final Color stateSuccess;
  final Color stateWarning;
  final Color stateInfo;
  final Color stateDanger;
  final bool isDark;

  const TackTokens({
    required this.bgCanvas,
    required this.bgSurface,
    required this.bgSunken,
    required this.borderSubtle,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accentPin,
    required this.accentPinText,
    required this.actionPrimary,
    required this.onActionPrimary,
    required this.focusRing,
    required this.stateSuccess,
    required this.stateWarning,
    required this.stateInfo,
    required this.stateDanger,
    required this.isDark,
  });

  static const TackTokens light = TackTokens(
    bgCanvas: AppColors.lightCanvas,
    bgSurface: AppColors.lightSurface,
    bgSunken: AppColors.lightSunken,
    borderSubtle: AppColors.lightBorderSubtle,
    borderStrong: AppColors.lightBorderStrong,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textTertiary: AppColors.lightTextTertiary,
    accentPin: AppColors.lightAccentPin,
    accentPinText: AppColors.lightAccentPinText,
    actionPrimary: AppColors.lightActionPrimary,
    onActionPrimary: AppColors.lightCanvas,
    focusRing: AppColors.lightActionPrimary,
    stateSuccess: AppColors.lightStateSuccess,
    stateWarning: AppColors.lightStateWarning,
    stateInfo: AppColors.lightStateInfo,
    stateDanger: AppColors.lightStateDanger,
    isDark: false,
  );

  static const TackTokens dark = TackTokens(
    bgCanvas: AppColors.darkCanvas,
    bgSurface: AppColors.darkSurface,
    bgSunken: AppColors.darkSunken,
    borderSubtle: AppColors.darkBorderSubtle,
    borderStrong: AppColors.darkBorderStrong,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textTertiary: AppColors.darkTextTertiary,
    accentPin: AppColors.darkAccentPin,
    accentPinText: AppColors.darkAccentPinText,
    actionPrimary: AppColors.darkActionPrimary,
    onActionPrimary: AppColors.darkCanvas,
    focusRing: AppColors.darkActionPrimary,
    stateSuccess: AppColors.darkStateSuccess,
    stateWarning: AppColors.darkStateWarning,
    stateInfo: AppColors.darkStateInfo,
    stateDanger: AppColors.darkStateDanger,
    isDark: true,
  );

  static TackTokens of(BuildContext context) {
    final ext = Theme.of(context).extension<TackTokens>();
    if (ext != null) return ext;
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  // Semantic token aliases used across Paper & Pin UI components
  Color get canvasPrimary => bgCanvas;
  Color get surfacePrimary => bgSurface;
  Color get surfaceElevated => bgSurface;
  Color get canvasSunken => bgSunken;
  Color get actionPrimaryFg => onActionPrimary;
  Color get borderFocus => focusRing;
  Color get danger => stateDanger;
  Color get success => stateSuccess;
  Color get warning => stateWarning;
  Color get info => stateInfo;

  @override
  TackTokens copyWith({
    Color? bgCanvas,
    Color? bgSurface,
    Color? bgSunken,
    Color? borderSubtle,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? accentPin,
    Color? accentPinText,
    Color? actionPrimary,
    Color? onActionPrimary,
    Color? focusRing,
    Color? stateSuccess,
    Color? stateWarning,
    Color? stateInfo,
    Color? stateDanger,
    bool? isDark,
  }) {
    return TackTokens(
      bgCanvas: bgCanvas ?? this.bgCanvas,
      bgSurface: bgSurface ?? this.bgSurface,
      bgSunken: bgSunken ?? this.bgSunken,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      accentPin: accentPin ?? this.accentPin,
      accentPinText: accentPinText ?? this.accentPinText,
      actionPrimary: actionPrimary ?? this.actionPrimary,
      onActionPrimary: onActionPrimary ?? this.onActionPrimary,
      focusRing: focusRing ?? this.focusRing,
      stateSuccess: stateSuccess ?? this.stateSuccess,
      stateWarning: stateWarning ?? this.stateWarning,
      stateInfo: stateInfo ?? this.stateInfo,
      stateDanger: stateDanger ?? this.stateDanger,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  TackTokens lerp(ThemeExtension<TackTokens>? other, double t) {
    if (other is! TackTokens) return this;
    return TackTokens(
      bgCanvas: Color.lerp(bgCanvas, other.bgCanvas, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgSunken: Color.lerp(bgSunken, other.bgSunken, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      accentPin: Color.lerp(accentPin, other.accentPin, t)!,
      accentPinText: Color.lerp(accentPinText, other.accentPinText, t)!,
      actionPrimary: Color.lerp(actionPrimary, other.actionPrimary, t)!,
      onActionPrimary: Color.lerp(onActionPrimary, other.onActionPrimary, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      stateSuccess: Color.lerp(stateSuccess, other.stateSuccess, t)!,
      stateWarning: Color.lerp(stateWarning, other.stateWarning, t)!,
      stateInfo: Color.lerp(stateInfo, other.stateInfo, t)!,
      stateDanger: Color.lerp(stateDanger, other.stateDanger, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

extension TackTokensContext on BuildContext {
  TackTokens get tokens => TackTokens.of(this);
}
