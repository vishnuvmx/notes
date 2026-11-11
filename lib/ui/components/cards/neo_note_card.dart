import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/base_item.dart';
import '../../../domain/models/text_note.dart';

/// Soft Monochrome Note Grid Card (`docs/design/11-reference-ui-style.md` §4, Screenshot 1 & 4).
///
/// Anatomy:
/// - Outer Container: `surface/primary` (`#FFFFFF` / `#18191C`), `r-md` (`18dp`), soft diffused shadow (`elev/1`)
/// - Top Header Row: Tag/Folder pill (or `NOTE` label) on the left + mono date (`12 NOV`) & `TackPinBadge` on the right
/// - Title (`title-sm`, `text/primary`, max 2 lines)
/// - Inner Tinted Sub-Card (`softBackground`, `10dp` radius) with a `3.5dp` vertical accent bar on the left,
///   body snippet, and a compact word-count pill (`42w`)
class NeoNoteCard extends StatefulWidget {
  final BaseWorkspaceItem item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isGrid;

  const NeoNoteCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onLongPress,
    this.isGrid = true,
  });

  @override
  State<NeoNoteCard> createState() => _NeoNoteCardState();
}

class _NeoNoteCardState extends State<NeoNoteCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final palette = AppColors.getPaletteById(widget.item.paletteId);
    final accentColor = palette.resolveAccentColor(tokens.isDark);
    final softTint = palette.resolveSoftBackground(tokens.isDark);
    final summary = widget.item.getSummary();
    final hasDistinctSummary = summary.trim().isNotEmpty &&
        summary.trim().toLowerCase() != widget.item.title.trim().toLowerCase() &&
        summary != 'Empty note';

    final displayTitle =
        (widget.item.iconEmoji != null && widget.item.iconEmoji!.isNotEmpty)
            ? '${widget.item.iconEmoji} ${widget.item.title}'
            : (widget.item.title.trim().isEmpty ? 'Untitled' : widget.item.title);

    final firstTag = (widget.item is TextNote &&
            (widget.item as TextNote).tags.isNotEmpty)
        ? '#${(widget.item as TextNote).tags.first}'
        : (widget.item.folderName != null &&
                widget.item.folderName!.isNotEmpty &&
                widget.item.folderName != 'All Notes'
            ? widget.item.folderName!
            : 'NOTE');

    final wordCount = widget.item is TextNote
        ? (widget.item as TextNote).wordCount
        : summary.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: AppSpacing.durationFast,
      curve: AppSpacing.curveStandard,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.cardMinHeight,
          maxHeight: 224.0,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: tokens.surfacePrimary,
            borderRadius: AppSpacing.roundedMd,
            border: _isPressed
                ? Border.all(color: tokens.borderStrong, width: 1)
                : null,
            boxShadow: AppSpacing.elev1(tokens.isDark),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTapDown: (_) {
                HapticFeedback.selectionClick();
                setState(() => _isPressed = true);
              },
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: () {
                setState(() => _isPressed = false);
                HapticFeedback.lightImpact();
                widget.onTap();
              },
              onLongPress: widget.onLongPress != null
                  ? () {
                      setState(() => _isPressed = false);
                      HapticFeedback.mediumImpact();
                      widget.onLongPress!();
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Top Meta Row: Category/Tag Pill + Date + Pin Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: softTint,
                            borderRadius: AppSpacing.roundedPill,
                          ),
                          child: Text(
                            firstTag,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption(
                              color: accentColor,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormatter.formatTimestamp(widget.item.updatedAt)
                              .toUpperCase(),
                          style: AppTypography.mono(
                            fontSize: 10.5,
                            color: tokens.textTertiary,
                          ),
                        ),
                        if (widget.item.isFavorite) ...[
                          const SizedBox(width: 6),
                          TackPinBadge(color: tokens.accentPin, size: 13),
                        ],
                      ],
                    ),

                    const SizedBox(height: AppSpacing.s2),

                    // 2. Note Title
                    Text(
                      displayTitle,
                      style: AppTypography.titleSm(
                        color: tokens.textPrimary,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: AppSpacing.s2),

                    // 3. Regent-Style Tinted Inner Block with 3.5dp Leading Bar
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: softTint,
                          borderRadius: AppSpacing.roundedSm,
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                width: 3.0,
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  borderRadius: AppSpacing.roundedPill,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  hasDistinctSummary ? summary : 'Tap to write…',
                                  style: AppTypography.bodySm(
                                    color: hasDistinctSummary
                                        ? tokens.textSecondary
                                        : tokens.textTertiary,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (wordCount > 0) ...[
                                const SizedBox(width: 6),
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.14),
                                      borderRadius: AppSpacing.roundedPill,
                                    ),
                                    child: Text(
                                      '${wordCount}w',
                                      style: AppTypography.caption(
                                        color: accentColor,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
