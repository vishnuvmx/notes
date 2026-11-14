import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/tack_icons.dart';
import '../../core/utils/date_formatter.dart';
import '../models/base_item.dart';
import '../../features/notes/models/text_note.dart';
import '../../features/notes/services/note_export_service.dart';
import '../../core/services/pinned_notification_service.dart';
import '../providers/workspace_provider.dart';
import 'app_bottom_sheet.dart';
import 'color_swatch_picker.dart';

/// Card Long-Press Peek & Action Sheet (`05-information-architecture.md` §5, `07-design-system.md` §7).
///
/// Replaces the old 3-item action sheet with a rich preview + full item actions:
/// - 3-line content preview (`title`, `body-sm` snippet, `caption` metadata)
/// - Quick color band selector
/// - Open, Pin/Unpin, Move to folder, Duplicate, Share, and Move to Trash (with Undo toast)
class CardPeekSheet extends StatefulWidget {
  final BaseWorkspaceItem item;
  final VoidCallback onOpen;

  const CardPeekSheet({
    super.key,
    required this.item,
    required this.onOpen,
  });

  static Future<void> show({
    required BuildContext context,
    required BaseWorkspaceItem item,
    required VoidCallback onOpen,
  }) {
    HapticFeedback.mediumImpact();
    return AppBottomSheet.show<void>(
      context: context,
      builder: (ctx) => CardPeekSheet(item: item, onOpen: onOpen),
    );
  }

  @override
  State<CardPeekSheet> createState() => _CardPeekSheetState();
}

