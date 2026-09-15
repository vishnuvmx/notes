import 'package:flutter/material.dart';

/// Central color tokens for Tack Android-First Design System.
/// Defines light/dark surfaces, primary brand colors, and the 8 curated pastels from the design spec.
class AppColors {
  AppColors._();

  // ================= Primary Brand & Surface =================
  static const Color primaryDark = Color(0xFF191A23);
  static const Color primaryLight = Color(0xFFF4F4F6);
  static const Color accentAmber = Color(0xFFFFC661);
  static const Color accentOrange = Color(0xFFF3916A);

  // Light surfaces (Soft, tactile, off-white)
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF1F3F5);
  static const Color lightBorder = Color(0xFFE8EAEF);
  static const Color lightTextPrimary = Color(0xFF191A23);
  static const Color lightTextSecondary = Color(0xFF5E6272);
  static const Color lightTextMuted = Color(0xFF969BAA);

  // Dark surfaces (Tack Design Spec: #121316 Surface, #1E1F24 Card, #F4F4F6 Text)
  static const Color darkBackground = Color(0xFF121316);
  static const Color darkSurface = Color(0xFF121316);
  static const Color darkSurfaceAlt = Color(0xFF1E1F24);
  static const Color darkCard = Color(0xFF1E1F24);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color darkBorder = Color(0xFF272930);
  static const Color darkTextPrimary = Color(0xFFF4F4F6);
  static const Color darkTextSecondary = Color(0xFFA1A6B7);
  static const Color darkTextMuted = Color(0xFF6B7184);

  // Status & Feedback
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFFFC661);
  static const Color error = Color(0xFFF56767);
  static const Color info = Color(0xFF26BBD9);

  // ================= 8 Curated Pastels (Exact Reference Hex) =================
  // 1. FFC661 - Warm Amber
  static const Color pastelAmberLight = Color(0xFFFFC661);
  static const Color pastelAmberDark = Color(0xFF261D0A); // Rich nocturnal amber
  static const Color pastelAmberSoft = Color(0xFFFFF9EC);

  // 2. F3916A - Sunset Peach
  static const Color pastelPeachLight = Color(0xFFF3916A);
  static const Color pastelPeachDark = Color(0xFF2A160E); // Deep velvety peach
  static const Color pastelPeachSoft = Color(0xFFFFF2EB);

  // 3. F0906A - Terracotta Coral
  static const Color pastelTerracottaLight = Color(0xFFF0906A);
  static const Color pastelTerracottaDark = Color(0xFF2A150D); // Deep terracotta
  static const Color pastelTerracottaSoft = Color(0xFFFFF1EB);

  // 4. F7C167 - Sun Yellow
  static const Color pastelYellowLight = Color(0xFFF7C167);
  static const Color pastelYellowDark = Color(0xFF261C08); // Deep nocturnal gold
  static const Color pastelYellowSoft = Color(0xFFFFF8EC);

  // 5. A88FE3 - Soft Lavender
  static const Color pastelLavenderLight = Color(0xFFA88FE3);
  static const Color pastelLavenderDark = Color(0xFF1E1432); // Deep midnight lavender
  static const Color pastelLavenderSoft = Color(0xFFF4EFFF);

  // 6. F56767 - Coral Rose
  static const Color pastelRoseLight = Color(0xFFF56767);
  static const Color pastelRoseDark = Color(0xFF2C1016); // Deep crimson rose
  static const Color pastelRoseSoft = Color(0xFFFFEFEF);
  static const Color pastelCoralLight = pastelRoseLight;
  static const Color pastelCoralDark = pastelRoseDark;

  // 7. 26BBD9 - Cyan Breeze
  static const Color pastelCyanLight = Color(0xFF26BBD9);
  static const Color pastelCyanDark = Color(0xFF0A222A); // Deep oceanic cyan
  static const Color pastelCyanSoft = Color(0xFFE6F9FC);

  // 8. D5F06A - Lime Zing
  static const Color pastelLimeLight = Color(0xFFD5F06A);
  static const Color pastelLimeDark = Color(0xFF172408); // Deep citrus lime
  static const Color pastelLimeSoft = Color(0xFFF8FDE8);

  // Fallback slate for neutrals
  static const Color pastelSlateLight = Color(0xFFE2E8F0);
  static const Color pastelSlateDark = Color(0xFF141720); // Deep midnight slate
  static const Color pastelSlateSoft = Color(0xFFF8FAFC);

  /// List of the 8 preset pastel color palettes exactly matching reference
  static const List<TackColorPalette> presetPalettes = [
    TackColorPalette(
      id: 'amber',
      name: 'Warm Amber',
      lightColor: pastelAmberLight,
      darkColor: pastelAmberDark,
      softBackground: pastelAmberSoft,
      indexColor: Color(0xFFD49216),
      pinColor: Color(0xFFE08324),
    ),
    TackColorPalette(
      id: 'peach',
      name: 'Sunset Peach',
      lightColor: pastelPeachLight,
      darkColor: pastelPeachDark,
      softBackground: pastelPeachSoft,
      indexColor: Color(0xFFD66033),
      pinColor: Color(0xFFE2542B),
    ),
    TackColorPalette(
      id: 'terracotta',
      name: 'Terracotta',
      lightColor: pastelTerracottaLight,
      darkColor: pastelTerracottaDark,
      softBackground: pastelTerracottaSoft,
      indexColor: Color(0xFFD45F33),
      pinColor: Color(0xFFE05228),
    ),
    TackColorPalette(
      id: 'yellow',
      name: 'Sun Yellow',
      lightColor: pastelYellowLight,
      darkColor: pastelYellowDark,
      softBackground: pastelYellowSoft,
      indexColor: Color(0xFFCF9317),
      pinColor: Color(0xFFD88915),
    ),
    TackColorPalette(
      id: 'lavender',
      name: 'Lavender',
      lightColor: pastelLavenderLight,
      darkColor: pastelLavenderDark,
      softBackground: pastelLavenderSoft,
      indexColor: Color(0xFF7E5EC2),
      pinColor: Color(0xFF6B42CA),
    ),
    TackColorPalette(
      id: 'coral',
      name: 'Coral Rose',
      lightColor: pastelRoseLight,
      darkColor: pastelRoseDark,
      softBackground: pastelRoseSoft,
      indexColor: Color(0xFFC73E3E),
      pinColor: Color(0xFFDC2E2E),
    ),
    TackColorPalette(
      id: 'cyan',
      name: 'Cyan Breeze',
      lightColor: pastelCyanLight,
      darkColor: pastelCyanDark,
      softBackground: pastelCyanSoft,
      indexColor: Color(0xFF0F8698),
      pinColor: Color(0xFF0B87C2),
    ),
    TackColorPalette(
      id: 'lime',
      name: 'Lime Zing',
      lightColor: pastelLimeLight,
      darkColor: pastelLimeDark,
      softBackground: pastelLimeSoft,
      indexColor: Color(0xFF869E1C),
      pinColor: Color(0xFF90B012),
    ),
  ];

  static TackColorPalette getPaletteById(String? id) {
    if (id == null) return presetPalettes[0];
    return presetPalettes.firstWhere(
      (p) => p.id == id,
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
  /// adapting to any of the 8 main note color palettes.
  static Color getHighlightColor(String? paletteId, {required bool isDark}) {
    final palette = getPaletteById(paletteId);
    return isDark
        ? palette.lightColor.withValues(alpha: 0.35)
        : palette.lightColor.withValues(alpha: 0.48);
  }

  /// Parses a hex color string like #565656, #ff8f6b, #fff, or #80565656.
  /// Returns null if the text is not a valid 3, 6, or 8 digit hex color code.
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

/// Strongly typed color palette model for sticky notes, flowchart nodes, and notebook tags.
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

  Color resolveCardColor(bool isDarkMode) => isDarkMode ? darkColor : lightColor;
  Color resolveSoftBackground(bool isDarkMode) => isDarkMode ? darkColor.withValues(alpha: 0.35) : softBackground;
  Color resolveTextColor(bool isDarkMode) => isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  Color resolveAccentColor(bool isDarkMode) => isDarkMode ? lightColor : indexColor;
}
