import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/base_item.dart';
import '../../../domain/models/text_note.dart';
import '../../../domain/models/whiteboard_item.dart';
import '../../../domain/models/clipboard_item.dart';

/// Playful Neo-Pop / Soft Neo-Brutalist Card matching the reference mockup.
/// Features a crisp 1.6px dark stroke border, flat curated pastel fills,
/// bold title, "4th Jan 2050" date stamp, snippet preview, and bottom glyph.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = AppColors.getPaletteById(widget.item.paletteId);
    final cardBg = palette.resolveCardColor(isDark);

    // Neo-pop stroke: In OLED dark mode, use a luminous stroke tinted by the card's pastel
    final borderColor = isDark
        ? palette.lightColor.withValues(alpha: 0.45)
        : const Color(0xFF191A23);

    final titleColor = isDark ? Colors.white : const Color(0xFF191A23);
    final dateColor = isDark
        ? palette.lightColor.withValues(alpha: 0.90)
        : const Color(0xFF383B46).withValues(alpha: 0.85);
    final snippetColor = isDark
        ? const Color(0xFFE2E4EC)
        : const Color(0xFF232530).withValues(alpha: 0.85);

    final card = AnimatedScale(
      scale: _isPressed ? 0.965 : 1.0,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: AppSpacing.roundedLg,
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: palette.lightColor.withValues(alpha: _isPressed ? 0.05 : 0.09),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0xFF191A23).withValues(alpha: _isPressed ? 0.03 : 0.08),
                    blurRadius: 0,
                    offset: Offset(0, _isPressed ? 1 : 3),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppSpacing.roundedLg,
          child: InkWell(
            onTapDown: (_) {
              HapticFeedback.selectionClick();
              setState(() => _isPressed = true);
            },
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: () {
              setState(() => _isPressed = false);
              HapticFeedback.mediumImpact();
              widget.onTap();
            },
            onLongPress: widget.onLongPress != null
                ? () {
                    setState(() => _isPressed = false);
                    widget.onLongPress!();
                  }
                : null,
            borderRadius: AppSpacing.roundedLg,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Bold Note Title
                  Text(
                    widget.item.title,
                    style: AppTypography.cardTitleStyle(
                      color: titleColor,
                      fontSize: widget.isGrid ? 15.5 : 17,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  // 2. Ordinal Date Stamp (e.g., "4th Jan 2050")
                  Text(
                    DateFormatter.formatOrdinalDate(widget.item.updatedAt),
                    style: AppTypography.cardDateStyle(
                      color: dateColor,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 3. Clamped Snippet / Preview
                  Expanded(
                    child: Text(
                      widget.item.getSummary(),
                      style: AppTypography.cardSnippetStyle(
                        color: snippetColor,
                        fontSize: 11.8,
                      ),
                      maxLines: widget.isGrid ? 4 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 4. Bottom Glyph / Badge
                  _buildBottomGlyph(context, isDark, titleColor, borderColor, palette.lightColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        card,
        if (widget.item.isFavorite)
          Positioned(
            top: -7,
            child: _buildPushPin(palette.pinColor, isDark),
          ),
      ],
    );
  }

  /// Bottom icon badge representing note category, mood, or type
  Widget _buildBottomGlyph(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color borderColor,
    Color accentColor,
  ) {
    dynamic icon = TackIcons.notesSvg;
    if (widget.item is WhiteboardCanvasItem) {
      icon = TackIcons.whiteboardSvg;
    } else if (widget.item is ClipboardItem) {
      icon = TackIcons.clipboard;
    } else if (widget.item is TextNote) {
      final note = widget.item as TextNote;
      if (note.tags.any((t) => t.toLowerCase().contains('fitness') || t.toLowerCase().contains('sport'))) {
        icon = TackIcons.bolt;
      } else if (note.tags.any((t) => t.toLowerCase().contains('work'))) {
        icon = TackIcons.briefcase;
      } else if (note.tags.any((t) => t.toLowerCase().contains('personal'))) {
        icon = TackIcons.user;
      } else {
        icon = TackIcons.notesSvg;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TackIcon(
          icon,
          size: 20,
          color: isDark ? accentColor : textColor.withValues(alpha: 0.85),
        ),
        if (widget.item.isFavorite)
          TackIcon(
            TackIcons.star,
            size: 16,
            color: isDark ? AppColors.pastelAmberLight : const Color(0xFF191A23),
          ),
      ],
    );
  }

  Widget _buildPushPin(Color color, bool isDark) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.8,
          colors: [
            Colors.white.withValues(alpha: 0.8),
            color,
            color.withValues(alpha: 0.9),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
    );
  }
}
