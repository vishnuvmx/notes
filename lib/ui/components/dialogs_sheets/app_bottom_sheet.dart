import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Canonical bottom sheet container adhering to Tack's Paper & Pin design system (`07` §7).
///
/// Guarantees:
/// 1. Exactly ONE drag handle (`36×4dp` in `border/strong`).
/// 2. Consistent `16dp` (`r-lg`) top corner radius on `surface/elevated`.
/// 3. Zero Android gesture bar overlap or double bottom padding.
/// 4. Smooth keyboard resize (`viewInsets` vs `viewPadding`).
/// 5. Max height constraint (`90%`) to prevent obscuring the Android status bar.
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
    final tokens = context.tokens;
    final sheetBg = backgroundColor ?? tokens.surfaceElevated;
    final scrim = barrierColor ?? AppSpacing.scrimColor;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      showDragHandle: false, // AppBottomSheet renders the single canonical handle
      backgroundColor: Colors.transparent,
      barrierColor: scrim,
      builder: (modalContext) {
        final modalTokens = modalContext.tokens;
        final viewInsets = MediaQuery.viewInsetsOf(modalContext);
        final screenHeight = MediaQuery.sizeOf(modalContext).height;

        return AnimatedPadding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          duration: AppSpacing.durationNormal,
          curve: AppSpacing.curveStandard,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: screenHeight * maxHeightFactor,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: AppSpacing.sheetTopRadius,
                boxShadow: AppSpacing.elev2(modalTokens.isDark),
              ),
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: sheetBg,
                child: SafeArea(
                  top: false,
                  bottom: viewInsets.bottom == 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showDragHandle)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.s3,
                            bottom: AppSpacing.s2,
                          ),
                          child: Center(
                            child: Semantics(
                              label: 'Drag handle to dismiss',
                              child: Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: modalTokens.borderStrong,
                                  borderRadius: BorderRadius.circular(2),
                                ),
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
          ),
        );
      },
    );
  }
}
