import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/base_item.dart';
import '../../../state/workspace_provider.dart';
import '../../components/cards/smart_note_list_card.dart';
import '../../components/feedback/empty_state_widget.dart';

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

/// Dedicated Folder screen for Favorites, Archive, or Trash.
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
              icon: const Icon(Icons.delete_forever_rounded, size: 18, color: AppColors.error),
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
                  ? Icons.delete_outline_rounded
                  : (folderType == FolderType.favorites ? Icons.star_outline_rounded : Icons.archive_outlined),
              title: 'No items in ${folderType.title}',
              subtitle: 'Items you ${folderType.name} will appear here.',
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                if (folderType == FolderType.trash) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: AppSpacing.roundedMd,
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: ListTile(
                      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(item.getSummary(), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.restore_from_trash_rounded, size: 20),
                            tooltip: 'Restore',
                            onPressed: () => workspace.restoreItem(item.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_forever_rounded, size: 20, color: AppColors.error),
                            tooltip: 'Delete Forever',
                            onPressed: () => workspace.deletePermanently(item.id),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SmartNoteListCard(
                  item: item,
                  index: index,
                  onTap: () => onOpenItem?.call(item),
                );
              },
            ),
    );
  }
}
