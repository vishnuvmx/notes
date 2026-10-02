import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/base_item.dart';
import '../../../domain/models/text_note.dart';
import '../../../domain/models/sticky_note.dart';
import '../../../domain/services/note_export_service.dart';
import '../../../state/workspace_provider.dart';
import '../feedback/tack_toast.dart';

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
      showDragHandle: true,
      useSafeArea: true,
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
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                TackToast.show(
                  context,
                  message: widget.item.isFavorite ? 'Removed from Favorites' : 'Added to Favorites',
                  icon: TackIcons.star,
                  iconColor: widget.item.isFavorite ? AppColors.lightTextMuted : AppColors.accentAmber,
                );
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
                TackToast.show(
                  context,
                  message: 'Note duplicated',
                  icon: TackIcons.copy,
                  iconColor: AppColors.pastelLavenderLight,
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

            // Action: Export as Image (PNG)
            _buildActionTile(
              title: widget.item is StickyNote ? 'Export Sticky as Image (PNG)' : 'Export as Image (PNG)',
              isDark: isDark,
              onTap: () {
                Navigator.of(context).pop();
                final content = _getItemContent();
                final tags = widget.item is TextNote ? (widget.item as TextNote).tags : <String>[];
                NoteExportService.exportImage(
                  title: title,
                  content: content,
                  tags: tags,
                  paletteId: widget.item.paletteId,
                  isSticky: widget.item is StickyNote,
                  isDark: isDark,
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
                TackToast.show(
                  context,
                  message: 'Moved note to trash',
                  icon: TackIcons.trash,
                  iconColor: AppColors.error,
                  duration: const Duration(seconds: 4),
                  actionLabel: 'Undo',
                  onAction: () {
                    workspace.restoreItem(widget.item.id);
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
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
