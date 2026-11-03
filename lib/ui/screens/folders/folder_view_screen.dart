import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../domain/models/base_item.dart';
import '../../../state/workspace_provider.dart';
import '../../components/cards/neo_note_card.dart';
import '../../components/feedback/empty_state_widget.dart';
import '../../components/dialogs_sheets/note_action_sheet.dart';

enum FolderType {
  favorites,
  archive,
  trash;

  String get title {
    switch (this) {
      case FolderType.favorites:
        return 'Favorites';
      case FolderType.archive:
        return 'Archived Notes';
      case FolderType.trash:
        return 'Trash';
    }
  }
}

/// Dedicated Folder screen for Favorites, Archive, or Trash with cute HeroIcons.
class FolderViewScreen extends StatelessWidget {
  final FolderType folderType;
  final Function(BaseWorkspaceItem item)? onOpenItem;

  const FolderViewScreen({
    super.key,
    required this.folderType,
    this.onOpenItem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workspace = context.watch<WorkspaceProvider>();

    List<BaseWorkspaceItem> items;
    switch (folderType) {
      case FolderType.favorites:
        items = workspace.favoriteItems;
        break;
      case FolderType.archive:
        items = workspace.archivedItems;
        break;
      case FolderType.trash:
        items = workspace.trashItems;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(folderType.title),
        actions: [
          if (folderType == FolderType.trash && items.isNotEmpty)
            TextButton.icon(
              icon: const TackIcon(TackIcons.trash, size: 18, color: AppColors.error),
              label: const Text('Empty', style: TextStyle(color: AppColors.error)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Empty Trash?'),
                    content: const Text('All notes in the trash will be permanently deleted.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                        onPressed: () {
                          workspace.emptyTrash();
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Empty Trash'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: items.isEmpty
          ? EmptyStateWidget(
              icon: folderType == FolderType.trash
                  ? TackIcons.trash
                  : (folderType == FolderType.favorites ? TackIcons.star : TackIcons.archive),
              title: 'No items in ${folderType.title}',
              subtitle: 'Items you ${folderType.name} will appear here.',
            )
          : folderType == FolderType.trash
              ? ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF323642) : const Color(0xFF191A23),
                          width: 1.5,
                        ),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: const Color(0xFF191A23).withValues(alpha: 0.06),
                                  blurRadius: 0,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        subtitle: Text(
                          item.getSummary(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            fontSize: 13,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const TackIcon(TackIcons.redo, size: 20),
                              tooltip: 'Restore',
                              onPressed: () => workspace.restoreItem(item.id),
                            ),
                            IconButton(
                              icon: const TackIcon(TackIcons.trash, size: 20, color: AppColors.error),
                              tooltip: 'Delete Forever',
                              onPressed: () => workspace.deletePermanently(item.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    mainAxisExtent: 220,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return NeoNoteCard(
                      item: item,
                      onTap: () => onOpenItem?.call(item),
                      onLongPress: () => NoteActionSheet.show(context, item: item),
                      isGrid: true,
                    );
                  },
                ),
    );
  }
}
