import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Custom floating modal bottom sheet system inspired by tactile card designs (`11-reference-ui-style.md`).
///
/// Guarantees:
/// 1. Floating island card with 28dp rounded corners (`AppSpacing.roundedModal`) on all 4 sides.
/// 2. Visible spacing from left, right, and bottom screen edges (16dp gutter + system gesture clearance).
/// 3. Dark, semi-transparent dimmed background (60% dark scrim).
/// 4. No default Android status bar, drag handle, or rectangular indicator line.
/// 5. Smooth entrance and dismissal animations with keyboard avoidance.
/// 6. Soft tactile surface with diffused elevation shadow.
class AppBottomSheet {
  AppBottomSheet._();

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext sheetContext) builder,
    bool isDismissible = true,
    bool enableDrag = true,
    bool showDragHandle = false,
    double maxHeightFactor = 0.88,
    Color? backgroundColor,
    Color? barrierColor,
  }) {
    final tokens = context.tokens;
    final sheetBg = backgroundColor ?? tokens.surfaceElevated;
    final scrim = barrierColor ?? AppSpacing.modalScrim;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      showDragHandle: false, // Explicitly no rectangular drag handle line
      backgroundColor: Colors.transparent,
      barrierColor: scrim,
      builder: (modalContext) {
        final modalTokens = modalContext.tokens;
        final viewInsets = MediaQuery.viewInsetsOf(modalContext);
        final viewPadding = MediaQuery.viewPaddingOf(modalContext);
        final screenHeight = MediaQuery.sizeOf(modalContext).height;
        final isDark = modalTokens.isDark;

        // Island bottom margin: 16dp + keyboard inset when typing, or 16dp + gesture bar when idle
        final bottomOffset = viewInsets.bottom > 0
            ? (viewInsets.bottom + AppSpacing.s4)
            : math.max(AppSpacing.s4, viewPadding.bottom + AppSpacing.s2);

        return AnimatedPadding(
          padding: EdgeInsets.only(bottom: bottomOffset),
          duration: AppSpacing.durationFast,
          curve: AppSpacing.curveStandard,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: screenHeight * maxHeightFactor,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: AppSpacing.roundedModal,
                boxShadow: AppSpacing.elevModal(isDark),
                border: Border.all(
                  color: modalTokens.borderSubtle.withValues(alpha: isDark ? 0.35 : 0.6),
                  width: 0.8,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: sheetBg,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: builder(modalContext),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Backwards compatibility alias for the custom floating modal.
typedef AppFloatingModal = AppBottomSheet;
