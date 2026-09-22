import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/base_item.dart';
import '../../../domain/models/text_note.dart';
import '../../../domain/models/sticky_note.dart';
import '../../../domain/services/note_export_service.dart';
import '../../../domain/services/pinned_notification_service.dart';
import '../../../state/workspace_provider.dart';

/// Modal bottom sheet triggered on long press of any workspace card.
/// Provides quick actions for Favorites, Pin to Status Bar, Duplicate, Share, and Delete.
class NoteActionSheet extends StatefulWidget {
  final BaseWorkspaceItem item;
  final VoidCallback? onOpen;

  const NoteActionSheet({
    super.key,
    required this.item,
    this.onOpen,
  });

  /// Displays the NoteActionSheet modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required BaseWorkspaceItem item,
    VoidCallback? onOpen,
  }) {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => NoteActionSheet(item: item, onOpen: onOpen),
    );
  }

  @override
  State<NoteActionSheet> createState() => _NoteActionSheetState();
}

class _NoteActionSheetState extends State<NoteActionSheet> {
  bool _isPinnedToStatusBar = false;

  @override
  void initState() {
    super.initState();
    PinnedNotificationService.isNotePinned(widget.item.id).then((pinned) {
      if (mounted) setState(() => _isPinnedToStatusBar = pinned);
    });
  }

  String _getItemContent() {
    if (widget.item is TextNote) {
      return (widget.item as TextNote).content;
    } else if (widget.item is StickyNote) {
      return (widget.item as StickyNote).content;
    }
    return widget.item.getSummary();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workspace = context.read<WorkspaceProvider>();
    final palette = AppColors.getPaletteById(widget.item.paletteId);

    final title = widget.item.title.trim().isEmpty ? 'Untitled Note' : widget.item.title.trim();
    final summary = widget.item.getSummary();
    final dateStr = DateFormatter.formatTimestamp(widget.item.updatedAt);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Note Header Preview
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: palette.lightColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: palette.lightColor.withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          summary.isNotEmpty ? summary : dateStr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Action: Favorite
            _buildActionTile(
              title: widget.item.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
              isDark: isDark,
              onTap: () {
                HapticFeedback.lightImpact();
                workspace.toggleFavorite(widget.item.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.item.isFavorite ? 'Removed from Favorites' : 'Added to Favorites',
                    ),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),

            // Action: Pin to Status Bar
            _buildActionTile(
              title: _isPinnedToStatusBar ? 'Unpin from Status Bar' : 'Pin to Status Bar',
              isDark: isDark,
              onTap: () async {
                HapticFeedback.lightImpact();
                final content = _getItemContent();
                final newPinned = await PinnedNotificationService.togglePinNote(
                  id: widget.item.id,
                  title: title,
                  content: content,
                  paletteId: widget.item.paletteId,
                );
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        newPinned
                            ? 'Note pinned to Android status bar!'
                            : 'Note unpinned from status bar',
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),

            // Action: Duplicate Note
            _buildActionTile(
              title: 'Duplicate Note',
              isDark: isDark,
              onTap: () {
                HapticFeedback.lightImpact();
                workspace.duplicateItem(widget.item.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Note duplicated!'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),

            // Action: Share Markdown
            _buildActionTile(
              title: 'Share Markdown',
              isDark: isDark,
              onTap: () {
                Navigator.of(context).pop();
                final content = _getItemContent();
                final tags = widget.item is TextNote ? (widget.item as TextNote).tags : <String>[];
                NoteExportService.shareNote(
                  title: title,
                  content: content,
                  tags: tags,
                );
              },
            ),

            // Action: Export as PDF
            _buildActionTile(
              title: 'Export as PDF',
              isDark: isDark,
              onTap: () {
                Navigator.of(context).pop();
                final content = _getItemContent();
                final tags = widget.item is TextNote ? (widget.item as TextNote).tags : <String>[];
                NoteExportService.exportPdf(
                  title: title,
                  content: content,
                  tags: tags,
                  paletteId: widget.item.paletteId,
                );
              },
            ),

            const Divider(height: 16),

            // Action: Delete (Move to Trash)
            _buildActionTile(
              title: 'Delete Note',
              isDestructive: true,
              isDark: isDark,
              onTap: () {
                HapticFeedback.mediumImpact();
                workspace.moveToTrash(widget.item.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Moved note to trash'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 4),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: AppColors.accentAmber,
                      onPressed: () {
                        workspace.restoreItem(widget.item.id);
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    bool isDestructive = false,
  }) {
    final textColor = isDestructive
        ? AppColors.error
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
