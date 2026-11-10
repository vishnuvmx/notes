import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/base_item.dart';
import '../../../domain/models/text_note.dart';

/// Paper & Pin Note Grid Card (`07-design-system.md` §7, `10-design.md` §5.1).
///
/// Anatomy:
/// - Container: `surface/primary`, `1dp` `border/subtle`, `r-md` (`12dp`), `elev/1`
/// - Color index band: `6dp` left vertical strip in the note's `object/<palette>` fill
/// - Padding: `14dp` (`16dp` left of text after the `6dp` band)
/// - Title (`title-sm`, `text/primary`, max 2 lines)
/// - Body preview (`body-sm`, `text/secondary`, max 3 lines, Markdown stripped)
/// - Footer row: relative date (`caption`, `text/tertiary`) + `TackPinBadge` when pinned
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
    final bandColor = palette.resolveCardColor(tokens.isDark);
    final summary = widget.item.getSummary();
    final hasDistinctSummary = summary.trim().isNotEmpty &&
        summary.trim().toLowerCase() != widget.item.title.trim().toLowerCase();

    final displayTitle =
        (widget.item.iconEmoji != null && widget.item.iconEmoji!.isNotEmpty)
            ? '${widget.item.iconEmoji} ${widget.item.title}'
            : (widget.item.title.trim().isEmpty ? 'Untitled' : widget.item.title);

    final firstTag = (widget.item is TextNote && (widget.item as TextNote).tags.isNotEmpty)
        ? (widget.item as TextNote).tags.first
        : null;

    return AnimatedScale(
      scale: _isPressed ? 0.985 : 1.0,
      duration: AppSpacing.durationFast,
      curve: AppSpacing.curveStandard,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.cardMinHeight,
          maxHeight: AppSpacing.cardMaxHeight,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: tokens.surfacePrimary,
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(
              color: _isPressed ? tokens.borderStrong : tokens.borderSubtle,
              width: 1,
            ),
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
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 6dp leading object-color index band
                    Container(
                      width: AppSpacing.cardColorBandWidth,
                      color: bandColor,
                    ),

                    // Card body
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.s4,
                          14,
                          14,
                          14,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Top: Title + Body Preview
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayTitle,
                                    style: AppTypography.titleSm(
                                      color: tokens.textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (hasDistinctSummary) ...[
                                    const SizedBox(height: AppSpacing.s1),
                                    Flexible(
                                      child: Text(
                                        summary,
                                        style: AppTypography.bodySm(
                                          color: tokens.textSecondary,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: AppSpacing.s2),

                            // Bottom: Relative date + tag/folder + Pin Red badge
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    firstTag != null
                                        ? '${DateFormatter.formatTimestamp(widget.item.updatedAt)} · #$firstTag'
                                        : DateFormatter.formatTimestamp(
                                            widget.item.updatedAt,
                                          ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption(
                                      color: tokens.textTertiary,
                                    ),
                                  ),
                                ),
                                if (widget.item.isFavorite) ...[
                                  const SizedBox(width: AppSpacing.s2),
                                  TackPinBadge(color: tokens.accentPin),
                                ],
                              ],
                            ),
                          ],
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
