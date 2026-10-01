import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../state/workspace_provider.dart';
import 'tack_dropdown.dart';

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
          child: TackDropdown<String>(
            value: selectedFolder,
            onSelected: (folder) => workspace.setSelectedFolder(folder),
            leadingIcon: selectedFolder == 'Favourites' ? TackIcons.star : null,
            leadingIconColor: selectedFolder == 'Favourites' ? AppColors.accentAmber : null,
            items: const [
              TackDropdownItem(value: 'All Notes', label: 'All Notes'),
              TackDropdownItem(value: 'Favourites', label: 'Favourites', icon: TackIcons.star, iconColor: AppColors.accentAmber),
            ],
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
}

