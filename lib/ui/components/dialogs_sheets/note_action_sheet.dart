import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/base_item.dart';
import '../../../domain/models/text_note.dart';
import '../../../domain/models/sticky_note.dart';
import '../../../domain/models/clipboard_item.dart';
import '../../../domain/services/note_export_service.dart';
import '../../../state/workspace_provider.dart';
import '../feedback/tack_toast.dart';
import 'app_bottom_sheet.dart';

/// Modal bottom sheet triggered on long press of any workspace card.
/// Provides quick actions for Favorites, Pin to Status Bar, Duplicate, Share, and Delete.
/// Includes generous bottom margin clearance to avoid overlapping the Android gesture bar.
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
    return AppBottomSheet.show(
      context: context,
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
    } else if (widget.item is ClipboardItem) {
      return (widget.item as ClipboardItem).clipText;
    }
    return widget.item.getSummary();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workspace = context.read<WorkspaceProvider>();
    final palette = AppColors.getPaletteById(widget.item.paletteId);

    final rawTitle = widget.item.title.trim();
    final isClip = widget.item is ClipboardItem;
    final title = rawTitle.isEmpty
        ? (isClip ? 'Clipboard Snippet' : 'Untitled Note')
        : (isClip && rawTitle == 'Clipboard' ? 'Clipboard Snippet' : rawTitle);

    final summary = widget.item.getSummary();
    final dateStr = DateFormatter.formatTimestamp(widget.item.updatedAt);
    final subText = isClip
        ? '${(widget.item as ClipboardItem).sourceApp}  •  $dateStr'
        : (summary.isNotEmpty ? summary : dateStr);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Preview Card
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
                            subText,
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
              const SizedBox(height: AppSpacing.sm),

              // Clipboard-specific primary action: Copy to Clipboard
              if (isClip) ...[
                _buildActionTile(
                  title: 'Copy to Clipboard',
                  icon: TackIcons.copy,
                  iconColor: palette.resolveAccentColor(isDark),
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    final text = (widget.item as ClipboardItem).clipText;
                    Clipboard.setData(ClipboardData(text: text));
                    Navigator.of(context).pop();
                    TackToast.show(
                      context,
                      message: 'Copied to clipboard',
                      icon: TackIcons.checkCircle,
                      iconColor: AppColors.success,
                      bottomMargin: 88,
                    );
                  },
                ),
                _buildActionTile(
                  title: (widget.item as ClipboardItem).isPinned ? 'Unpin from Top' : 'Pin to Top',
                  icon: TackIcons.pin,
                  iconColor: (widget.item as ClipboardItem).isPinned ? AppColors.accentAmber : null,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    final clip = widget.item as ClipboardItem;
                    workspace.saveItem(clip.copyWith(isPinned: !clip.isPinned));
                    Navigator.of(context).pop();
                    TackToast.show(
                      context,
                      message: clip.isPinned ? 'Unpinned snippet' : 'Pinned snippet to top',
                      icon: TackIcons.pin,
                      iconColor: AppColors.accentAmber,
                      bottomMargin: 88,
                    );
                  },
                ),
              ],

              // Action: Favorite
              _buildActionTile(
                title: widget.item.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                icon: TackIcons.star,
                iconColor: widget.item.isFavorite ? AppColors.accentAmber : null,
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

              // Action: Move to Folder
              if (!isClip)
                _buildActionTile(
                  title: widget.item.folderName != null
                      ? 'Move Folder (${widget.item.folderName})'
                      : 'Move to Folder',
                  icon: LucideIcons.folder,
                  iconColor: AppColors.accentCyan,
                  isDark: isDark,
                  onTap: () async {
                    Navigator.of(context).pop();
                    final chosen = await showModalBottomSheet<String?>(
                      context: context,
                      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (ctx) => SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Move "${widget.item.title}" to Folder',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ListTile(
                                leading: const Icon(LucideIcons.folderX, size: 19),
                                title: const Text('No Folder (All Notes)'),
                                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                                onTap: () => Navigator.of(ctx).pop(''),
                              ),
                              ...workspace.userFolders.map(
                                (f) => ListTile(
                                  leading: const Icon(LucideIcons.folder, size: 19),
                                  title: Text(f),
                                  trailing: widget.item.folderName == f
                                      ? const TackIcon(TackIcons.check, size: 16)
                                      : null,
                                  shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                                  onTap: () => Navigator.of(ctx).pop(f),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                    if (chosen != null) {
                      await workspace.moveItemToFolder(
                        widget.item.id,
                        chosen.isEmpty ? null : chosen,
                      );
                    }
                  },
                ),

              // Action: Duplicate
              _buildActionTile(
                title: isClip ? 'Duplicate Snippet' : 'Duplicate Note',
                icon: TackIcons.copy,
                iconColor: AppColors.pastelLavenderLight,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.lightImpact();
                  workspace.duplicateItem(widget.item.id);
                  Navigator.of(context).pop();
                  TackToast.show(
                    context,
                    message: isClip ? 'Snippet duplicated' : 'Note duplicated',
                    icon: TackIcons.copy,
                    iconColor: AppColors.pastelLavenderLight,
                  );
                },
              ),

              // Action: Share
              _buildActionTile(
                title: isClip ? 'Share Text' : 'Share Markdown',
                icon: TackIcons.share,
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

              // Export actions (for non-clipboard items)
              if (!isClip) ...[
                _buildActionTile(
                  title: 'Export as PDF',
                  icon: TackIcons.notes,
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
                _buildActionTile(
                  title: widget.item is StickyNote ? 'Export Sticky as Image (PNG)' : 'Export as Image (PNG)',
                  icon: TackIcons.photo,
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
              ],

              const Divider(height: 14),

              // Action: Delete (Move to Trash)
              _buildActionTile(
                title: isClip ? 'Delete Snippet' : 'Delete Note',
                icon: TackIcons.trash,
                isDestructive: true,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  workspace.moveToTrash(widget.item.id);
                  Navigator.of(context).pop();
                  TackToast.show(
                    context,
                    message: isClip ? 'Moved clip to trash' : 'Moved note to trash',
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

              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      );
  }

  Widget _buildActionTile({
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    IconData? icon,
    Color? iconColor,
    bool isDestructive = false,
  }) {
    final textColor = isDestructive
        ? AppColors.error
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    final effectiveIconColor = iconColor ?? (isDestructive
        ? AppColors.error
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              if (icon != null) ...[
                TackIcon(
                  icon,
                  size: 19,
                  color: effectiveIconColor,
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
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
            ],
          ),
        ),
      ),
    );
  }
}
