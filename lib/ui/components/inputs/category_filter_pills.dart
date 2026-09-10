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

    final borderColor = isDark ? const Color(0xFF323642) : const Color(0xFF191A23);
    final activeLime = AppColors.pastelLimeLight; // Signature #D5F06A

    final availableTags = workspace.availableTags;
    final selectedTag = workspace.selectedTag ?? '#All';
    final selectedFolder = workspace.selectedFolder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Folder Dropdown + Grid/List View Mode Switcher
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Folder Dropdown Pill ("Personal ▾")
              PopupMenuButton<String>(
                initialValue: selectedFolder,
                onSelected: (folder) {
                  HapticFeedback.selectionClick();
                  workspace.setSelectedFolder(folder);
                  if (folder == 'All Notes') {
                    workspace.setSelectedTag('#All');
                  } else {
                    workspace.setSelectedTag('#$folder');
                  }
                },
                offset: const Offset(0, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: borderColor, width: 1.5),
                ),
                color: isDark ? AppColors.darkSurface : Colors.white,
                itemBuilder: (context) => [
                  _buildFolderMenuItem('Personal', isDark),
                  _buildFolderMenuItem('Work', isDark),
                  _buildFolderMenuItem('Fitness', isDark),
                  _buildFolderMenuItem('Ideas', isDark),
                  _buildFolderMenuItem('All Notes', isDark),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF252833) : const Color(0xFFF1F3F7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 1.4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedFolder,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: isDark ? Colors.white : const Color(0xFF191A23),
                        ),
                      ),
                      const SizedBox(width: 6),
                      TackIcon(
                        TackIcons.chevronDown,
                        size: 15,
                        color: isDark ? Colors.white : const Color(0xFF191A23),
                      ),
                    ],
                  ),
                ),
              ),

              // View Mode Switcher Icons (Grid / List side-by-side)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Grid View Toggle (4 squares)
                  _buildViewModeIcon(
                    icon: TackIcons.gridView,
                    isActive: workspace.viewMode == HomeViewMode.stickyGrid,
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      workspace.setViewMode(HomeViewMode.stickyGrid);
                    },
                    tooltip: 'Grid View',
                  ),
                  const SizedBox(width: 8),

                  // List View Toggle (3 bars)
                  _buildViewModeIcon(
                    icon: TackIcons.listView,
                    isActive: workspace.viewMode == HomeViewMode.notebook,
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      workspace.setViewMode(HomeViewMode.notebook);
                    },
                    tooltip: 'List View',
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. Neo-Pop Tag Filter Pills (#All, #work, #Personal, #Fitness)
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: availableTags.length,
            separatorBuilder: (_, _) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final tag = availableTags[index];
              final isSelected = tag.toLowerCase() == selectedTag.toLowerCase();

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    workspace.setSelectedTag(tag);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedScale(
                    scale: isSelected ? 1.04 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        // Active is vibrant Lime Zing, inactive is surface fill
                        color: isSelected
                            ? activeLime
                            : (isDark ? AppColors.darkSurface : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: 1.5),
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
                              : (isDark ? Colors.white : const Color(0xFF191A23)),
                        ),
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
      child: Text(
        folder,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF191A23),
        ),
      ),
    );
  }

  Widget _buildViewModeIcon({
    required HeroIcons icon,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    final activeColor = isDark ? Colors.white : const Color(0xFF191A23);
    final inactiveColor = isDark ? const Color(0xFF686D7D) : const Color(0xFF969BAA);

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? const Color(0xFF2E3240) : const Color(0xFFEFF1F5))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: TackIcon(
              icon,
              size: 19,
              color: isActive ? activeColor : inactiveColor,
              style: isActive ? HeroIconStyle.solid : HeroIconStyle.outline,
            ),
          ),
        ),
      ),
    );
  }
}

