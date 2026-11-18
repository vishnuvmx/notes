import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../services/wiki_link_service.dart';
import '../../../shared/widgets/app_search_field.dart';

/// Top-anchored floating Document Outline (Table of Contents) popover for [NoteEditorScreen]
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
    final tokens = context.tokens;
    final topInset = MediaQuery.paddingOf(context).top + AppSpacing.appBarHeight + 6;
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close document outline',
      barrierColor: Colors.black.withValues(alpha: tokens.isDark ? 0.36 : 0.16),
      transitionDuration: const Duration(milliseconds: 210),
      pageBuilder: (dialogCtx, _, _) {
        return SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                topInset,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 360,
                  maxHeight: 460,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: ShapeDecoration(
                      color: tokens.surfacePrimary,
                      shadows: AppSpacing.elev2(tokens.isDark),
                      shape: SmoothRectangleBorder(
                        borderRadius: AppSpacing.roundedLg,
                        smoothness: AppSpacing.defaultSmoothing,
                        side: BorderSide(color: tokens.borderSubtle, width: 1),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: DocumentOutlineSheet(
                      noteTitle: noteTitle,
                      content: content,
                      paletteId: paletteId,
                      currentLineIndex: currentLineIndex,
                      onSelectHeading: onSelectHeading,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.04),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
              alignment: Alignment.topRight,
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  State<DocumentOutlineSheet> createState() => _DocumentOutlineSheetState();
}

class _DocumentOutlineSheetState extends State<DocumentOutlineSheet> {
  final TextEditingController _filterController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final palette = AppColors.getPaletteById(widget.paletteId);
    final accent = palette.resolveAccentColor(tokens.isDark);
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
                  style: AppTypography.titleSm(
                    color: tokens.textPrimary,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: AppSpacing.roundedPill,
                ),
                child: Text(
                  '${allHeadings.length} sections',
                  style: AppTypography.caption(
                    color: accent,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Close',
                constraints: const BoxConstraints(
                  minWidth: AppSpacing.minTouchTarget,
                  minHeight: AppSpacing.minTouchTarget,
                ),
                icon: TackIcon(
                  TackIcons.close,
                  size: 18,
                  color: tokens.textSecondary,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          if (allHeadings.length > 5) ...[
            const SizedBox(height: 10),
            AppSearchField(
              controller: _filterController,
              hintText: 'Jump to section...',
              onChanged: (v) => setState(() => _filter = v),
              onClear: () {
                _filterController.clear();
                setState(() => _filter = '');
              },
            ),
          ],
          const SizedBox(height: 10),
          if (allHeadings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Add # H1, ## H2, or ### H3 headings to automatically generate a navigable document outline.',
                style: AppTypography.bodySm(color: tokens.textSecondary),
              ),
            )
          else if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No headings match "${_filter.trim()}"',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySm(
                        color: tokens.textSecondary,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s1),
                    SizedBox(
                      height: AppSpacing.minTouchTarget,
                      child: TextButton.icon(
                        onPressed: () {
                          _filterController.clear();
                          setState(() => _filter = '');
                        },
                        icon: TackIcon(
                          TackIcons.close,
                          size: 15,
                          color: tokens.actionPrimary,
                        ),
                        label: const Text('Clear filter'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Flexible(
              child: ConstrainedBox(
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
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          widget.onSelectHeading(h);
                        });
                      },
                      borderRadius: AppSpacing.roundedSm,
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: AppSpacing.minTouchTarget,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: EdgeInsets.fromLTRB(10 + indent, 10, 10, 10),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? accent.withValues(
                                  alpha: tokens.isDark ? 0.18 : 0.11,
                                )
                              : Colors.transparent,
                          borderRadius: AppSpacing.roundedSm,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: tokens.canvasSunken,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                'H${h.level}',
                                style: AppTypography.caption(
                                  color: isCurrent
                                      ? accent
                                      : tokens.textSecondary,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                h.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: h.level == 1
                                    ? AppTypography.body(
                                        color: isCurrent
                                            ? accent
                                            : tokens.textPrimary,
                                        weight: FontWeight.w700,
                                      )
                                    : AppTypography.bodySm(
                                        color: isCurrent
                                            ? accent
                                            : tokens.textPrimary,
                                        weight: h.level <= 2 || isCurrent
                                            ? FontWeight.w700
                                            : FontWeight.w500,
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

    final tokens = context.tokens;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: tokens.surfacePrimary.withValues(alpha: isDark ? 0.85 : 0.92),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: tokens.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: AppSpacing.roundedMd,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSpacing.minTouchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    TackIcon(TackIcons.nestedList, size: 16, color: accent),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Table of Contents',
                        style: AppTypography.caption(
                          color: tokens.textPrimary,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: TackIcon(
                        TackIcons.chevronDown,
                        size: 15,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: headings.map((h) {
                  final indent = ((h.level - minLevel).clamp(0, 4)) * 14.0;
                  return InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onJumpToLine?.call(h.lineIndex);
                    },
                    borderRadius: AppSpacing.roundedXs,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: AppSpacing.minTouchTarget,
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(indent, 8, 8, 8),
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
                                style: AppTypography.bodySm(
                                  color: tokens.textPrimary,
                                  weight: h.level <= 2
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            secondChild: const SizedBox(width: double.infinity, height: 0),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            sizeCurve: Curves.easeOutCubic,
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeInCubic,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

