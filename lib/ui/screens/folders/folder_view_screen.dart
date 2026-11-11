import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/base_item.dart';
import '../../../domain/models/whiteboard_item.dart';
import '../../../state/workspace_provider.dart';
import '../../components/cards/board_grid_card.dart';
import '../../components/cards/neo_note_card.dart';
import '../../components/cards/responsive_card_grid.dart';
import '../../components/dialogs_sheets/app_bottom_sheet.dart';
import '../../components/dialogs_sheets/app_floating_dialog.dart';
import '../../components/dialogs_sheets/card_peek_sheet.dart';
import '../../components/feedback/empty_state_widget.dart';
import '../today/today_screen.dart';

enum FolderType {
  favorites,
  archive,
  trash;

  String get title {
    switch (this) {
      case FolderType.favorites:
        return 'Pinned';
      case FolderType.archive:
        return 'Archived';
      case FolderType.trash:
        return 'Trash';
    }
  }
}

/// Dedicated screen for Trash (and legacy Pinned/Archive routes) (`05` §2.1).
/// Includes confirmation on permanent delete and tap-to-preview in Trash (`03` §7 P2).
class FolderViewScreen extends StatelessWidget {
  final FolderType folderType;
  final void Function(BaseWorkspaceItem item)? onOpenItem;

  const FolderViewScreen({
    super.key,
    required this.folderType,
    this.onOpenItem,
  });

  Future<void> _confirmDeleteSingle(
    BuildContext context,
    WorkspaceProvider workspace,
    BaseWorkspaceItem item,
  ) async {
    final title = item.title.trim().isEmpty ? 'Untitled' : item.title;
    final confirmed = await AppFloatingDialog.confirm(
      context: context,
      title: 'Delete permanently?',
      message: '"$title" will be permanently deleted and cannot be recovered.',
      confirmLabel: 'Delete Forever',
      isDestructive: true,
      icon: TackIcons.trash,
    );
    if (confirmed) {
      await workspace.deletePermanently(item.id);
    }
  }

  Future<void> _confirmEmptyTrash(
    BuildContext context,
    WorkspaceProvider workspace,
  ) async {
    final confirmed = await AppFloatingDialog.confirm(
      context: context,
      title: 'Empty Trash?',
      message: 'All items in Trash will be permanently deleted. This cannot be undone.',
      confirmLabel: 'Empty Trash',
      isDestructive: true,
      icon: TackIcons.trash,
    );
    if (confirmed) {
      await workspace.emptyTrash();
    }
  }

  void _previewTrashedItem(
    BuildContext context,
    WorkspaceProvider workspace,
    BaseWorkspaceItem item,
  ) {
    AppBottomSheet.show<void>(
      context: context,
      builder: (ctx) {
        final tokens = ctx.tokens;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s5,
            AppSpacing.s2,
            AppSpacing.s5,
            AppSpacing.s5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.title.trim().isEmpty ? 'Untitled' : item.title,
                style: AppTypography.title(color: tokens.textPrimary),
              ),
              const SizedBox(height: AppSpacing.s1),
              Text(
                'Deleted ${DateFormatter.formatTimestamp(item.updatedAt)}',
                style: AppTypography.caption(color: tokens.textTertiary),
              ),
              const SizedBox(height: AppSpacing.s3),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: SingleChildScrollView(
                  child: Text(
                    item.getSummary(),
                    style: AppTypography.bodySm(color: tokens.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s5),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await _confirmDeleteSingle(context, workspace, item);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: tokens.danger,
                      ),
                      child: const Text('Delete forever'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await workspace.restoreFromTrash(item.id);
                      },
                      child: const Text('Restore'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final workspace = context.watch<WorkspaceProvider>();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final gutter = AppSpacing.screenGutter(screenWidth);
    final cols = AppSpacing.gridColumnsForWidth(screenWidth);

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
      backgroundColor: tokens.canvasPrimary,
      appBar: AppBar(
        backgroundColor: tokens.canvasPrimary,
        leading: IconButton(
          icon: TackIcon(TackIcons.back, size: 20, color: tokens.textPrimary),
          tooltip: 'Back',
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          folderType.title,
          style: AppTypography.title(color: tokens.textPrimary),
        ),
        actions: [
          if (folderType == FolderType.trash && items.isNotEmpty)
            TextButton.icon(
              icon: TackIcon(TackIcons.trash, size: 17, color: tokens.danger),
              label: Text(
                'Empty',
                style: AppTypography.label(
                  color: tokens.danger,
                  weight: FontWeight.w600,
                ),
              ),
              onPressed: () => _confirmEmptyTrash(context, workspace),
            ),
          const SizedBox(width: AppSpacing.s2),
        ],
      ),
      body: items.isEmpty
          ? EmptyStateWidget(
              icon: folderType == FolderType.trash
                  ? TackIcons.trash
                  : TackIcons.pin,
              title: 'No items in ${folderType.title}',
              subtitle: folderType == FolderType.trash
                  ? 'Deleted notes and boards rest here until you empty Trash.'
                  : 'Pinned items appear here.',
            )
          : folderType == FolderType.trash
              ? ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    AppSpacing.s3,
                    gutter,
                    AppSpacing.s8,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.s3),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final palette = AppColors.getPaletteById(item.paletteId);
                    final bandColor = palette.resolveCardColor(tokens.isDark);

                    return Container(
                      decoration: BoxDecoration(
                        color: tokens.surfacePrimary,
                        borderRadius: AppSpacing.roundedMd,
                        border: Border.all(
                          color: tokens.borderSubtle,
                          width: 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: AppSpacing.cardColorBandWidth,
                              color: bandColor,
                            ),
                            Expanded(
                              child: ListTile(
                                onTap: () => _previewTrashedItem(
                                  context,
                                  workspace,
                                  item,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.s4,
                                  vertical: AppSpacing.s1,
                                ),
                                title: Text(
                                  item.title.trim().isEmpty
                                      ? 'Untitled'
                                      : item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.titleSm(
                                    color: tokens.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  item.getSummary(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySm(
                                    color: tokens.textSecondary,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: TackIcon(
                                        TackIcons.undo,
                                        size: 19,
                                        color: tokens.textPrimary,
                                      ),
                                      tooltip: 'Restore',
                                      onPressed: () =>
                                          workspace.restoreFromTrash(item.id),
                                    ),
                                    IconButton(
                                      icon: TackIcon(
                                        TackIcons.trash,
                                        size: 19,
                                        color: tokens.danger,
                                      ),
                                      tooltip: 'Delete Forever',
                                      onPressed: () => _confirmDeleteSingle(
                                        context,
                                        workspace,
                                        item,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : ResponsiveCardGrid(
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    AppSpacing.s3,
                    gutter,
                    AppSpacing.s8,
                  ),
                  crossAxisCount: cols,
                  mainAxisSpacing: AppSpacing.cardGridGap,
                  crossAxisSpacing: AppSpacing.cardGridGap,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    void openFn() {
                      if (onOpenItem != null) {
                        onOpenItem!(item);
                      } else {
                        openWorkspaceItemScreen(context, item);
                      }
                    }
                    if (item is WhiteboardCanvasItem) {
                      return BoardGridCard(
                        board: item,
                        onTap: openFn,
                        onLongPress: () => CardPeekSheet.show(
                          context: context,
                          item: item,
                          onOpen: openFn,
                        ),
                      );
                    }
                    return NeoNoteCard(
                      item: item,
                      onTap: openFn,
                      onLongPress: () => CardPeekSheet.show(
                        context: context,
                        item: item,
                        onOpen: openFn,
                      ),
                    );
                  },
                ),
    );
  }
}
