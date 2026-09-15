import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/base_item.dart';
import '../../../domain/models/sticky_note.dart';

/// Tactile, playful-professional Sticky Note Card matching reference.
/// Features iOS-style press depression, subtle spring physics, haptics, and a 3D push-pin tack.
class StickyNoteCard extends StatefulWidget {
  final BaseWorkspaceItem item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const StickyNoteCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<StickyNoteCard> createState() => _StickyNoteCardState();
}

class _StickyNoteCardState extends State<StickyNoteCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = AppColors.getPaletteById(widget.item.paletteId);
    final cardBgColor = palette.resolveCardColor(isDark);
    final pinColor = palette.pinColor;

    final double rotation = widget.item is StickyNote
        ? (widget.item as StickyNote).rotationAngle
        : 0.0;

    return Transform.rotate(
      angle: rotation,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
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
                border: isDark
                    ? Border.all(color: palette.lightColor.withValues(alpha: 0.35), width: 1.2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? palette.lightColor.withValues(alpha: _isPressed ? 0.05 : 0.10)
                        : cardBgColor.withValues(alpha: _isPressed ? 0.15 : 0.35),
                    blurRadius: _isPressed ? 10 : 18,
                    offset: Offset(0, _isPressed ? 3 : 8),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
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
                              widget.item.title,
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
                            widget.item.getSummary(),
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
                          DateFormatter.formatTimestamp(widget.item.updatedAt),
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? palette.lightColor.withValues(alpha: 0.75)
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
