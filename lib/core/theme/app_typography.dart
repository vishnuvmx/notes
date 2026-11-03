import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Central typography tokens for Tack Android-First Design System.
/// Standardized strictly on DM Sans per Locked Product Decisions and Design Guidelines.
class AppTypography {
  AppTypography._();

  // Primary & display font family: DM Sans
  static String get fontFamily =>
      GoogleFonts.dmSans().fontFamily ?? 'DM Sans';

  // Display font family
  static String get displayFontFamily =>
      GoogleFonts.dmSans().fontFamily ?? 'DM Sans';

  // Letter spacing constant ~-2% (-0.02 * fontSize)
  static double ls(double fontSize) => -(fontSize * 0.02);

  // ================= Neo-Pop Display & Header Styles =================
  /// Punchy display headline for "Your Notes" / section titles
  static TextStyle sectionHeadline({
    required Color color,
    double fontSize = 34,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.0,
      height: 1.08,
      color: color,
    );
  }

  /// Welcome greeting: "Welcome back " (regular weight)
  static TextStyle welcomeGreetingStyle({required Color color}) {
    return GoogleFonts.dmSans(
      fontSize: 13.5,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.3,
      color: color,
    );
  }

  /// Welcome greeting username: "**Chad**" (bold weight)
  static TextStyle welcomeUsernameStyle({required Color color}) {
    return GoogleFonts.dmSans(
      fontSize: 13.5,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.3,
      color: color,
    );
  }

  /// Note Card Title (Bold, punchy, neo-brutalist)
  static TextStyle cardTitleStyle({
    required Color color,
    double fontSize = 16.5,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1.2,
      color: color,
    );
  }

  /// Note Card Date Stamp: "4th Jan 2050"
  static TextStyle cardDateStyle({
    required Color color,
    double fontSize = 11.5,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: color,
    );
  }

  /// Note Card Snippet / Preview Body
  static TextStyle cardSnippetStyle({
    required Color color,
    double fontSize = 12.5,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      height: 1.38,
      letterSpacing: -0.2,
      color: color,
    );
  }

  // ================= Light Typography =================
  static TextTheme lightTextTheme = TextTheme(
    displayLarge: GoogleFonts.dmSans(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.2,
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
      fontWeight: FontWeight.w700,
      letterSpacing: ls(24),
      color: AppColors.lightTextPrimary,
    ),
    headlineSmall: GoogleFonts.dmSans(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: ls(20),
      color: AppColors.lightTextPrimary,
    ),
    titleLarge: GoogleFonts.dmSans(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: ls(18),
      color: AppColors.lightTextPrimary,
    ),
    titleMedium: GoogleFonts.dmSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: ls(16),
      color: AppColors.lightTextPrimary,
    ),
    titleSmall: GoogleFonts.dmSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
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
      fontWeight: FontWeight.w700,
      letterSpacing: ls(13),
      color: AppColors.lightTextPrimary,
    ),
    labelMedium: GoogleFonts.dmSans(
      fontSize: 11,
      fontWeight: FontWeight.w600,
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
      fontSize: 34,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.2,
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
      fontWeight: FontWeight.w700,
      letterSpacing: ls(24),
      color: AppColors.darkTextPrimary,
    ),
    headlineSmall: GoogleFonts.dmSans(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: ls(20),
      color: AppColors.darkTextPrimary,
    ),
    titleLarge: GoogleFonts.dmSans(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: ls(18),
      color: AppColors.darkTextPrimary,
    ),
    titleMedium: GoogleFonts.dmSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: ls(16),
      color: AppColors.darkTextPrimary,
    ),
    titleSmall: GoogleFonts.dmSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
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
      fontWeight: FontWeight.w700,
      letterSpacing: ls(13),
      color: AppColors.darkTextPrimary,
    ),
    labelMedium: GoogleFonts.dmSans(
      fontSize: 11,
      fontWeight: FontWeight.w600,
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
      fontWeight: FontWeight.w600,
      fontStyle: FontStyle.italic,
      letterSpacing: -1.0,
      color: color,
    );
  }
}
