import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';

/// 5-Destination Bottom Navigation Bar with iOS frosted blur and microanimations.
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

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF000000) : Colors.white).withValues(alpha: 0.88),
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 0.8,
              ),
            ),
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
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, ({dynamic icon, String label, int index}) item, bool isDark) {
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
            AnimatedScale(
              scale: isSelected ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: TackIcon(
                item.icon,
                size: 24,
                color: isSelected ? activeColor : inactiveColor,
                style: isSelected ? HeroIconStyle.solid : HeroIconStyle.outline,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: (AppTypography.lightTextTheme.labelSmall ?? const TextStyle()).copyWith(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
              child: Text(item.label),
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
            color: (isDark ? Colors.white : AppColors.primaryDark).withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.mediumImpact();
            onFabTap();
          },
          child: Center(
            child: TackIcon(
              TackIcons.plusSvg,
              size: 24,
              color: isDark ? AppColors.darkBackground : AppColors.lightSurface,
            ),
          ),
        ),
      ),
    );
  }
}
