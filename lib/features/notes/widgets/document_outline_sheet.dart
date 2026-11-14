import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../services/wiki_link_service.dart';
import '../../../shared/widgets/app_search_field.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';

/// Slide-up Document Outline (Table of Contents) sheet for [NoteEditorScreen]
/// plus [InlineTocCard] for `[TOC]` blocks inside [RichNoteContentView].
class DocumentOutlineSheet extends StatefulWidget {
  final String noteTitle;
  final String content;
  final String paletteId;
  final int? currentLineIndex;
  final ValueChanged<({int level, String title, int lineIndex})> onSelectHeading;

  const DocumentOutlineSheet({
    super.key,
    required this.noteTitle,
    required this.content,
    required this.paletteId,
    this.currentLineIndex,
    required this.onSelectHeading,
  });

  static Future<void> show(
    BuildContext context, {
    required String noteTitle,
    required String content,
    required String paletteId,
    int? currentLineIndex,
    required ValueChanged<({int level, String title, int lineIndex})> onSelectHeading,
  }) {
    return AppBottomSheet.show<void>(
      context: context,
      builder: (_) => DocumentOutlineSheet(
        noteTitle: noteTitle,
        content: content,
        paletteId: paletteId,
        currentLineIndex: currentLineIndex,
        onSelectHeading: onSelectHeading,
      ),
    );
  }

  @override
  State<DocumentOutlineSheet> createState() => _DocumentOutlineSheetState();
}

class _DocumentOutlineSheetState extends State<DocumentOutlineSheet> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = AppColors.getPaletteById(widget.paletteId);
    final accent = palette.resolveAccentColor(isDark);
    final allHeadings = WikiLinkService.extractHeadings(widget.content);
    final minLevel = allHeadings.isEmpty
        ? 1
        : allHeadings.map((h) => h.level).reduce((a, b) => a < b ? a : b);

    int activeIdx = -1;
    if (widget.currentLineIndex != null) {
      for (int i = 0; i < allHeadings.length; i++) {
        if (allHeadings[i].lineIndex <= widget.currentLineIndex!) {
          activeIdx = i;
        }
      }
    }

    final filtered = _filter.trim().isEmpty
        ? allHeadings
        : allHeadings
            .where((h) => h.title.toLowerCase().contains(_filter.toLowerCase()))
            .toList();

    return Padding(
      padding: AppSpacing.modalSheetPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TackIcon(TackIcons.nestedList, size: 19, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Document Outline',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: AppSpacing.roundedPill,
                ),
                child: Text(
                  '${allHeadings.length} sections',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          if (allHeadings.length > 5) ...[
            const SizedBox(height: 10),
            AppSearchField(
              hintText: 'Jump to section...',
              height: 40,
              onChanged: (v) => setState(() => _filter = v),
              onClear: () => setState(() => _filter = ''),
            ),
          ],
            const SizedBox(height: 10),
            if (allHeadings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Add # H1, ## H2, or ### H3 headings to automatically generate a navigable document outline.',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final h = filtered[i];
                    final isCurrent = activeIdx >= 0 &&
                        allHeadings[activeIdx].lineIndex == h.lineIndex;
                    final indent = ((h.level - minLevel).clamp(0, 4)) * 16.0;
                    return InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).pop();
                        widget.onSelectHeading(h);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: EdgeInsets.fromLTRB(10 + indent, 9, 10, 9),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? accent.withValues(alpha: isDark ? 0.18 : 0.11)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurfaceAlt
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                'H${h.level}',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isCurrent
                                      ? accent
                                      : (isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                h.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: h.level == 1 ? 14 : 13,
                                  fontWeight: h.level <= 2 || isCurrent
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  letterSpacing: -0.25,
                                  color: isCurrent
                                      ? accent
                                      : (isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary),
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
          ],
        ),
      );
  }
}

/// Inline `[TOC]` Table of Contents block rendered inside [RichNoteContentView].
class InlineTocCard extends StatefulWidget {
  final String content;
  final String? paletteId;
  final ValueChanged<int>? onJumpToLine;

  const InlineTocCard({
    super.key,
    required this.content,
    this.paletteId,
    this.onJumpToLine,
  });

  @override
  State<InlineTocCard> createState() => _InlineTocCardState();
}

class _InlineTocCardState extends State<InlineTocCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = AppColors.getPaletteById(widget.paletteId);
    final accent = palette.resolveAccentColor(isDark);
    final headings = WikiLinkService.extractHeadings(widget.content);
    if (headings.isEmpty) return const SizedBox.shrink();

    final minLevel = headings.map((h) => h.level).reduce((a, b) => a < b ? a : b);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceAlt.withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  TackIcon(TackIcons.nestedList, size: 16, color: accent),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Table of Contents',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  TackIcon(
                    _expanded ? TackIcons.chevronUp : TackIcons.chevronDown,
                    size: 15,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: headings.map((h) {
                  final indent = ((h.level - minLevel).clamp(0, 4)) * 14.0;
                  return InkWell(
                    onTap: () => widget.onJumpToLine?.call(h.lineIndex),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(indent, 4, 4, 4),
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              h.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 12.5,
                                fontWeight: h.level <= 2
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                letterSpacing: -0.2,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

