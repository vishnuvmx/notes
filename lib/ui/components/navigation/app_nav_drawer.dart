import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../state/workspace_provider.dart';

/// Navigation Drawer for secondary destinations with cute HeroIcons.
/// Fully responsive across all Android device heights and orientations.
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
        child: ListView(
          padding: EdgeInsets.zero,
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
                      shape: BoxShape.circle,
                      boxShadow: isDark ? AppSpacing.softShadowDark : AppSpacing.softShadowLight,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const TackIcon(TackIcons.pin),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
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
                          'Your tactile brain garden 🌱',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Primary Navigation Items with cute HeroIcons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Column(
                children: [
                  _buildDrawerTile(
                    context,
                    icon: TackIcons.gridView,
                    title: 'All Notes',
                    badgeCount: workspace.rawItems.length,
                    onTap: () {
                      Navigator.of(context).pop();
                      workspace.setCategory(null);
                    },
                  ),
                  _buildDrawerTile(
                    context,
                    icon: TackIcons.star,
                    iconColor: AppColors.accentAmber,
                    style: HeroIconStyle.solid,
                    title: 'Favorites',
                    badgeCount: workspace.favoriteItems.length,
                    onTap: () {
                      Navigator.of(context).pop();
                      onOpenFavorites?.call();
                    },
                  ),
                  _buildDrawerTile(
                    context,
                    icon: TackIcons.archive,
                    title: 'Archived',
                    badgeCount: workspace.archivedItems.length,
                    onTap: () {
                      Navigator.of(context).pop();
                      onOpenArchive?.call();
                    },
                  ),
                  _buildDrawerTile(
                    context,
                    icon: TackIcons.trash,
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

            const Divider(height: 1),

            // Settings & About
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Column(
                children: [
                  _buildDrawerTile(
                    context,
                    icon: TackIcons.settings,
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
    required HeroIcons icon,
    required String title,
    Color? iconColor,
    HeroIconStyle style = HeroIconStyle.outline,
    int? badgeCount,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      leading: TackIcon(
        icon,
        color: iconColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        size: 22,
        style: style,
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
