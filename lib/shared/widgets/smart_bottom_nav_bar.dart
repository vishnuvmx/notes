import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/tack_icons.dart';
import 'sliding_pill_track.dart';

/// Soft Monochrome Floating Pill Bottom Navigation Bar + Detached Circular (+) FAB:
/// Icon-only 4-slot dock (`Today` · `Library` · `Boards` · `Search`) with a
/// smooth gliding pill indicator and a detached `( + )` capture button.
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

    final selectedSlot = navItems
        .indexWhere((item) => item.index == currentIndex)
        .clamp(0, navItems.length - 1);

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
                // 1. Icon-only Floating Pill Dock with gliding pill indicator
                Expanded(
                  child: SlidingPillTrack(
                    height: 56,
                    padding: const EdgeInsets.all(5),
                    itemCount: navItems.length,
                    selectedIndex: selectedSlot,
                    duration: const Duration(milliseconds: 300),
                    curve: const Cubic(0.22, 1.0, 0.36, 1.0),
                    trackColor: tokens.canvasSunken,
                    indicatorColor: tokens.surfacePrimary,
                    indicatorShadow: AppSpacing.elev1(tokens.isDark),
                    trackShadow: AppSpacing.elev1(tokens.isDark),
                    children: [
                      for (final item in navItems)
                        _buildNavItem(context, item, tokens),
                    ],
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
    const iconAnimDuration = Duration(milliseconds: 240);
    const iconAnimCurve = Curves.easeOutCubic;

    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: Tooltip(
        message: item.label,
        child: GestureDetector(
          key: ValueKey('nav_item_${item.index}'),
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap(item.index);
          },
          child: Center(
            child: AnimatedScale(
              scale: isSelected ? 1.04 : 0.94,
              duration: iconAnimDuration,
              curve: iconAnimCurve,
              child: AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.52,
                duration: iconAnimDuration,
                curve: iconAnimCurve,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    TackIcon(
                      item.icon,
                      size: 21,
                      color: fgColor,
                      style: isSelected
                          ? HeroIconStyle.solid
                          : HeroIconStyle.outline,
                    ),
                    if (item.badge > 0)
                      Positioned(
                        top: -2,
                        right: -4,
                        child: AnimatedContainer(
                          duration: iconAnimDuration,
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
