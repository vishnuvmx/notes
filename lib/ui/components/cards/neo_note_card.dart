import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
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
class NeoNoteCard extends StatelessWidget {
  final BaseWorkspaceItem item;
  final VoidCallback onTap;
  final bool isGrid;

  const NeoNoteCard({
    super.key,
    required this.item,
    required this.onTap,
    this.isGrid = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = AppColors.getPaletteById(item.paletteId);
    final cardBg = palette.resolveCardColor(isDark);

    // Neo-pop high contrast dark stroke
    final borderColor = isDark
        ? const Color(0xFF323642)
        : const Color(0xFF191A23);

    final titleColor = isDark ? Colors.white : const Color(0xFF191A23);
    final dateColor = isDark
        ? Colors.white.withValues(alpha: 0.75)
        : const Color(0xFF383B46).withValues(alpha: 0.85);
    final snippetColor = isDark
        ? Colors.white.withValues(alpha: 0.88)
        : const Color(0xFF232530).withValues(alpha: 0.85);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 1.6),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF191A23).withValues(alpha: 0.08),
                  blurRadius: 0,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Bold Note Title
                Text(
                  item.title,
                  style: AppTypography.cardTitleStyle(
                    color: titleColor,
                    fontSize: isGrid ? 15.5 : 17,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),

                // 2. Ordinal Date Stamp (e.g., "4th Jan 2050")
                Text(
                  DateFormatter.formatOrdinalDate(item.updatedAt),
                  style: AppTypography.cardDateStyle(
                    color: dateColor,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),

                // 3. Clamped Snippet / Preview
                Expanded(
                  child: Text(
                    item.getSummary(),
                    style: AppTypography.cardSnippetStyle(
                      color: snippetColor,
                      fontSize: 11.8,
                    ),
                    maxLines: isGrid ? 4 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 8),

                // 4. Bottom Glyph / Badge
                _buildBottomGlyph(context, isDark, titleColor, borderColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Bottom icon badge representing note category, mood, or type
  Widget _buildBottomGlyph(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color borderColor,
  ) {
    HeroIcons icon = TackIcons.notes;
    if (item is WhiteboardCanvasItem) {
      icon = TackIcons.whiteboard;
    } else if (item is ClipboardItem) {
      icon = TackIcons.clipboard;
    } else if (item is TextNote) {
      final note = item as TextNote;
      if (note.tags.any((t) => t.toLowerCase().contains('fitness') || t.toLowerCase().contains('sport'))) {
        icon = HeroIcons.sparkles;
      } else if (note.tags.any((t) => t.toLowerCase().contains('work'))) {
        icon = HeroIcons.briefcase;
      } else if (note.tags.any((t) => t.toLowerCase().contains('personal'))) {
        icon = HeroIcons.user;
      } else {
        icon = HeroIcons.pencilSquare;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor.withValues(alpha: 0.4), width: 1.2),
          ),
          child: Center(
            child: HeroIcon(
              icon,
              size: 14,
              color: textColor,
            ),
          ),
        ),
        if (item.isFavorite)
          HeroIcon(
            HeroIcons.star,
            style: HeroIconStyle.solid,
            size: 15,
            color: isDark ? AppColors.pastelAmberLight : const Color(0xFF191A23),
          ),
      ],
    );
  }
}
