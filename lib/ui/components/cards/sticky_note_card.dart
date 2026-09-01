import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/base_item.dart';
import '../../../domain/models/sticky_note.dart';
import '../../../state/workspace_provider.dart';

/// Colorful rounded Sticky Note Card matching Screenshots 1 & 3.
/// Features vibrant pastel background, rounded corners, timestamp, and favorite pin.
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workspace = context.read<WorkspaceProvider>();
    final palette = AppColors.getPaletteById(item.paletteId);
    final cardColor = palette.resolveCardColor(isDark);

    final double rotation = item is StickyNote
        ? (item as StickyNote).rotationAngle
        : 0.0;

    return Transform.rotate(
      angle: rotation,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: AppSpacing.roundedLg,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : cardColor.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppSpacing.roundedLg,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppSpacing.roundedLg,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Type Pill + Pin + Favorite
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.12),
                              borderRadius: AppSpacing.roundedPill,
                            ),
                            child: Text(
                              item.type.label,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              item.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 18,
                              color: item.isFavorite ? AppColors.accentAmber : Colors.white70,
                            ),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            onPressed: () => workspace.toggleFavorite(item.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Title
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Content Preview
                      Text(
                        item.getSummary(),
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  // Bottom Timestamp
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Text(
                      DateFormatter.formatTimestamp(item.updatedAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
