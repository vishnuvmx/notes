import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../state/workspace_provider.dart';
import 'tack_dropdown.dart';

const String _kCreateNewFolderValue = '__create_new_folder__';

/// Neo-Pop filter controls:
/// 1. Folder dropdown ("All Notes ▾", "Favourites", custom user folders, "+ New Folder...")
///    paired with a 1-tap Grid / Notebook List layout switcher.
/// 2. Tag filter pills ("#All", "#work", "#Personal", ...) with Lime Zing active state.
class CategoryFilterPills extends StatelessWidget {
  const CategoryFilterPills({super.key});

  Future<void> _promptNewFolder(
    BuildContext context,
    WorkspaceProvider workspace,
  ) async {
    final controller = TextEditingController();
    try {
      final created = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            'New Folder',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g. Product Specs, Archive, Journal...',
            ),
            onSubmitted: (val) => Navigator.of(ctx).pop(val.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Create'),
            ),
          ],
        ),
      );
      if (created != null && created.isNotEmpty) {
        await workspace.addFolder(created);
        workspace.setSelectedFolder(created);
      }
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workspace = context.watch<WorkspaceProvider>();

    final activeLime = AppColors.pastelLimeLight;

    final availableTags = workspace.availableTags;
    final selectedTag = workspace.selectedTag ?? '#All';
    final selectedFolder = workspace.selectedFolder;

    final folderItems = <TackDropdownItem<String>>[
      const TackDropdownItem(value: 'All Notes', label: 'All Notes', icon: TackIcons.gridView),
      const TackDropdownItem(
        value: 'Favorites',
        label: 'Favorites',
        icon: TackIcons.star,
        iconColor: AppColors.accentAmber,
      ),
      ...workspace.userFolders.map(
        (folder) => TackDropdownItem<String>(
          value: folder,
          label: folder,
          icon: LucideIcons.folder,
        ),
      ),
      const TackDropdownItem<String>(
        value: _kCreateNewFolderValue,
        label: '+ New Folder...',
        icon: TackIcons.plus,
        iconColor: AppColors.accentCyan,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Folder Dropdown
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TackDropdown<String>(
              value: (selectedFolder == 'Favourites' ? 'Favorites' : selectedFolder),
              onSelected: (folder) {
                if (folder == _kCreateNewFolderValue) {
                  _promptNewFolder(context, workspace);
                } else {
                  workspace.setSelectedFolder(folder);
                }
              },
              leadingIcon: (selectedFolder == 'Favourites' || selectedFolder == 'Favorites')
                  ? TackIcons.star
                  : (selectedFolder == 'All Notes' ? null : LucideIcons.folder),
              leadingIconColor:
                  (selectedFolder == 'Favourites' || selectedFolder == 'Favorites')
                      ? AppColors.accentAmber
                      : null,
              items: folderItems,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // 2. Neo-Pop Tag Filter Pills (#All, #work, #Personal, #Fitness)
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
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  HapticFeedback.selectionClick();
                  workspace.setSelectedTag(tag);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? activeLime : Colors.transparent,
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
