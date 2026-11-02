import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../domain/models/base_item.dart';
import '../../../state/workspace_provider.dart';
import '../../screens/editor/note_editor_screen.dart';
import '../../screens/graph/knowledge_graph_screen.dart';

/// Navigation Drawer for secondary destinations, Daily Notes, Knowledge Graph, and Folders.
class AppNavDrawer extends StatelessWidget {
  final VoidCallback? onOpenFavorites;
  final VoidCallback? onOpenArchive;
  final VoidCallback? onOpenTrash;
  final VoidCallback? onOpenSettings;
  final ValueChanged<BaseWorkspaceItem>? onOpenItem;

  const AppNavDrawer({
    super.key,
    this.onOpenFavorites,
    this.onOpenArchive,
    this.onOpenTrash,
    this.onOpenSettings,
    this.onOpenItem,
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
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const TackIcon(TackIcons.pin),
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
                          'Connected specs & notes',
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

            // Scrollable Middle: Primary Navigation + Folders
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                children: [
                  _buildDrawerTile(
                    context,
                    icon: TackIcons.sun,
                    iconColor: AppColors.accentAmber,
                    title: "Today's Note",
                    onTap: () async {
                      final nav = Navigator.of(context);
                      nav.pop();
                      final daily = await workspace.openOrCreateTodaysNote();
                      if (onOpenItem != null) {
                        onOpenItem!(daily);
                      } else {
                        nav.push(
                          MaterialPageRoute(builder: (_) => NoteEditorScreen(item: daily)),
                        );
                      }
                    },
                  ),
                  _buildDrawerTile(
                    context,
                    icon: LucideIcons.network,
                    iconColor: AppColors.accentCyan,
                    title: 'Knowledge Graph',
                    onTap: () {
                      final nav = Navigator.of(context);
                      nav.pop();
                      nav.push(
                        MaterialPageRoute(builder: (_) => const KnowledgeGraphScreen()),
                      );
                    },
                  ),
                  _buildDrawerTile(
                    context,
                    icon: TackIcons.gridView,
                    title: 'All Notes',
                    badgeCount: workspace.rawItems.length,
                    onTap: () {
                      Navigator.of(context).pop();
                      workspace.setCategory(null);
                      workspace.setSelectedFolder('All Notes');
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
                  if (onOpenArchive != null)
                    _buildDrawerTile(
                      context,
                      icon: TackIcons.archive,
                      title: 'Archive',
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
                  if (workspace.userFolders.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Divider(height: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Text(
                        'FOLDERS',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ),
                    ...workspace.userFolders.map((folder) {
                      final count = workspace.rawItems
                          .where((i) =>
                              !i.isTrash &&
                              !i.isArchived &&
                              (i.folderName ?? '').toLowerCase() == folder.toLowerCase())
                          .length;
                      return _buildDrawerTile(
                        context,
                        icon: LucideIcons.folder,
                        title: folder,
                        badgeCount: count,
                        onTap: () {
                          Navigator.of(context).pop();
                          workspace.setCategory(null);
                          workspace.setSelectedFolder(folder);
                        },
                        onLongPress: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text('Remove "$folder"?'),
                              content: const Text(
                                'Notes inside this folder will stay safe in All Notes.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await workspace.deleteFolder(folder);
                          }
                        },
                      );
                    }),
                  ],
                ],
              ),
            ),

            const Divider(height: 1),

            // Bottom-Pinned: Settings & Version Information
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Version 2.0.0',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        Text(
                          'Local-First Markdown',
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
    dynamic style,
    int? badgeCount,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
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
      onLongPress: onLongPress,
    );
  }
}
