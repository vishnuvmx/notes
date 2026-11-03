import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Canonical bottom sheet container adhering to Tack's Android design system.
///
/// Guarantees:
/// 1. Exactly ONE drag handle.
/// 2. Consistent 24dp top corner radius.
/// 3. Zero Android gesture bar overlap or double bottom padding.
/// 4. Proper keyboard resize (viewInsets vs viewPadding).
/// 5. Max height constraint to prevent obscuring the Android status bar.
class AppBottomSheet {
  AppBottomSheet._();

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext sheetContext) builder,
    bool isDismissible = true,
    bool enableDrag = true,
    bool showDragHandle = true,
    double maxHeightFactor = 0.90,
    Color? backgroundColor,
    Color? barrierColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sheetBg = backgroundColor ?? (isDark ? AppColors.darkCard : AppColors.lightSurface);
    final scrim = barrierColor ?? AppColors.sheetScrim;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      showDragHandle: false, // Prevent duplicate M3 drag handle; AppBottomSheet renders exactly one
      backgroundColor: Colors.transparent,
      barrierColor: scrim,
      builder: (modalContext) {
        final viewInsets = MediaQuery.viewInsetsOf(modalContext);
        final screenHeight = MediaQuery.sizeOf(modalContext).height;

        return AnimatedPadding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: screenHeight * maxHeightFactor,
            ),
            child: Material(
              color: sheetBg,
              elevation: 16,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusLg),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: SafeArea(
                top: false,
                bottom: viewInsets.bottom == 0, // Apply system navigation bar inset only when keyboard is hidden
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showDragHandle)
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 6),
                        child: Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
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
