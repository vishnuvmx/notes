import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';

/// Ergonomic, tactile toast notification adhering to Tack's modern design system.
/// Features pill-shaped surface, subtle diffused shadows, DM Sans typography, and Lucide icons.
class TackToast {
  TackToast._();

  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? iconColor,
    Duration duration = const Duration(milliseconds: 2200),
    String? actionLabel,
    VoidCallback? onAction,
    double bottomMargin = 24,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        margin: EdgeInsets.fromLTRB(24, 0, 24, bottomMargin),
        padding: EdgeInsets.zero,
        duration: duration,
        content: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: AppSpacing.roundedPill,
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorder
                    : const Color(0xFF191A23).withValues(alpha: 0.08),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.5)
                      : const Color(0xFF191A23).withValues(alpha: 0.09),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: (iconColor ??
                              (isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary))
                          .withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: TackIcon(
                        icon,
                        size: 13,
                        color: iconColor ??
                            (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                ],
                Flexible(
                  child: Text(
                    message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      messenger.hideCurrentSnackBar();
                      onAction();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.pastelAmberLight.withValues(alpha: 0.22)
                            : const Color(0xFF191A23),
                        borderRadius: AppSpacing.roundedPill,
                      ),
                      child: Text(
                        actionLabel,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          color: isDark ? AppColors.pastelAmberLight : Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
