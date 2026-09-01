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

/// Expressive, playful-professional Bento Card inspired by Givingli & Pinterest aesthetics.
/// Features rich pastel backgrounds, bold expressive titles, and tactile micro-elements.
class BentoWorkspaceCard extends StatelessWidget {
  final BaseWorkspaceItem item;
  final VoidCallback onTap;
  final bool isHero; // When true, rendered as a wider featured bento card

  const BentoWorkspaceCard({
    super.key,
    required this.item,
    required this.onTap,
    this.isHero = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = AppColors.getPaletteById(item.paletteId);
    final cardBg = palette.resolveCardColor(isDark);

    // High-contrast readable text colors for the pastel backgrounds
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF191A23);
    final secondaryTextColor = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : const Color(0xFF2E313D).withValues(alpha: 0.9);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : cardBg.withValues(alpha: 0.38),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: EdgeInsets.all(isHero ? AppSpacing.xl : AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Content: Title + Body Preview
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bold, Expressive Title (Givingli Style)
                    Text(
                      item.title,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: isHero ? 24 : 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: primaryTextColor,
                        height: 1.15,
                      ),
                      maxLines: isHero ? 2 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Excerpt / Summary
                    Text(
                      item.getSummary(),
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: isHero ? 14 : 12.5,
                        height: 1.38,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: isHero ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Bottom Visual Graphic Element & Metadata
                _buildCardVisualElement(context, isDark, primaryTextColor, secondaryTextColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Visual graphic element uniquely tailored to each note type (Givingli style)
  Widget _buildCardVisualElement(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    Color secondaryColor,
  ) {
    if (item is WhiteboardCanvasItem) {
      final canvas = item as WhiteboardCanvasItem;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TackIcon(TackIcons.whiteboard, size: 16),
            const SizedBox(width: 6),
            Text(
              '${canvas.nodes.length} flowchart nodes',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
          ],
        ),
      );
    }

    if (item is ClipboardItem) {
      final clip = item as ClipboardItem;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                clip.clipText,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            const TackIcon(TackIcons.copy, size: 14),
          ],
        ),
      );
    }

    if (item is TextNote) {
      final note = item as TextNote;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (note.tags.isNotEmpty)
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#${note.tags.first}',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
          else
            const SizedBox.shrink(),

          Text(
            DateFormatter.formatTimestamp(item.updatedAt),
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: secondaryColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      );
    }

    // Default Sticky Note Footer
    return Align(
      alignment: Alignment.bottomRight,
      child: Text(
        DateFormatter.formatTimestamp(item.updatedAt),
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: secondaryColor.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
