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
import '../dialogs_sheets/ios_menu_button.dart';

/// Tactile, unbloated Note List Card matching reference design (Screenshot 2).
/// Features clean index number, crisp typography, and uncluttered layout.
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

    // Metadata line (clean & subtle)
    String metaString = DateFormatter.formatTimestamp(item.updatedAt);
    if (item is TextNote) {
      final note = item as TextNote;
      metaString = '${note.estimatedMinutes} min read  •  $metaString';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : const Color(0xFF191A23).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clean Tactile Index Number (e.g. 01, 02)
                Container(
                  width: 44,
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    formattedIndex,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: palette.resolveAccentColor(isDark),
                    ),
                  ),
                ),

                // Note Content (Title, Summary, Timestamp)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        item.title,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),

                      // Content Summary
                      Text(
                        item.getSummary(),
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13.5,
                          height: 1.4,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Subtle Meta Info
                      Text(
                        metaString,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11.5,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // iOS-Style Context Menu
                IosThreeDotMenu<String>(
                  size: 32,
                  icon: HeroIcons.ellipsisHorizontal,
                  iconColor: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  onSelected: (value) {
                    if (value == 'favorite') {
                      workspace.toggleFavorite(item.id);
                    } else if (value == 'archive') {
                      workspace.toggleArchive(item.id);
                    } else if (value == 'trash') {
                      workspace.moveToTrash(item.id);
                    }
                  },
                  items: [
                    IosMenuItem(
                      value: 'favorite',
                      title: item.isFavorite ? 'Unfavorite' : 'Favorite',
                      icon: TackIcons.star,
                      iconStyle: item.isFavorite ? HeroIconStyle.solid : HeroIconStyle.outline,
                      iconColor: AppColors.accentAmber,
                    ),
                    IosMenuItem(
                      value: 'archive',
                      title: item.isArchived ? 'Unarchive' : 'Archive',
                      icon: TackIcons.archive,
                    ),
                    const IosMenuItem(
                      value: 'trash',
                      title: 'Move to Trash',
                      icon: TackIcons.trash,
                      isDestructive: true,
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
}
