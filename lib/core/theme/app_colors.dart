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
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFEFF1F5);
  static const Color lightBorder = Color(0xFFE8EAEF);
  static const Color lightTextPrimary = Color(0xFF18191F);
  static const Color lightTextSecondary = Color(0xFF5E6272);
  static const Color lightTextMuted = Color(0xFF969BAA);

  // Dark surfaces (Rich charcoal, deep tones)
  static const Color darkBackground = Color(0xFF121316);
  static const Color darkSurface = Color(0xFF1B1C22);
  static const Color darkSurfaceAlt = Color(0xFF24262E);
  static const Color darkBorder = Color(0xFF2B2E37);
  static const Color darkTextPrimary = Color(0xFFF5F6F9);
  static const Color darkTextSecondary = Color(0xFF9FA4B4);
  static const Color darkTextMuted = Color(0xFF686D7D);

  // Status & Feedback
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFFFC661);
  static const Color error = Color(0xFFF56767);
  static const Color info = Color(0xFF26BBD9);

  // ================= 8 Curated Pastels (Exact Reference Hex) =================
  // 1. FFC661 - Warm Amber
  static const Color pastelAmberLight = Color(0xFFFFC661);
  static const Color pastelAmberDark = Color(0xFF5A4112);
  static const Color pastelAmberSoft = Color(0xFFFFF9EC);

  // 2. F3916A - Sunset Peach
  static const Color pastelPeachLight = Color(0xFFF3916A);
  static const Color pastelPeachDark = Color(0xFF5C2B18);
  static const Color pastelPeachSoft = Color(0xFFFFF2EB);

  // 3. F0906A - Terracotta Coral
  static const Color pastelTerracottaLight = Color(0xFFF0906A);
  static const Color pastelTerracottaDark = Color(0xFF5C2A18);
  static const Color pastelTerracottaSoft = Color(0xFFFFF1EB);

  // 4. F7C167 - Sun Yellow
  static const Color pastelYellowLight = Color(0xFFF7C167);
  static const Color pastelYellowDark = Color(0xFF5C4314);
  static const Color pastelYellowSoft = Color(0xFFFFF8EC);

  // 5. A88FE3 - Soft Lavender
  static const Color pastelLavenderLight = Color(0xFFA88FE3);
  static const Color pastelLavenderDark = Color(0xFF3C2C64);
  static const Color pastelLavenderSoft = Color(0xFFF4EFFF);

  // 6. F56767 - Coral Rose
  static const Color pastelRoseLight = Color(0xFFF56767);
  static const Color pastelRoseDark = Color(0xFF5D1D1D);
  static const Color pastelRoseSoft = Color(0xFFFFEFEF);
  static const Color pastelCoralLight = pastelRoseLight;
  static const Color pastelCoralDark = pastelRoseDark;

  // 7. 26BBD9 - Cyan Breeze
  static const Color pastelCyanLight = Color(0xFF26BBD9);
  static const Color pastelCyanDark = Color(0xFF0C4652);
  static const Color pastelCyanSoft = Color(0xFFE6F9FC);

  // 8. D5F06A - Lime Zing
  static const Color pastelLimeLight = Color(0xFFD5F06A);
  static const Color pastelLimeDark = Color(0xFF465410);
  static const Color pastelLimeSoft = Color(0xFFF8FDE8);

  // Fallback slate for neutrals
  static const Color pastelSlateLight = Color(0xFFE2E8F0);
  static const Color pastelSlateDark = Color(0xFF2D3748);
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
