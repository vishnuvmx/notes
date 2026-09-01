import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/base_item.dart';
import '../../../domain/models/text_note.dart';
import '../../../state/workspace_provider.dart';


/// Tactile Spiral Notebook List Card with cute HeroIcons.
class SmartNoteListCard extends StatelessWidget {
  final BaseWorkspaceItem item;
  final int index;
  final VoidCallback onTap;

  const SmartNoteListCard({
    super.key,
    required this.item,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workspace = context.read<WorkspaceProvider>();
    final palette = AppColors.getPaletteById(item.paletteId);
    final formattedIndex = (index + 1).toString().padLeft(2, '0');

    // Extract read time / subtitle metadata
    String metaString = DateFormatter.formatTimestamp(item.updatedAt);
    if (item is TextNote) {
      final note = item as TextNote;
      metaString += '  •  ${note.estimatedMinutes} min read';
    } else if (item.type == ItemType.whiteboard) {
      metaString += '  •  Canvas';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: isDark ? AppSpacing.softShadowDark : AppSpacing.softShadowLight,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppSpacing.roundedMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.roundedMd,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tactile Spiral Notebook Spine Accent
                _buildSpiralSpine(isDark),

                // Large Stylized Number Index (01, 02...)
                Container(
                  width: 58,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    formattedIndex,
                    style: AppTypography.scriptIndexStyle(
                      color: palette.resolveAccentColor(isDark),
                      fontSize: 34,
                    ),
                  ),
                ),

                // Note Content & Details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Category Label + Cute Star Pin
                        Row(
                          children: [
                            Text(
                              item.type.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: palette.resolveAccentColor(isDark),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            if (item.isFavorite) ...[
                              const SizedBox(width: 6),
                              const TackIcon(
                                TackIcons.star,
                                size: 14,
                                color: AppColors.accentAmber,
                                style: HeroIconStyle.solid,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),

                        // Title
                        Text(
                          item.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Summary Snippet
                        Text(
                          item.getSummary(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // Timestamp & Meta
                        Text(
                          metaString,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3-Dots Context Menu (Cute HeroIcon)
                PopupMenuButton<String>(
                  icon: TackIcon(
                    TackIcons.more,
                    size: 20,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                  onSelected: (value) {
                    if (value == 'favorite') {
                      workspace.toggleFavorite(item.id);
                    } else if (value == 'archive') {
                      workspace.toggleArchive(item.id);
                    } else if (value == 'trash') {
                      workspace.moveToTrash(item.id);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'favorite',
                      child: Row(
                        children: [
                          TackIcon(
                            TackIcons.star,
                            size: 18,
                            color: AppColors.accentAmber,
                            style: item.isFavorite ? HeroIconStyle.solid : HeroIconStyle.outline,
                          ),
                          const SizedBox(width: 8),
                          Text(item.isFavorite ? 'Unfavorite' : 'Favorite'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'archive',
                      child: Row(
                        children: [
                          TackIcon(TackIcons.archive, size: 18),
                          const SizedBox(width: 8),
                          Text(item.isArchived ? 'Unarchive' : 'Archive'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'trash',
                      child: Row(
                        children: [
                          TackIcon(TackIcons.trash, size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Move to Trash', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpiralSpine(bool isDark) {
    return Container(
      width: 14,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181A1F) : const Color(0xFFF1F3F5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusMd),
          bottomLeft: Radius.circular(AppSpacing.radiusMd),
        ),
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          6,
          (i) => Container(
            width: 7,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF333842) : const Color(0xFFC4C9D2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
