import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';

/// Soft Monochrome Floating Pill Bottom Navigation Bar + Detached Circular (+) FAB
/// (`docs/design/11-reference-ui-style.md` §3–4, Screenshot 2):
/// `( [ Today ]  [ Library ]  [ Boards ]  [ Search ] )    ( + )`
class SmartBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabTap;
  final int inboxCount;

  const SmartBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
    this.inboxCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final gutter = AppSpacing.screenGutter(screenWidth);

    final navItems = [
      (icon: TackIcons.today, label: 'Today', index: 0, badge: inboxCount),
      (icon: TackIcons.library, label: 'Library', index: 1, badge: 0),
      (icon: TackIcons.boards, label: 'Boards', index: 3, badge: 0),
      (icon: TackIcons.search, label: 'Search', index: 4, badge: 0),
    ];

    return ColoredBox(
      color: tokens.canvasPrimary,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            gutter,
            AppSpacing.s2,
            gutter,
            AppSpacing.s3,
          ),
          child: SizedBox(
            height: 58,
            child: Row(
              children: [
                // 1. Floating Pill Dock (Today · Library · Boards · Search)
                Expanded(
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: tokens.canvasSunken,
                      borderRadius: AppSpacing.roundedPill,
                      boxShadow: AppSpacing.elev1(tokens.isDark),
                    ),
                    child: Row(
                      children: [
                        for (final item in navItems)
                          _buildNavItem(context, item, tokens),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: AppSpacing.s3),

                // 2. Detached Circular (+) Capture Button (56x56dp Ink Black)
                _buildDetachedCaptureFab(context, tokens),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    ({dynamic icon, String label, int index, int badge}) item,
    TackTokens tokens,
  ) {
    final isSelected = currentIndex == item.index;
    final fgColor = isSelected ? tokens.textPrimary : tokens.textSecondary;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: item.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('nav_item_${item.index}'),
            onTap: () {
              HapticFeedback.selectionClick();
              onTap(item.index);
            },
            borderRadius: AppSpacing.roundedPill,
            child: AnimatedContainer(
              duration: AppSpacing.durationFast,
              curve: AppSpacing.curveStandard,
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: isSelected ? tokens.surfacePrimary : Colors.transparent,
                borderRadius: AppSpacing.roundedPill,
                boxShadow: isSelected
                    ? AppSpacing.elev1(tokens.isDark)
                    : AppSpacing.elev0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      TackIcon(
                        item.icon,
                        size: 17,
                        color: fgColor,
                        style: isSelected
                            ? HeroIconStyle.solid
                            : HeroIconStyle.outline,
                      ),
                      if (item.badge > 0)
                        Positioned(
                          top: -3,
                          right: -5,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: tokens.accentPin,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? tokens.surfacePrimary
                                    : tokens.canvasSunken,
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption(
                        color: fgColor,
                        weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetachedCaptureFab(BuildContext context, TackTokens tokens) {
    return Semantics(
      button: true,
      label: 'Capture thought, note, or board',
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: tokens.actionPrimary,
          shape: BoxShape.circle,
          boxShadow: AppSpacing.elev2(tokens.isDark),
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            key: const ValueKey('nav_capture_fab'),
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.mediumImpact();
              onFabTap();
            },
            child: Center(
              child: TackIcon(
                TackIcons.plus,
                size: 24,
                color: tokens.actionPrimaryFg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
