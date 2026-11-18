import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tack_icons.dart';
import 'tactile_ink_target.dart';

/// Ergonomic, tactile toast notification adhering to Tack's modern design system.
/// Features pill-shaped surface, subtle diffused shadows, DM Sans typography, and Lucide icons.
class TackToast {
  TackToast._();

  static void show(
    BuildContext context, {
    required String message,
    dynamic icon,
    Color? iconColor,
    Duration duration = const Duration(milliseconds: 2200),
    String? actionLabel,
    VoidCallback? onAction,
    double bottomMargin = 24,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final tokens = context.tokens;
    final isDark = tokens.isDark;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        margin: EdgeInsets.fromLTRB(
          AppSpacing.s6,
          0,
          AppSpacing.s6,
          bottomMargin,
        ),
        padding: EdgeInsets.zero,
        duration: duration,
        content: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: tokens.surfacePrimary,
              borderRadius: AppSpacing.roundedPill,
              border: Border.all(color: tokens.borderSubtle, width: 1.2),
              boxShadow: AppSpacing.elevModal(isDark),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: (iconColor ?? tokens.textPrimary).withValues(
                        alpha: 0.12,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: TackIcon(
                        icon,
                        size: 13,
                        color: iconColor ?? tokens.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s2),
                ],
                Flexible(
                  child: Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label(
                      color: tokens.textPrimary,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(width: AppSpacing.s2),
                  TactileInkTarget(
                    semanticsLabel: actionLabel,
                    borderRadius: AppSpacing.roundedPill,
                    color: isDark
                        ? AppColors.pastelAmberLight.withValues(alpha: 0.22)
                        : tokens.actionPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s3,
                      vertical: 6,
                    ),
                    splashColor:
                        (isDark
                                ? AppColors.pastelAmberLight
                                : tokens.actionPrimaryFg)
                            .withValues(alpha: 0.16),
                    onTap: () {
                      messenger.hideCurrentSnackBar();
                      onAction();
                    },
                    child: Text(
                      actionLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption(
                        color: isDark
                            ? AppColors.pastelAmberLight
                            : tokens.actionPrimaryFg,
                        weight: FontWeight.w700,
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
