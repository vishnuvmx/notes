import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Central typography tokens for Tack.
/// Uses DM Sans with ~-2% letter spacing across all hierarchy levels.
class AppTypography {
  AppTypography._();

  // Primary font family
  static String get fontFamily => GoogleFonts.dmSans().fontFamily ?? 'DM Sans';

  // Letter spacing constant ~-2% (-0.02 * fontSize)
  static double ls(double fontSize) => -(fontSize * 0.02);

  // ================= Light Typography =================
  static TextTheme lightTextTheme = TextTheme(
    displayLarge: GoogleFonts.dmSans(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: ls(32),
      color: AppColors.lightTextPrimary,
    ),
    displayMedium: GoogleFonts.dmSans(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: ls(28),
      color: AppColors.lightTextPrimary,
    ),
    headlineMedium: GoogleFonts.dmSans(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: ls(24),
      color: AppColors.lightTextPrimary,
    ),
    headlineSmall: GoogleFonts.dmSans(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: ls(20),
      color: AppColors.lightTextPrimary,
    ),
    titleLarge: GoogleFonts.dmSans(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: ls(18),
      color: AppColors.lightTextPrimary,
    ),
    titleMedium: GoogleFonts.dmSans(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: ls(16),
      color: AppColors.lightTextPrimary,
    ),
    titleSmall: GoogleFonts.dmSans(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: ls(14),
      color: AppColors.lightTextSecondary,
    ),
    bodyLarge: GoogleFonts.dmSans(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.45,
      letterSpacing: ls(15),
      color: AppColors.lightTextPrimary,
    ),
    bodyMedium: GoogleFonts.dmSans(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.40,
      letterSpacing: ls(13),
      color: AppColors.lightTextSecondary,
    ),
    bodySmall: GoogleFonts.dmSans(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      letterSpacing: ls(11),
      color: AppColors.lightTextMuted,
    ),
    labelLarge: GoogleFonts.dmSans(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: ls(13),
      color: AppColors.lightTextPrimary,
    ),
    labelMedium: GoogleFonts.dmSans(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: ls(11),
      color: AppColors.lightTextSecondary,
    ),
    labelSmall: GoogleFonts.dmSans(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      letterSpacing: ls(10),
      color: AppColors.lightTextMuted,
    ),
  );

  // ================= Dark Typography =================
  static TextTheme darkTextTheme = TextTheme(
    displayLarge: GoogleFonts.dmSans(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: ls(32),
      color: AppColors.darkTextPrimary,
    ),
    displayMedium: GoogleFonts.dmSans(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: ls(28),
      color: AppColors.darkTextPrimary,
    ),
    headlineMedium: GoogleFonts.dmSans(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: ls(24),
      color: AppColors.darkTextPrimary,
    ),
    headlineSmall: GoogleFonts.dmSans(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: ls(20),
      color: AppColors.darkTextPrimary,
    ),
    titleLarge: GoogleFonts.dmSans(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: ls(18),
      color: AppColors.darkTextPrimary,
    ),
    titleMedium: GoogleFonts.dmSans(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: ls(16),
      color: AppColors.darkTextPrimary,
    ),
    titleSmall: GoogleFonts.dmSans(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: ls(14),
      color: AppColors.darkTextSecondary,
    ),
    bodyLarge: GoogleFonts.dmSans(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.45,
      letterSpacing: ls(15),
      color: AppColors.darkTextPrimary,
    ),
    bodyMedium: GoogleFonts.dmSans(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.40,
      letterSpacing: ls(13),
      color: AppColors.darkTextSecondary,
    ),
    bodySmall: GoogleFonts.dmSans(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      letterSpacing: ls(11),
      color: AppColors.darkTextMuted,
    ),
    labelLarge: GoogleFonts.dmSans(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: ls(13),
      color: AppColors.darkTextPrimary,
    ),
    labelMedium: GoogleFonts.dmSans(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: ls(11),
      color: AppColors.darkTextSecondary,
    ),
    labelSmall: GoogleFonts.dmSans(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      letterSpacing: ls(10),
      color: AppColors.darkTextMuted,
    ),
  );

  // Stylized index script typography (01, 02...)
  static TextStyle scriptIndexStyle({required Color color, double fontSize = 34}) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
      letterSpacing: -1.0,
      color: color,
    );
  }
}
