import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../state/workspace_provider.dart';

/// Navigation Drawer for secondary destinations (Favorites, Archive, Trash, Settings).
class AppNavDrawer extends StatelessWidget {
  final VoidCallback? onOpenFavorites;
  final VoidCallback? onOpenArchive;
  final VoidCallback? onOpenTrash;
  final VoidCallback? onOpenSettings;

  const AppNavDrawer({
    super.key,
    this.onOpenFavorites,
    this.onOpenArchive,
    this.onOpenTrash,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workspace = context.watch<WorkspaceProvider>();

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(AppSpacing.radiusLg)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer Header with Tack icon and branding
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
                      borderRadius: AppSpacing.roundedMd,
                      boxShadow: isDark ? AppSpacing.softShadowDark : AppSpacing.softShadowLight,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(Icons.push_pin_rounded),

                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tack',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        'Tactile notes & canvas',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),

            // Primary Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                children: [
                  _buildDrawerTile(
                    context,
                    icon: Icons.grid_view_rounded,
                    title: 'All Notes',
                    badgeCount: workspace.items.length,
                    onTap: () {
                      Navigator.of(context).pop();
                      workspace.setCategory(null);
                    },
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.star_rounded,
                    iconColor: AppColors.accentAmber,
                    title: 'Favorites',
                    badgeCount: workspace.favoriteItems.length,
                    onTap: () {
                      Navigator.of(context).pop();
                      onOpenFavorites?.call();
                    },
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.archive_outlined,
                    title: 'Archived',
                    badgeCount: workspace.archivedItems.length,
                    onTap: () {
                      Navigator.of(context).pop();
                      onOpenArchive?.call();
                    },
                  ),
                  _buildDrawerTile(
                    context,
                    icon: Icons.delete_outline_rounded,
                    iconColor: AppColors.error,
                    title: 'Trash',
                    badgeCount: workspace.trashItems.length,
                    onTap: () {
                      Navigator.of(context).pop();
                      onOpenTrash?.call();
                    },
                  ),
                ],
              ),
            ),

            const Divider(),

            // Settings & About
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Column(
                children: [
                  _buildDrawerTile(
                    context,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.of(context).pop();
                      onOpenSettings?.call();
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Version 1.0.0',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        Text(
                          'Flutter Android',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color? iconColor,
    int? badgeCount,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        size: 22,
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
      trailing: badgeCount != null && badgeCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
                borderRadius: AppSpacing.roundedPill,
              ),
              child: Text(
                '$badgeCount',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            )
          : null,
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
      onTap: onTap,
    );
  }
}
