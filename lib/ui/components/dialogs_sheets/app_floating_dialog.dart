import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';

/// Custom floating modal dialog system replacing default Android AlertDialogs (`11-reference-ui-style.md`).
///
/// Features:
/// - Floating island card with 28dp rounded corners (`AppSpacing.roundedModal`).
/// - Visible 24dp spacing from screen edges.
/// - Dark, semi-transparent dimmed background (`0x99000000` / 60% black scrim).
/// - Soft tactile surface (`tokens.surfacePrimary`) and diffused elevation shadow.
/// - Smooth entrance animation (scale + subtle fade).
/// - Modern pill action buttons instead of standard flat Android text buttons.
class AppFloatingDialog {
  AppFloatingDialog._();

  /// Show a custom floating dialog card.
  static Future<T?> showCustom<T>({
    required BuildContext context,
    required Widget Function(BuildContext dialogContext) builder,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Dismiss',
      barrierColor: AppSpacing.modalScrim,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return builder(dialogContext);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = Curves.easeOutCubic.transform(animation.value);
        return Transform.scale(
          scale: 0.92 + (0.08 * curved),
          child: Opacity(
            opacity: animation.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
    );
  }

  /// Show a standardized floating confirmation dialog (Delete, Discard, Empty Trash, etc.).
  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    dynamic icon,
  }) async {
    final result = await showCustom<bool>(
      context: context,
      builder: (dialogCtx) {
        final tokens = dialogCtx.tokens;
        final isDark = tokens.isDark;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
              decoration: ShapeDecoration(
                color: tokens.surfacePrimary,
                shadows: AppSpacing.elevModal(isDark),
                shape: SmoothRectangleBorder(
                  borderRadius: AppSpacing.roundedModal,
                  smoothness: 0.60,
                  side: BorderSide(
                    color: tokens.borderSubtle.withValues(alpha: isDark ? 0.35 : 0.6),
                    width: 0.8,
                  ),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: tokens.surfacePrimary,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (icon != null) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDestructive
                                  ? tokens.danger.withValues(alpha: 0.12)
                                  : tokens.canvasSunken,
                              borderRadius: AppSpacing.roundedSm,
                            ),
                            child: Center(
                              child: TackIcon(
                                icon,
                                size: 22,
                                color: isDestructive
                                    ? tokens.danger
                                    : tokens.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                      ],
                      Text(
                        title,
                        style: AppTypography.titleSm(
                          color: tokens.textPrimary,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        message,
                        style: AppTypography.body(color: tokens.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.s6),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(46),
                                side: BorderSide(color: tokens.borderSubtle),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppSpacing.roundedPill,
                                ),
                              ),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                Navigator.of(dialogCtx).pop(false);
                              },
                              child: Text(
                                cancelLabel,
                                style: AppTypography.label(
                                  color: tokens.textPrimary,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s3),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(46),
                                backgroundColor: isDestructive
                                    ? tokens.danger
                                    : tokens.actionPrimary,
                                foregroundColor: isDestructive
                                    ? Colors.white
                                    : tokens.actionPrimaryFg,
                                elevation: 0,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppSpacing.roundedPill,
                                ),
                              ),
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                Navigator.of(dialogCtx).pop(true);
                              },
                              child: Text(
                                confirmLabel,
                                style: AppTypography.label(
                                  color: isDestructive
                                      ? Colors.white
                                      : tokens.actionPrimaryFg,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  /// Show a standardized single-input prompt dialog (e.g. New Category, Save Template, Edit Profile Name).
  static Future<String?> prompt({
    required BuildContext context,
    required String title,
    String? message,
    String? hintText,
    String? initialValue,
    String confirmLabel = 'Save',
    String cancelLabel = 'Cancel',
    dynamic icon,
  }) async {
    final controller = TextEditingController(text: initialValue);
    try {
      final result = await showCustom<String>(
        context: context,
        builder: (dialogCtx) {
          final tokens = dialogCtx.tokens;
          final isDark = tokens.isDark;
          final viewInsets = MediaQuery.viewInsetsOf(dialogCtx);

          return AnimatedPadding(
            padding: EdgeInsets.only(bottom: viewInsets.bottom),
            duration: AppSpacing.durationFast,
            curve: AppSpacing.curveStandard,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
                  decoration: ShapeDecoration(
                    color: tokens.surfacePrimary,
                    shadows: AppSpacing.elevModal(isDark),
                    shape: SmoothRectangleBorder(
                      borderRadius: AppSpacing.roundedModal,
                      smoothness: 0.60,
                      side: BorderSide(
                        color: tokens.borderSubtle.withValues(alpha: isDark ? 0.35 : 0.6),
                        width: 0.8,
                      ),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Material(
                    color: tokens.surfacePrimary,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.s6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (icon != null) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: tokens.canvasSunken,
                                  borderRadius: AppSpacing.roundedSm,
                                ),
                                child: Center(
                                  child: TackIcon(
                                    icon,
                                    size: 22,
                                    color: tokens.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s4),
                          ],
                          Text(
                            title,
                            style: AppTypography.titleSm(
                              color: tokens.textPrimary,
                              weight: FontWeight.w700,
                            ),
                          ),
                          if (message != null) ...[
                            const SizedBox(height: AppSpacing.s1),
                            Text(
                              message,
                              style: AppTypography.body(color: tokens.textSecondary),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.s4),
                          TextField(
                            controller: controller,
                            autofocus: true,
                            style: AppTypography.body(color: tokens.textPrimary),
                            decoration: InputDecoration(
                              hintText: hintText,
                              hintStyle: AppTypography.body(color: tokens.textTertiary),
                              filled: true,
                              fillColor: tokens.canvasSunken,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s4,
                                vertical: AppSpacing.s3,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: AppSpacing.roundedSm,
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (val) {
                              final trimmed = val.trim();
                              Navigator.of(dialogCtx).pop(trimmed.isEmpty ? null : trimmed);
                            },
                          ),
                          const SizedBox(height: AppSpacing.s6),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(46),
                                    side: BorderSide(color: tokens.borderSubtle),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: AppSpacing.roundedPill,
                                    ),
                                  ),
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    Navigator.of(dialogCtx).pop(null);
                                  },
                                  child: Text(
                                    cancelLabel,
                                    style: AppTypography.label(
                                      color: tokens.textPrimary,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s3),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(46),
                                    backgroundColor: tokens.actionPrimary,
                                    foregroundColor: tokens.actionPrimaryFg,
                                    elevation: 0,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: AppSpacing.roundedPill,
                                    ),
                                  ),
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    final trimmed = controller.text.trim();
                                    Navigator.of(dialogCtx).pop(trimmed.isEmpty ? null : trimmed);
                                  },
                                  child: Text(
                                    confirmLabel,
                                    style: AppTypography.label(
                                      color: tokens.actionPrimaryFg,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
      return result;
    } finally {
      controller.dispose();
    }
  }
}

