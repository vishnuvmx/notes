import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';

/// 5-Destination Bottom Navigation Bar with cute HeroIcons and elevated center (+) FAB.
class SmartBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabTap;

  const SmartBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final navItems = [
      (icon: TackIcons.home, label: 'Home', index: 0),
      (icon: TackIcons.notes, label: 'Notes', index: 1),
      (icon: TackIcons.whiteboard, label: 'Whiteboard', index: 3),
      (icon: TackIcons.clipboard, label: 'Clipboard', index: 4),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
        boxShadow: isDark ? AppSpacing.softShadowDark : AppSpacing.softShadowLight,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Home
              _buildNavItem(context, navItems[0], isDark),

              // 2. Notes
              _buildNavItem(context, navItems[1], isDark),

              // 3. Center (+) Floating Action Button
              _buildCenterFab(context, isDark),

              // 4. Whiteboard
              _buildNavItem(context, navItems[2], isDark),

              // 5. Clipboard
              _buildNavItem(context, navItems[3], isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, ({HeroIcons icon, String label, int index}) item, bool isDark) {
    final isSelected = currentIndex == item.index;
    final activeColor = isDark ? AppColors.primaryLight : AppColors.primaryDark;
    final inactiveColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Expanded(
      child: InkWell(
        key: ValueKey('nav_item_${item.index}'),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap(item.index);
        },
        borderRadius: AppSpacing.roundedSm,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TackIcon(
              item.icon,
              size: 24,
              color: isSelected ? activeColor : inactiveColor,
              style: isSelected ? HeroIconStyle.solid : HeroIconStyle.outline,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: AppTypography.lightTextTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterFab(BuildContext context, bool isDark) {
    return Container(
      width: 50,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.lightSurface : AppColors.primaryDark,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.white : AppColors.primaryDark).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.lightImpact();
            onFabTap();
          },
          child: Center(
            child: TackIcon(
              TackIcons.plus,
              size: 26,
              color: isDark ? AppColors.darkBackground : AppColors.lightSurface,
              style: HeroIconStyle.outline,
            ),
          ),
        ),
      ),
    );
  }
}
