import 'package:flutter/material.dart';

/// Central color tokens for Tack Android-First Design System.
/// Defines light/dark surfaces, primary brand colors, and the 8 curated sticky pastels.
class AppColors {
  AppColors._();

  // ================= Primary Brand & Surface =================
  static const Color primaryDark = Color(0xFF191A23);
  static const Color primaryLight = Color(0xFFF4F4F6);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentOrange = Color(0xFFFF8F6B);

  // Light surfaces
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF1F3F5);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightTextPrimary = Color(0xFF191A23);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextMuted = Color(0xFF9CA3AF);

  // Dark surfaces
  static const Color darkBackground = Color(0xFF121316);
  static const Color darkSurface = Color(0xFF1E1F24);
  static const Color darkSurfaceAlt = Color(0xFF282A30);
  static const Color darkBorder = Color(0xFF2D3039);
  static const Color darkTextPrimary = Color(0xFFF4F4F6);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextMuted = Color(0xFF6B7280);

  // Status & Feedback
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ================= 8 Curated Sticky Pastels =================
  // 1. Sunset Peach
  static const Color pastelPeachLight = Color(0xFFFF8F6B);
  static const Color pastelPeachDark = Color(0xFF5A2718);
  static const Color pastelPeachSoft = Color(0xFFFFF0EB);

  // 2. Warm Amber
  static const Color pastelAmberLight = Color(0xFFF5B842);
  static const Color pastelAmberDark = Color(0xFF593F0E);
  static const Color pastelAmberSoft = Color(0xFFFFF7E6);

  // 3. Coral Blush
  static const Color pastelCoralLight = Color(0xFFE05D5D);
  static const Color pastelCoralDark = Color(0xFF591C1C);
  static const Color pastelCoralSoft = Color(0xFFFFEEEE);

  // 4. Lavender Mist
  static const Color pastelLavenderLight = Color(0xFF9D84D6);
  static const Color pastelLavenderDark = Color(0xFF3B2B61);
  static const Color pastelLavenderSoft = Color(0xFFF3EFFF);

  // 5. Cyan Breeze
  static const Color pastelCyanLight = Color(0xFF1BA5BA);
  static const Color pastelCyanDark = Color(0xFF0C464F);
  static const Color pastelCyanSoft = Color(0xFFE6F9FC);

  // 6. Lime Zing
  static const Color pastelLimeLight = Color(0xFFB2CD4D);
  static const Color pastelLimeDark = Color(0xFF404F12);
  static const Color pastelLimeSoft = Color(0xFFF6FCE5);

  // 7. Rose Bubble
  static const Color pastelRoseLight = Color(0xFFF48FB1);
  static const Color pastelRoseDark = Color(0xFF5E2138);
  static const Color pastelRoseSoft = Color(0xFFFDEEF4);

  // 8. Slate Pure
  static const Color pastelSlateLight = Color(0xFFE2E8F0);
  static const Color pastelSlateDark = Color(0xFF2D3748);
  static const Color pastelSlateSoft = Color(0xFFF8FAFC);

  /// List of the 8 preset pastel color palettes
  static const List<TackColorPalette> presetPalettes = [
    TackColorPalette(
      id: 'peach',
      name: 'Sunset Peach',
      lightColor: pastelPeachLight,
      darkColor: pastelPeachDark,
      softBackground: pastelPeachSoft,
      indexColor: Color(0xFFE8673E),
    ),
    TackColorPalette(
      id: 'amber',
      name: 'Warm Amber',
      lightColor: pastelAmberLight,
      darkColor: pastelAmberDark,
      softBackground: pastelAmberSoft,
      indexColor: Color(0xFFD99516),
    ),
    TackColorPalette(
      id: 'coral',
      name: 'Coral Blush',
      lightColor: pastelCoralLight,
      darkColor: pastelCoralDark,
      softBackground: pastelCoralSoft,
      indexColor: Color(0xFFC73E3E),
    ),
    TackColorPalette(
      id: 'lavender',
      name: 'Lavender Mist',
      lightColor: pastelLavenderLight,
      darkColor: pastelLavenderDark,
      softBackground: pastelLavenderSoft,
      indexColor: Color(0xFF7E5EC2),
    ),
    TackColorPalette(
      id: 'cyan',
      name: 'Cyan Breeze',
      lightColor: pastelCyanLight,
      darkColor: pastelCyanDark,
      softBackground: pastelCyanSoft,
      indexColor: Color(0xFF0F8698),
    ),
    TackColorPalette(
      id: 'lime',
      name: 'Lime Zing',
      lightColor: pastelLimeLight,
      darkColor: pastelLimeDark,
      softBackground: pastelLimeSoft,
      indexColor: Color(0xFF8EAA28),
    ),
    TackColorPalette(
      id: 'rose',
      name: 'Rose Bubble',
      lightColor: pastelRoseLight,
      darkColor: pastelRoseDark,
      softBackground: pastelRoseSoft,
      indexColor: Color(0xFFD8678F),
    ),
    TackColorPalette(
      id: 'slate',
      name: 'Slate Pure',
      lightColor: pastelSlateLight,
      darkColor: pastelSlateDark,
      softBackground: pastelSlateSoft,
      indexColor: Color(0xFF64748B),
    ),
  ];

  static TackColorPalette getPaletteById(String? id) {
    if (id == null) return presetPalettes[0];
    return presetPalettes.firstWhere(
      (p) => p.id == id,
      orElse: () => presetPalettes[0],
    );
  }

  static TackColorPalette getPaletteByColor(Color color) {
    for (final palette in presetPalettes) {
      if (palette.lightColor.value == color.value ||
          palette.darkColor.value == color.value) {
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

  const TackColorPalette({
    required this.id,
    required this.name,
    required this.lightColor,
    required this.darkColor,
    required this.softBackground,
    required this.indexColor,
  });

  Color resolveCardColor(bool isDarkMode) => isDarkMode ? darkColor : lightColor;
  Color resolveTextColor(bool isDarkMode) => isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  Color resolveAccentColor(bool isDarkMode) => isDarkMode ? lightColor : indexColor;
}