class _CardPeekSheetState extends State<CardPeekSheet> {
  late BaseWorkspaceItem _currentItem;
  bool _showFolderPicker = false;
  bool _isNotifPinned = false;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
    PinnedNotificationService.isNotePinned(widget.item.id).then((pinned) {
      if (mounted) setState(() => _isNotifPinned = pinned);
    });
  }

  Future<void> _updatePalette(String paletteId) async {
    final workspace = context.read<WorkspaceProvider>();
    final updated = _currentItem.copyWith(
      paletteId: paletteId,
      updatedAt: DateTime.now(),
    );
    setState(() => _currentItem = updated);
    await workspace.saveItem(updated);
  }

  Future<void> _updateFolder(String? folderName) async {
    final workspace = context.read<WorkspaceProvider>();
    final updated = _currentItem.copyWith(
      folderName: folderName,
      clearFolder: folderName == null,
      updatedAt: DateTime.now(),
    );
    setState(() {
      _currentItem = updated;
      _showFolderPicker = false;
    });
    await workspace.saveItem(updated);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final workspace = context.watch<WorkspaceProvider>();
    final palette = AppColors.getPaletteById(_currentItem.paletteId);
    final bandColor = palette.resolveCardColor(tokens.isDark);
    final softFill = palette.resolveSoftBackground(tokens.isDark);
    final summary = _currentItem.getSummary();

    return SingleChildScrollView(
      padding: AppSpacing.modalSheetPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Regent-style 3-line Content Peek Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.s3),
            decoration: BoxDecoration(
              color: softFill,
              borderRadius: AppSpacing.roundedMd,
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: AppSpacing.cardColorBandWidth,
                    decoration: BoxDecoration(
                      color: bandColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _currentItem.title.trim().isEmpty
                                    ? 'Untitled'
                                    : _currentItem.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleSm(
                                  color: tokens.textPrimary,
                                ),
                              ),
                            ),
                            if (_currentItem.isFavorite) ...[
                              const SizedBox(width: AppSpacing.s2),
                              TackPinBadge(color: tokens.accentPin),
                            ],
                          ],
                        ),
                        if (summary.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.s1),
                          Text(
                            summary,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySm(
                              color: tokens.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.s2),
                        Text(
                          [
                            _currentItem.type.label,
                            if (_currentItem.folderName != null &&
                                _currentItem.folderName!.isNotEmpty)
                              _currentItem.folderName!,
                            'Updated ${DateFormatter.formatTimestamp(_currentItem.updatedAt)}',
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption(
                            color: tokens.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.s3),

          // 2. Quick Color Band Swatches
          ColorSwatchPicker(
            selectedPaletteId: _currentItem.paletteId,
            onPaletteSelected: _updatePalette,
          ),

          if (_showFolderPicker && workspace.userFolders.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s3),
            Wrap(
              spacing: AppSpacing.s2,
              runSpacing: AppSpacing.s2,
              children: [
                _FolderOptionChip(
                  label: 'No folder',
                  isSelected: _currentItem.folderName == null,
                  onTap: () => _updateFolder(null),
                ),
                ...workspace.userFolders.map(
                  (folder) => _FolderOptionChip(
                    label: folder,
                    isSelected: _currentItem.folderName == folder,
                    onTap: () => _updateFolder(folder),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.s2),
          Divider(height: 1, color: tokens.borderSubtle),
          const SizedBox(height: AppSpacing.s1),

          // 3. Action Rows (48dp minimum height each)
          _PeekActionRow(
            icon: TackIcons.notes,
            label: 'Open ${_currentItem.type.label.toLowerCase()}',
            onTap: () {
              Navigator.of(context).pop();
              widget.onOpen();
            },
          ),
          _PeekActionRow(
            icon: TackIcons.pin,
            iconColor: _currentItem.isFavorite ? tokens.accentPin : null,
            label: _currentItem.isFavorite ? 'Unpin' : 'Pin to top',
            onTap: () async {
              Navigator.of(context).pop();
              await workspace.toggleFavorite(_currentItem.id);
            },
          ),
          if (workspace.userFolders.isNotEmpty)
            _PeekActionRow(
              icon: TackIcons.folder,
              label: _currentItem.folderName != null
                  ? 'Folder · ${_currentItem.folderName}'
                  : 'Move to folder…',
              onTap: () => setState(() => _showFolderPicker = !_showFolderPicker),
            ),
          _PeekActionRow(
            icon: TackIcons.copy,
            label: 'Duplicate',
            onTap: () async {
              final messenger = ScaffoldMessenger.maybeOf(context);
              Navigator.of(context).pop();
              await workspace.duplicateItem(_currentItem);
              messenger?.showSnackBar(
                const SnackBar(
                  content: Text('Duplicated'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          if (_currentItem is TextNote)
            _PeekActionRow(
              icon: TackIcons.notification,
              label: _isNotifPinned
                  ? 'Unpin from Notification Bar'
                  : 'Pin to Notification Bar',
              onTap: () async {
                final item = _currentItem;
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.maybeOf(context);
                if (_isNotifPinned) {
                  await PinnedNotificationService.unpinNote(item.id);
                  if (mounted) nav.pop();
                  messenger?.showSnackBar(
                    const SnackBar(
                      content: Text('Unpinned from notification bar'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  final ok = await PinnedNotificationService.pinNote(item);
                  if (mounted) nav.pop();
                  messenger?.showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'Pinned to notification bar'
                            : 'Enable notifications to pin notes',
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          if (_currentItem is TextNote)
            _PeekActionRow(
              icon: TackIcons.share,
              label: 'Share note',
              onTap: () async {
                final note = _currentItem as TextNote;
                Navigator.of(context).pop();
                await NoteExportService.shareNote(
                  title: note.title,
                  content: note.content,
                  tags: note.tags,
                );
              },
            ),
          _PeekActionRow(
            icon: TackIcons.trash,
            iconColor: tokens.danger,
            labelColor: tokens.danger,
            label: 'Move to Trash',
            onTap: () async {
              final itemId = _currentItem.id;
              final itemTitle = _currentItem.title;
              final messenger = ScaffoldMessenger.maybeOf(context);
              Navigator.of(context).pop();
              await workspace.moveToTrash(itemId);
              messenger?.showSnackBar(
                SnackBar(
                  content: Text('Moved "$itemTitle" to Trash'),
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      workspace.restoreFromTrash(itemId);
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PeekActionRow extends StatelessWidget {
  final dynamic icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _PeekActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final fg = labelColor ?? tokens.textPrimary;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: AppSpacing.roundedSm,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.minTouchTarget,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
          child: Row(
            children: [
              TackIcon(
                icon,
                size: 20,
                color: iconColor ?? fg,
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body(
                    color: fg,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderOptionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FolderOptionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.roundedSm,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s3,
          vertical: AppSpacing.s2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? tokens.actionPrimary : tokens.canvasPrimary,
          borderRadius: AppSpacing.roundedSm,
          border: Border.all(
            color: isSelected ? tokens.actionPrimary : tokens.borderSubtle,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.label(
            color: isSelected ? tokens.actionPrimaryFg : tokens.textPrimary,
            weight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

