import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';

/// 5-Destination Bottom Navigation Bar (`05-information-architecture.md` §2.1, `07-design-system.md` §7):
/// `[ Today ]  [ Library ]  [ (+) Capture ]  [ Boards ]  [ Search ]`
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

    final navItems = [
      (icon: TackIcons.today, label: 'Today', index: 0, badge: inboxCount),
      (icon: TackIcons.library, label: 'Library', index: 1, badge: 0),
      (icon: TackIcons.boards, label: 'Boards', index: 3, badge: 0),
      (icon: TackIcons.search, label: 'Search', index: 4, badge: 0),
    ];

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfacePrimary,
        border: Border(
          top: BorderSide(
            color: tokens.borderSubtle,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSpacing.bottomBarHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 0. Today
              _buildNavItem(context, navItems[0], tokens),

              // 1. Library
              _buildNavItem(context, navItems[1], tokens),

              // 2. Center (+) Capture Button (56x56dp in action/primary)
              _buildCenterCaptureButton(context, tokens),

              // 3. Boards
              _buildNavItem(context, navItems[2], tokens),

              // 4. Search
              _buildNavItem(context, navItems[3], tokens),
            ],
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
    final iconColor = isSelected ? tokens.textPrimary : tokens.textTertiary;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: item.label,
        child: InkWell(
          key: ValueKey('nav_item_${item.index}'),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap(item.index);
          },
          borderRadius: AppSpacing.roundedSm,
          child: SizedBox(
            height: AppSpacing.bottomBarHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    TackIcon(
                      item.icon,
                      size: 22,
                      color: iconColor,
                      style: isSelected
                          ? HeroIconStyle.solid
                          : HeroIconStyle.outline,
                    ),
                    if (item.badge > 0)
                      Positioned(
                        top: -3,
                        right: -6,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: tokens.accentPin,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: tokens.surfacePrimary,
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(
                    color: iconColor,
                    weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                // Signature Pin Red dot under the active tab (`07` §7)
                AnimatedContainer(
                  duration: AppSpacing.durationFast,
                  curve: AppSpacing.curveStandard,
                  width: isSelected ? 4 : 0,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isSelected ? tokens.accentPin : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterCaptureButton(BuildContext context, TackTokens tokens) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
      child: Semantics(
        button: true,
        label: 'Capture thought, note, or board',
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: tokens.actionPrimary,
            shape: BoxShape.circle,
            boxShadow: AppSpacing.elev1(tokens.isDark),
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
                  size: 22,
                  color: tokens.actionPrimaryFg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
