import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../state/workspace_provider.dart';

/// Neo-Pop filter controls matching reference mockup (Screenshot 1 & 2).
/// Includes:
/// 1. Folder dropdown ("Personal ▾") and Grid/List switcher icons
/// 2. Tag filter pills ("#All", "#work", "#Personal", "#Fitness") with Lime Zing active state
class CategoryFilterPills extends StatelessWidget {
  const CategoryFilterPills({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workspace = context.watch<WorkspaceProvider>();

    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFF191A23);
    final activeLime = AppColors.pastelLimeLight; // Signature #D5F06A

    final availableTags = workspace.availableTags;
    final selectedTag = workspace.selectedTag ?? '#All';
    final selectedFolder = workspace.selectedFolder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Folder Dropdown
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: PopupMenuButton<String>(
            initialValue: selectedFolder,
            onSelected: (folder) {
              HapticFeedback.selectionClick();
              workspace.setSelectedFolder(folder);
            },
            offset: const Offset(0, 42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor, width: 1.5),
            ),
            color: isDark ? AppColors.darkSurface : Colors.white,
            itemBuilder: (context) => [
              _buildFolderMenuItem('All Notes', isDark),
              _buildFolderMenuItem('Favourites', isDark),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : const Color(0xFFF1F3F7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 1.4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selectedFolder == 'Favourites') ...[
                    const TackIcon(
                      TackIcons.star,
                      size: 14,
                      color: AppColors.accentAmber,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    selectedFolder,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF191A23),
                    ),
                  ),
                  const SizedBox(width: 6),
                  TackIcon(
                    TackIcons.chevronDown,
                    size: 15,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF191A23),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // 2. Neo-Pop Tag Filter Pills (#All, #work, #Personal, #Fitness) with no shadow clipping
        SizedBox(
          height: 48,
          child: ListView.separated(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
            itemCount: availableTags.length,
            separatorBuilder: (_, _) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final tag = availableTags[index];
              final isSelected = tag.toLowerCase() == selectedTag.toLowerCase();

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  workspace.setSelectedTag(tag);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeLime
                        : (isDark ? AppColors.darkSurface : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected && isDark ? activeLime : borderColor,
                      width: 1.5,
                    ),
                    boxShadow: isSelected && !isDark
                        ? [
                            BoxShadow(
                              color: const Color(0xFF191A23).withValues(alpha: 0.1),
                              blurRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        letterSpacing: -0.2,
                        color: isSelected
                            ? const Color(0xFF191A23)
                            : (isDark ? AppColors.darkTextPrimary : const Color(0xFF191A23)),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildFolderMenuItem(String folder, bool isDark) {
    return PopupMenuItem<String>(
      value: folder,
      child: Row(
        children: [
          TackIcon(
            folder == 'Favourites' ? TackIcons.star : TackIcons.notes,
            size: 16,
            color: folder == 'Favourites'
                ? AppColors.accentAmber
                : (isDark ? AppColors.darkTextPrimary : const Color(0xFF191A23)),
          ),
          const SizedBox(width: 10),
          Text(
            folder,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF191A23),
            ),
          ),
        ],
      ),
    );
  }
}

