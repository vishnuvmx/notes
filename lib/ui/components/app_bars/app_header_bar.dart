import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../state/theme_provider.dart';

/// Top header app bar for Tack home screen matching reference mockup.
/// Features avatar, "Welcome back Chad", search, and notification bell.
class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onOpenDrawer;
  final VoidCallback onToggleSearch;
  final bool isSearching;
  final VoidCallback onQuickCreate;
  final String userName;

  const AppHeaderBar({
    super.key,
    required this.onOpenDrawer,
    required this.onToggleSearch,
    required this.isSearching,
    required this.onQuickCreate,
    this.userName = 'friend',
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 6);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProv = context.watch<ThemeProvider>();

    final iconColor = isDark ? Colors.white : const Color(0xFF191A23);
    final borderColor = isDark ? const Color(0xFF323642) : const Color(0xFF191A23);

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: AppSpacing.lg,
      title: Row(
        children: [
          // Cute Tack Mascot Avatar button (opens drawer)
          GestureDetector(
            onTap: onOpenDrawer,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.08),
                    offset: const Offset(0, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'icon.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => TackIcon(
                    TackIcons.user,
                    size: 20,
                    color: iconColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Playful greeting
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Hey there, ',
                style: AppTypography.welcomeGreetingStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                children: [
                  TextSpan(
                    text: '$userName ✨',
                    style: AppTypography.welcomeUsernameStyle(
                      color: iconColor,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        // Search Button
        IconButton(
          onPressed: onToggleSearch,
          icon: TackIcon(
            isSearching ? TackIcons.close : TackIcons.search,
            size: 22,
            color: iconColor,
          ),
          tooltip: isSearching ? 'Close Search' : 'Search Notes',
          style: IconButton.styleFrom(
            minimumSize: const Size(40, 40),
            padding: EdgeInsets.zero,
          ),
        ),

        // Notification Bell with Badge
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No new notifications'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: TackIcon(
                TackIcons.notification,
                size: 22,
                color: iconColor,
              ),
              tooltip: 'Notifications',
              style: IconButton.styleFrom(
                minimumSize: const Size(40, 40),
                padding: EdgeInsets.zero,
              ),
            ),
            Positioned(
              top: 10,
              right: 11,
              child: Container(
                width: 7.5,
                height: 7.5,
                decoration: BoxDecoration(
                  color: AppColors.pastelRoseLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),

        // Quick Theme Toggle
        IconButton(
          onPressed: () => themeProv.toggleTheme(context),
          icon: TackIcon(
            isDark ? TackIcons.sun : TackIcons.moon,
            size: 20,
            color: isDark ? AppColors.pastelAmberLight : iconColor,
            style: isDark ? HeroIconStyle.solid : HeroIconStyle.outline,
          ),
          tooltip: isDark ? 'Light Mode' : 'Dark Mode',
          style: IconButton.styleFrom(
            minimumSize: const Size(38, 38),
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}

