import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../state/workspace_provider.dart';
import '../../../state/theme_provider.dart';

/// Top header app bar for the Tack home screen.
/// Includes drawer menu trigger, Tack brand icon & title, subtitle, search toggle, view toggle, and theme switch.
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

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drawer Hamburger Button
            IconButton(
              onPressed: onOpenDrawer,
              icon: const Icon(Icons.menu_rounded, size: 28),
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
                          errorBuilder: (_, _, _) => const Icon(Icons.push_pin_rounded, size: 20),

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
              icon: Icon(
                workspace.viewMode == HomeViewMode.notebook
                    ? Icons.grid_view_rounded
                    : Icons.view_agenda_outlined,
                size: 22,
              ),
              tooltip: workspace.viewMode == HomeViewMode.notebook
                  ? 'Switch to Sticky Grid'
                  : 'Switch to Notebook List',
            ),

            // Search Toggle Button
            IconButton(
              onPressed: onToggleSearch,
              icon: Icon(
                isSearching ? Icons.close_rounded : Icons.search_rounded,
                size: 24,
              ),
              tooltip: isSearching ? 'Close Search' : 'Search Notes',
            ),

            // Quick Theme Toggle Button
            IconButton(
              onPressed: () => themeProv.toggleTheme(context),
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
                size: 22,
              ),
              tooltip: isDark ? 'Switch to Light' : 'Switch to Dark',
            ),
          ],
        ),
      ),
    );
  }
}
