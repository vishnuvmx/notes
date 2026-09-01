import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/base_item.dart';
import '../../../domain/models/sticky_note.dart';

/// Tactile, playful-professional Sticky Note Card matching reference (Screenshot 2).
/// Features a cute 3D push-pin tack, clean pastel surface, and uncluttered layout.
class StickyNoteCard extends StatelessWidget {
  final BaseWorkspaceItem item;
  final VoidCallback onTap;

  const StickyNoteCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = AppColors.getPaletteById(item.paletteId);
    final cardBgColor = palette.resolveCardColor(isDark);
    final pinColor = palette.pinColor;

    final double rotation = item is StickyNote
        ? (item as StickyNote).rotationAngle
        : 0.0;

    return Transform.rotate(
      angle: rotation,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Main Sticky Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.45)
                      : cardBgColor.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg + 4, AppSpacing.md, AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Card Body
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            item.title,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF18191F),
                              letterSpacing: -0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),

                          // Summary
                          Text(
                            item.getSummary(),
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12.5,
                              height: 1.38,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : const Color(0xFF2D3142).withValues(alpha: 0.9),
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      // Timestamp at bottom
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormatter.formatTimestamp(item.updatedAt),
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : const Color(0xFF4A4E69).withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3D Translucent Tactile Push-Pin Tack (Top Center - Screenshot 2)
          Positioned(
            top: -7,
            child: _buildPushPin(pinColor, isDark),
          ),
        ],
      ),
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
