import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../shared/models/base_item.dart';
import '../../whiteboard/models/whiteboard_item.dart';
import '../services/wiki_link_service.dart';

/// Compact keyboard-docked autocomplete bar when typing `[[` or `![[` in the note editor.
class WikiLinkAutocompleteBar extends StatelessWidget {
  final ActiveWikiTrigger trigger;
  final List<BaseWorkspaceItem> workspaceItems;
  final String currentItemId;
  final ValueChanged<String> onSelectCompletion;
  final VoidCallback onDismiss;

  const WikiLinkAutocompleteBar({
    super.key,
    required this.trigger,
    required this.workspaceItems,
    required this.currentItemId,
    required this.onSelectCompletion,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final candidates = workspaceItems
        .where((i) => !i.isTrash && i.id != currentItemId && i.type != ItemType.clipboard)
        .toList();

    // Case 1: User typed `[[Target#` -> suggest Headings (for Notes) or Nodes (for Whiteboards)
    if (trigger.anchorQuery != null) {
      final targetItem = WikiLinkService.resolveTarget(trigger.targetQuery, candidates);
      if (targetItem != null) {
        return _buildAnchorSuggestions(context, targetItem, trigger.anchorQuery!, isDark);
      }
    }

    // Case 2: Suggest matching Notes, Stickies, and Whiteboards
    final query = trigger.targetQuery.trim().toLowerCase();
    final filtered = candidates.where((item) {
      if (query.isEmpty) return true;
      return item.title.toLowerCase().contains(query);
    }).toList();

    // Prioritize Whiteboards when typing `![[` (embed syntax)
    if (trigger.isEmbed) {
      filtered.sort((a, b) {
        final aBoard = a is WhiteboardCanvasItem ? 0 : 1;
        final bBoard = b is WhiteboardCanvasItem ? 0 : 1;
        return aBoard.compareTo(bBoard);
      });
    }

    final exactExists = query.isNotEmpty &&
        candidates.any((i) => i.title.trim().toLowerCase() == query);
    final showCreateNew = !trigger.isEmbed && trigger.targetQuery.trim().isNotEmpty && !exactExists;

    if (filtered.isEmpty && !showCreateNew) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 46,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppSpacing.roundedPill,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: AppSpacing.floatingControlShadow,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              trigger.isEmbed ? 'Embed' : 'Link',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: AppColors.accentAmber,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (showCreateNew)
                  _buildChip(
                    isDark: isDark,
                    icon: TackIcons.plus,
                    accentColor: AppColors.accentAmber,
                    label: 'New "${trigger.targetQuery.trim()}"',
                    onTap: () {
                      final clean = trigger.targetQuery.trim();
                      onSelectCompletion('[[$clean]]');
                    },
                  ),
                for (final item in filtered.take(12))
                  _buildChip(
                    isDark: isDark,
                    icon: item is WhiteboardCanvasItem
                        ? TackIcons.whiteboardSvg
                        : TackIcons.notesSvg,
                    accentColor: AppColors.getPaletteById(item.paletteId).resolveAccentColor(isDark),
                    label: item.title,
                    onTap: () {
                      final prefix = trigger.isEmbed ? '![[' : '[[';
                      onSelectCompletion('$prefix${item.title}]]');
                    },
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const TackIcon(TackIcons.close, size: 15),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            onPressed: onDismiss,
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }

  Widget _buildAnchorSuggestions(
    BuildContext context,
    BaseWorkspaceItem targetItem,
    String anchorQuery,
    bool isDark,
  ) {
    final lowerAnchor = anchorQuery.trim().toLowerCase();
    final prefix = trigger.isEmbed ? '![[' : '[[';
    final entries = <({String label, String value})>[];

    if (targetItem is WhiteboardCanvasItem) {
      for (final node in targetItem.nodes) {
        if (node.text.trim().isEmpty) continue;
        if (lowerAnchor.isEmpty || node.text.toLowerCase().contains(lowerAnchor)) {
          entries.add((
            label: 'Node: ${node.text.split('\n').first}',
            value: '$prefix${targetItem.title}#${node.id}|${targetItem.title} › ${node.text.split('\n').first}]]',
          ));
        }
      }
    } else {
      final headings = WikiLinkService.extractHeadings(WikiLinkService.contentOfItem(targetItem));
      for (final h in headings) {
        if (lowerAnchor.isEmpty || h.title.toLowerCase().contains(lowerAnchor)) {
          entries.add((
            label: '# ${h.title}',
            value: '$prefix${targetItem.title}#${h.title}]]',
          ));
        }
      }
    }

    if (entries.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 46,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppSpacing.roundedPill,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: AppSpacing.floatingControlShadow,
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final entry in entries)
            _buildChip(
              isDark: isDark,
              icon: TackIcons.link,
              accentColor: AppColors.accentCyan,
              label: entry.label,
              onTap: () => onSelectCompletion(entry.value),
            ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required bool isDark,
    required dynamic icon,
    required Color accentColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
      child: Material(
        color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF3F5F8),
        borderRadius: AppSpacing.roundedPill,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: AppSpacing.roundedPill,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TackIcon(icon, size: 13, color: accentColor),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Zero-clutter collapsible Backlinks & Unlinked Mentions panel at the bottom of a note.
class NoteBacklinksSection extends StatefulWidget {
  final List<BacklinkEntry> linked;
  final List<BacklinkEntry> unlinked;
  final void Function(BacklinkEntry entry) onOpenEntry;
  final void Function(BacklinkEntry entry) onConvertUnlinkedToWikiLink;

  const NoteBacklinksSection({
    super.key,
    required this.linked,
    required this.unlinked,
    required this.onOpenEntry,
    required this.onConvertUnlinkedToWikiLink,
  });

  @override
  State<NoteBacklinksSection> createState() => _NoteBacklinksSectionState();
}

class _NoteBacklinksSectionState extends State<NoteBacklinksSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final total = widget.linked.length + widget.unlinked.length;
    if (total == 0) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface.withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _expanded = !_expanded);
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const TackIcon(TackIcons.link, size: 15, color: AppColors.accentCyan),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.linked.isNotEmpty
                            ? '${widget.linked.length} Backlink${widget.linked.length == 1 ? '' : 's'}'
                                '${widget.unlinked.isNotEmpty ? '  •  ${widget.unlinked.length} Unlinked' : ''}'
                            : '${widget.unlinked.length} Unlinked Mention${widget.unlinked.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    TackIcon(
                      _expanded ? TackIcons.chevronUp : TackIcons.chevronDown,
                      size: 16,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              Divider(height: 1, color: borderColor),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final entry in widget.linked)
                      _buildEntryTile(context, entry, isDark: isDark, isUnlinked: false),
                    for (final entry in widget.unlinked)
                      _buildEntryTile(context, entry, isDark: isDark, isUnlinked: true),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEntryTile(
    BuildContext context,
    BacklinkEntry entry, {
    required bool isDark,
    required bool isUnlinked,
  }) {
    final palette = AppColors.getPaletteById(entry.sourceItem.paletteId);
    final accent = palette.resolveAccentColor(isDark);
    final isBoard = entry.sourceItem is WhiteboardCanvasItem;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF6F7FA),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onOpenEntry(entry);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                TackIcon(
                  isBoard ? TackIcons.whiteboardSvg : TackIcons.notesSvg,
                  size: 16,
                  color: accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.sourceItem.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: isDark ? Colors.white : const Color(0xFF191A23),
                        ),
                      ),
                      if (entry.contextSnippet.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          entry.contextSnippet,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11.5,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isUnlinked)
                  TextButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      widget.onConvertUnlinkedToWikiLink(entry);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(48, 32),
                    ),
                    child: Text(
                      'Link',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

