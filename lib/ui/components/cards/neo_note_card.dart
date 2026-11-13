import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/base_item.dart';
import '../../../domain/models/text_note.dart';

/// Clean, Soft Monochrome Note Grid Card (`docs/design/11-reference-ui-style.md`, Screenshots 1 & 4).
///
/// Designed to be calm and uncluttered:
/// - Pure white / soft carbon surface (`radius: 18dp`, diffused elevation)
/// - Top meta row: subtle custom tag/folder (only if set), date, and pin badge (only if favorited)
/// - Prominent, readable title
/// - Clean content snippet preview (no redundant nested boxes, badges, or word-count pills)
class NeoNoteCard extends StatefulWidget {
  final BaseWorkspaceItem item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isGrid;
  final bool showContentPreview;

  const NeoNoteCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onLongPress,
    this.isGrid = true,
    this.showContentPreview = false,
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

    final String? customTag = (widget.item is TextNote &&
            (widget.item as TextNote).tags.isNotEmpty)
        ? '#${(widget.item as TextNote).tags.first}'
        : (widget.item.folderName != null &&
                widget.item.folderName!.isNotEmpty &&
                widget.item.folderName != 'All Notes'
            ? widget.item.folderName!
            : null);

    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: AppSpacing.durationFast,
      curve: AppSpacing.curveStandard,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: widget.showContentPreview
              ? AppSpacing.cardMinHeight
              : AppSpacing.cardMinHeightCompact,
        ),
        child: Container(
          decoration: ShapeDecoration(
            color: tokens.surfacePrimary,
            shadows: AppSpacing.elev1(tokens.isDark),
            shape: SmoothRectangleBorder(
              borderRadius: AppSpacing.roundedMd,
              smoothness: 0.60,
              side: _isPressed
                  ? BorderSide(color: tokens.borderStrong, width: 1)
                  : BorderSide.none,
            ),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Top Meta Row: Custom Tag (if any) + Date + Pin Badge (if favorited)
                    Row(
                      children: [
                        if (customTag != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: softTint,
                              borderRadius: AppSpacing.roundedPill,
                            ),
                            child: Text(
                              customTag,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption(
                                color: accentColor,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
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
                          TackPinBadge(color: tokens.accentPin, size: 12),
                        ],
                      ],
                    ),

                    const SizedBox(height: 8),

                    // 2. Note Title
                    Text(
                      displayTitle,
                      style: AppTypography.titleSm(
                        color: tokens.textPrimary,
                        fontSize: 15.5,
                        weight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // 3. Optional Content Snippet Preview (hidden by default on home/note grids per user request)
                    if (widget.showContentPreview && hasDistinctSummary) ...[
                      const SizedBox(height: 6),
                      Text(
                        summary,
                        style: AppTypography.bodySm(
                          color: tokens.textSecondary,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
