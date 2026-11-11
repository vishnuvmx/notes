import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Central typography tokens for Tack — Direction A ("Paper & Pin") Design System.
///
/// Follows docs/design/07-design-system.md §3:
/// - UI: DM Sans (400/500/600/700)
/// - Read-mode Display Title: Newsreader (editorial serif, 32/38sp, w600, -1% tracking)
/// - Metadata & Code: JetBrains Mono (13/20sp, w400)
/// - 12sp is the minimum font size floor across the application.
class AppTypography {
  AppTypography._();

  /// Primary UI font family: DM Sans
  static String get fontFamily =>
      GoogleFonts.dmSans().fontFamily ?? 'DM Sans';

  /// Editorial serif font family for Read-mode display titles
  static String get serifFontFamily =>
      GoogleFonts.newsreader().fontFamily ?? 'Georgia';

  /// Monospace font family for code, IDs, and metadata
  static String get monoFontFamily =>
      GoogleFonts.jetBrainsMono().fontFamily ?? 'monospace';

  static String get displayFontFamily => serifFontFamily;

  static double ls(double fontSize, [double percent = -0.015]) =>
      fontSize * percent;

  // ================= Named Token Builders (07-design-system.md §3) =================

  /// `display` — Serif 32/38sp, w600, -1% tracking (Read-mode note title)
  static TextStyle display({
    Color? color,
    double fontSize = 32,
    FontWeight? weight,
    FontWeight fontWeight = FontWeight.w600,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    return GoogleFonts.newsreader(
      fontSize: fontSize,
      height: 38 / 32,
      fontWeight: weight ?? fontWeight,
      fontStyle: fontStyle,
      letterSpacing: -(fontSize * 0.01),
      color: color,
    );
  }

  /// `serifItalic` — Editorial italic serif subtitle ("Let's make progress today!", Screenshot 2)
  static TextStyle serifItalic({
    Color? color,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.newsreader(
      fontSize: fontSize,
      height: 22 / 16,
      fontWeight: fontWeight,
      fontStyle: FontStyle.italic,
      letterSpacing: -0.1,
      color: color,
    );
  }

  /// `title-lg` — DM Sans 24/30sp, w700, -2% tracking (Screen titles, sheet titles)
  static TextStyle titleLg({
    Color? color,
    double fontSize = 24,
    FontWeight? weight,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      height: 30 / 24,
      fontWeight: weight ?? fontWeight,
      letterSpacing: -(fontSize * 0.02),
      color: color,
    );
  }

  /// `title` — DM Sans 20/26sp, w600, -1.5% tracking (App bar titles, section heads)
  static TextStyle title({
    Color? color,
    double fontSize = 20,
    FontWeight? weight,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      height: 26 / 20,
      fontWeight: weight ?? fontWeight,
      letterSpacing: -(fontSize * 0.015),
      color: color,
    );
  }

  /// `title-sm` — DM Sans 17/24sp, w600, -1% tracking (Card titles, list row titles)
  static TextStyle titleSm({
    Color? color,
    double fontSize = 17,
    FontWeight? weight,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      height: 24 / 17,
      fontWeight: weight ?? fontWeight,
      letterSpacing: -(fontSize * 0.01),
      color: color,
    );
  }

  /// `body-lg` — DM Sans 17/26sp, w400, 0 tracking (Read mode paragraphs)
  static TextStyle bodyLg({
    Color? color,
    FontWeight? weight,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.dmSans(
      fontSize: 17,
      height: 26 / 17,
      fontWeight: weight ?? fontWeight,
      letterSpacing: 0,
      color: color,
    );
  }

  /// `body` — DM Sans 16/24sp, w400, 0 tracking (Edit mode, default text)
  static TextStyle body({
    Color? color,
    FontWeight? weight,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.dmSans(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: weight ?? fontWeight,
      letterSpacing: 0,
      color: color,
    );
  }

  /// `body-sm` — DM Sans 14/20sp, w400, 0 tracking (Secondary text, card summaries)
  static TextStyle bodySm({
    Color? color,
    FontWeight? weight,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.dmSans(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: weight ?? fontWeight,
      letterSpacing: 0,
      color: color,
    );
  }

  /// `label` — DM Sans 13/16sp, w500, +0.1% tracking (Chips, buttons, tabs)
  static TextStyle label({
    Color? color,
    FontWeight? weight,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return GoogleFonts.dmSans(
      fontSize: 13,
      height: 16 / 13,
      fontWeight: weight ?? fontWeight,
      letterSpacing: 13 * 0.001,
      color: color,
    );
  }

  /// `caption` — DM Sans 12/16sp, w400, +0.2% tracking (Timestamps, counts; 12sp floor)
  static TextStyle caption({
    Color? color,
    FontWeight? weight,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.dmSans(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: weight ?? fontWeight,
      letterSpacing: 12 * 0.002,
      color: color,
    );
  }

  /// `mono` — JetBrains Mono 13/20sp, w400, 0 tracking (Code, IDs, metadata)
  static TextStyle mono({
    Color? color,
    double fontSize = 13,
    FontWeight? weight,
    FontWeight fontWeight = FontWeight.w400,
    Color? backgroundColor,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      height: 20 / 13,
      fontWeight: weight ?? fontWeight,
      letterSpacing: 0,
      color: color,
      backgroundColor: backgroundColor,
    );
  }

  // ================= Backwards-Compatible Style Helpers =================
  static TextStyle sectionHeadline({
    required Color color,
    double fontSize = 24,
  }) =>
      titleLg(color: color, fontSize: fontSize);

  static TextStyle welcomeGreetingStyle({required Color color}) =>
      bodySm(color: color, fontWeight: FontWeight.w500);

  static TextStyle welcomeUsernameStyle({required Color color}) =>
      titleSm(color: color);

  static TextStyle cardTitleStyle({
    required Color color,
    double fontSize = 17,
  }) =>
      titleSm(color: color, fontSize: fontSize);

  static TextStyle cardDateStyle({
    required Color color,
    double fontSize = 12,
  }) =>
      caption(color: color);

  static TextStyle cardSnippetStyle({
    required Color color,
    double fontSize = 14,
  }) =>
      bodySm(color: color);

  static TextStyle scriptIndexStyle({required Color color, double fontSize = 24}) =>
      display(color: color, fontSize: fontSize);

  // ================= Material TextTheme Mappings =================
  static TextTheme lightTextTheme = TextTheme(
    displayLarge: display(color: AppColors.lightTextPrimary),
    displayMedium: titleLg(color: AppColors.lightTextPrimary, fontSize: 28),
    headlineMedium: titleLg(color: AppColors.lightTextPrimary),
    headlineSmall: title(color: AppColors.lightTextPrimary),
    titleLarge: title(color: AppColors.lightTextPrimary),
    titleMedium: titleSm(color: AppColors.lightTextPrimary),
    titleSmall: bodySm(color: AppColors.lightTextSecondary, fontWeight: FontWeight.w600),
    bodyLarge: body(color: AppColors.lightTextPrimary),
    bodyMedium: bodySm(color: AppColors.lightTextSecondary),
    bodySmall: caption(color: AppColors.lightTextTertiary),
    labelLarge: label(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w600),
    labelMedium: caption(color: AppColors.lightTextSecondary, fontWeight: FontWeight.w500),
    labelSmall: caption(color: AppColors.lightTextTertiary),
  );

  static TextTheme darkTextTheme = TextTheme(
    displayLarge: display(color: AppColors.darkTextPrimary),
    displayMedium: titleLg(color: AppColors.darkTextPrimary, fontSize: 28),
    headlineMedium: titleLg(color: AppColors.darkTextPrimary),
    headlineSmall: title(color: AppColors.darkTextPrimary),
    titleLarge: title(color: AppColors.darkTextPrimary),
    titleMedium: titleSm(color: AppColors.darkTextPrimary),
    titleSmall: bodySm(color: AppColors.darkTextSecondary, fontWeight: FontWeight.w600),
    bodyLarge: body(color: AppColors.darkTextPrimary),
    bodyMedium: bodySm(color: AppColors.darkTextSecondary),
    bodySmall: caption(color: AppColors.darkTextTertiary),
    labelLarge: label(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w600),
    labelMedium: caption(color: AppColors.darkTextSecondary, fontWeight: FontWeight.w500),
    labelSmall: caption(color: AppColors.darkTextTertiary),
  );
}
