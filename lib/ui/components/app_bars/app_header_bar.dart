import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../state/workspace_provider.dart';
import '../../../state/theme_provider.dart';

/// Top header app bar for Tack home screen.
/// Clean, playful-professional header with "Hey Tack" greeting.
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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workspace = context.watch<WorkspaceProvider>();
    final themeProv = context.watch<ThemeProvider>();

    final iconColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: AppSpacing.md,
      title: Row(
        children: [
          // Drawer Menu Button
          IconButton(
            onPressed: onOpenDrawer,
            icon: TackIcon(TackIcons.menu, size: 24, color: iconColor),
            style: IconButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(40, 40),
            ),
            tooltip: 'Navigation Menu',
          ),
          const SizedBox(width: AppSpacing.sm),

          // Clean, Playful Greeting "Hey Tack"
          Expanded(
            child: Text(
              'Hey Tack',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
      actions: [
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
            size: 20,
            color: iconColor,
          ),
          tooltip: workspace.viewMode == HomeViewMode.notebook
              ? 'Switch to Grid View'
              : 'Switch to List View',
          style: IconButton.styleFrom(
            minimumSize: const Size(38, 38),
            padding: EdgeInsets.zero,
          ),
        ),

        // Search Toggle Button
        IconButton(
          onPressed: onToggleSearch,
          icon: TackIcon(
            isSearching ? TackIcons.close : TackIcons.search,
            size: 20,
            color: iconColor,
          ),
          tooltip: isSearching ? 'Close Search' : 'Search Notes',
          style: IconButton.styleFrom(
            minimumSize: const Size(38, 38),
            padding: EdgeInsets.zero,
          ),
        ),

        // Quick Theme Switch
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
