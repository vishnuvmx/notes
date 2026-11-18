import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/models/base_item.dart';
import '../../whiteboard/models/whiteboard_item.dart';
import '../../../shared/providers/workspace_provider.dart';
import '../../whiteboard/widgets/board_grid_card.dart';
import '../../../shared/widgets/neo_note_card.dart';
import '../../../shared/widgets/responsive_card_grid.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/app_floating_dialog.dart';
import '../../../shared/widgets/card_peek_sheet.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/tack_toast.dart';
import '../../tasks/screens/today_screen.dart';

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
    final tokens = context.tokens;
    final title = item.title.trim().isEmpty ? 'Untitled' : item.title;
    final confirmed = await AppFloatingDialog.confirm(
      context: context,
      title: 'Delete forever?',
      message:
          '"$title" will be permanently deleted and cannot be recovered.',
      confirmLabel: 'Delete forever',
      isDestructive: true,
      icon: TackIcons.trash,
    );
    if (!confirmed) return;
    try {
      await workspace.deletePermanently(item.id);
      if (context.mounted) {
        TackToast.show(
          context,
          message: 'Deleted forever',
          icon: TackIcons.trash,
          iconColor: tokens.danger,
        );
      }
    } catch (_) {
      if (context.mounted) {
        TackToast.show(
          context,
          message: 'Could not delete item',
          icon: TackIcons.close,
          iconColor: tokens.danger,
        );
      }
    }
  }

  Future<void> _confirmEmptyTrash(
    BuildContext context,
    WorkspaceProvider workspace,
  ) async {
    final tokens = context.tokens;
    final confirmed = await AppFloatingDialog.confirm(
      context: context,
      title: 'Empty Trash?',
      message:
          'All items in Trash will be permanently deleted. This cannot be undone.',
      confirmLabel: 'Empty Trash',
      isDestructive: true,
      icon: TackIcons.trash,
    );
    if (!confirmed) return;
    try {
      await workspace.emptyTrash();
      if (context.mounted) {
        TackToast.show(
          context,
          message: 'Emptied Trash',
          icon: TackIcons.trash,
          iconColor: tokens.danger,
        );
      }
    } catch (_) {
      if (context.mounted) {
        TackToast.show(
          context,
          message: 'Could not empty Trash',
          icon: TackIcons.close,
          iconColor: tokens.danger,
        );
      }
    }
  }

  Future<void> _restoreItem(
    BuildContext context,
    WorkspaceProvider workspace,
    BaseWorkspaceItem item,
  ) async {
    final tokens = context.tokens;
    try {
      await workspace.restoreFromTrash(item.id);
      if (context.mounted) {
        TackToast.show(
          context,
          message: 'Restored from Trash',
          icon: TackIcons.check,
          iconColor: tokens.success,
        );
      }
    } catch (_) {
      if (context.mounted) {
        TackToast.show(
          context,
          message: 'Could not restore item',
          icon: TackIcons.close,
          iconColor: tokens.danger,
        );
      }
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
        final summary = item.getSummary().trim();
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s5,
            AppSpacing.s4,
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
              if (summary.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s3),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: SingleChildScrollView(
                    child: Text(
                      summary,
                      style: AppTypography.bodySm(color: tokens.textSecondary),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.s5),
              LayoutBuilder(
                builder: (layoutCtx, constraints) {
                  final stacked = constraints.maxWidth < 300;
                  final deleteBtn = OutlinedButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await _confirmDeleteSingle(context, workspace, item);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                        AppSpacing.minTouchTarget,
                      ),
                      foregroundColor: tokens.danger,
                      side: BorderSide(color: tokens.danger.withValues(alpha: 0.45)),
                    ),
                    child: const Text(
                      'Delete forever',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                  final restoreBtn = ElevatedButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await _restoreItem(context, workspace, item);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                        AppSpacing.minTouchTarget,
                      ),
                    ),
                    child: const Text(
                      'Restore',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                  if (stacked) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        restoreBtn,
                        const SizedBox(height: AppSpacing.s2),
                        deleteBtn,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: deleteBtn),
                      const SizedBox(width: AppSpacing.s3),
                      Expanded(child: restoreBtn),
                    ],
                  );
                },
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
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  AppSpacing.minTouchTarget,
                  AppSpacing.minTouchTarget,
                ),
              ),
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
              icon: switch (folderType) {
                FolderType.trash => TackIcons.trash,
                FolderType.archive => TackIcons.inbox,
                FolderType.favorites => TackIcons.pin,
              },
              title: 'No items in ${folderType.title}',
              subtitle: switch (folderType) {
                FolderType.trash =>
                  'Deleted notes and boards rest here until you empty Trash.',
                FolderType.archive => 'Archived notes and boards appear here.',
                FolderType.favorites => 'Pinned notes and boards appear here.',
              },
              actionLabel: 'Go back',
              actionIcon: TackIcons.back,
              onAction: () => Navigator.of(context).pop(),
            )
          : folderType == FolderType.trash
              ? SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSpacing.readMaxWidth,
                      ),
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          gutter,
                          AppSpacing.s3,
                          gutter,
                          AppSpacing.s8 + MediaQuery.paddingOf(context).bottom,
                        ),
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.s3),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final palette = AppColors.getPaletteById(
                            item.paletteId,
                          );
                          final bandColor = palette.resolveCardColor(
                            tokens.isDark,
                          );

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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                            constraints: const BoxConstraints(
                                              minWidth:
                                                  AppSpacing.minTouchTarget,
                                              minHeight:
                                                  AppSpacing.minTouchTarget,
                                            ),
                                            icon: TackIcon(
                                              TackIcons.undo,
                                              size: 19,
                                              color: tokens.textPrimary,
                                            ),
                                            tooltip: 'Restore',
                                            onPressed: () => _restoreItem(
                                              context,
                                              workspace,
                                              item,
                                            ),
                                          ),
                                          IconButton(
                                            constraints: const BoxConstraints(
                                              minWidth:
                                                  AppSpacing.minTouchTarget,
                                              minHeight:
                                                  AppSpacing.minTouchTarget,
                                            ),
                                            icon: TackIcon(
                                              TackIcons.trash,
                                              size: 19,
                                              color: tokens.danger,
                                            ),
                                            tooltip: 'Delete forever',
                                            onPressed: () =>
                                                _confirmDeleteSingle(
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
                      ),
                    ),
                  ),
                )
              : SafeArea(
                  top: false,
                  child: ResponsiveCardGrid(
                    padding: EdgeInsets.fromLTRB(
                      gutter,
                      AppSpacing.s3,
                      gutter,
                      AppSpacing.s8 + MediaQuery.paddingOf(context).bottom,
                    ),
                  crossAxisCount: cols,
                  mainAxisSpacing: AppSpacing.cardGridGap,
                  crossAxisSpacing: AppSpacing.cardGridGap,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item is WhiteboardCanvasItem) {
                      return BoardGridCard(
                        board: item,
                        openBuilder: (_) => buildWorkspaceItemDetailScreen(item),
                        onPeek: (openDetail) => CardPeekSheet.show(
                          context: context,
                          item: item,
                          onOpen: openDetail,
                        ),
                      );
                    }
                    return NeoNoteCard(
                      item: item,
                      openBuilder: (_) => buildWorkspaceItemDetailScreen(item),
                      onPeek: (openDetail) => CardPeekSheet.show(
                        context: context,
                        item: item,
                        onOpen: openDetail,
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
