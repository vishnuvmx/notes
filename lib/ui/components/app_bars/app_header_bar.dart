import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../state/workspace_provider.dart';
import '../../../state/theme_provider.dart';

/// Top header app bar for the Tack home screen with cute HeroIcons.
class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onOpenDrawer;
  final VoidCallback onToggleSearch;
  final bool isSearching;
  final VoidCallback onQuickCreate;

  const AppHeaderBar({
    super.key,
    required this.onOpenDrawer,
    required this.onToggleSearch,
    required this.isSearching,
    required this.onQuickCreate,
  });

  @override
  Size get preferredSize => const Size.fromHeight(84);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workspace = context.watch<WorkspaceProvider>();
    final themeProv = context.watch<ThemeProvider>();

    final iconColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drawer Hamburger Button (Cute HeroIcon)
            IconButton(
              onPressed: onOpenDrawer,
              icon: TackIcon(TackIcons.menu, size: 24, color: iconColor),
              style: IconButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 44),
              ),
              tooltip: 'Navigation Menu',
            ),
            const SizedBox(width: AppSpacing.sm),

            // App Icon & Brand Title / Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          'icon.png',
                          width: 22,
                          height: 22,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => TackIcon(TackIcons.pin, size: 20, color: iconColor),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tack',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      style: AppTypography.lightTextTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontSize: 12,
                      ),
                      children: [
                        const TextSpan(text: 'Everything '),
                        TextSpan(
                          text: 'worth',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.pastelAmberLight : AppColors.accentAmber,
                          ),
                        ),
                        const TextSpan(text: ' remembering.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // View Mode Toggle (Notebook vs Sticky Grid)
            IconButton(
              onPressed: () {
                final nextMode = workspace.viewMode == HomeViewMode.notebook
                    ? HomeViewMode.stickyGrid
                    : HomeViewMode.notebook;
                workspace.setViewMode(nextMode);
              },
              icon: TackIcon(
                workspace.viewMode == HomeViewMode.notebook
                    ? TackIcons.gridView
                    : TackIcons.listView,
                size: 22,
                color: iconColor,
              ),
              tooltip: workspace.viewMode == HomeViewMode.notebook
                  ? 'Switch to Sticky Grid'
                  : 'Switch to Notebook List',
            ),

            // Search Toggle Button
            IconButton(
              onPressed: onToggleSearch,
              icon: TackIcon(
                isSearching ? TackIcons.close : TackIcons.search,
                size: 22,
                color: iconColor,
              ),
              tooltip: isSearching ? 'Close Search' : 'Search Notes',
            ),

            // Quick Theme Toggle Button
            IconButton(
              onPressed: () => themeProv.toggleTheme(context),
              icon: TackIcon(
                isDark ? TackIcons.sun : TackIcons.moon,
                size: 22,
                color: isDark ? AppColors.pastelAmberLight : iconColor,
                style: isDark ? HeroIconStyle.solid : HeroIconStyle.outline,
              ),
              tooltip: isDark ? 'Switch to Light' : 'Switch to Dark',
            ),
          ],
        ),
      ),
    );
  }
}
