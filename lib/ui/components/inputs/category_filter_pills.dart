import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../domain/models/base_item.dart';
import '../../../state/workspace_provider.dart';

/// Clean segmented pill switcher matching reference aesthetics (Screenshot 1).
class CategoryFilterPills extends StatelessWidget {
  const CategoryFilterPills({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workspace = context.watch<WorkspaceProvider>();
    final selectedType = workspace.selectedCategory;

    final categories = <({ItemType? type, String label, HeroIcons icon})>[
      (type: null, label: 'All', icon: TackIcons.gridView),
      (type: ItemType.note, label: 'Notes', icon: TackIcons.notes),
      (type: ItemType.sticky, label: 'Sticky', icon: TackIcons.sticky),
      (type: ItemType.whiteboard, label: 'Whiteboard', icon: TackIcons.whiteboard),
      (type: ItemType.clipboard, label: 'Clipboard', icon: TackIcons.clipboard),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = categories[index];
          final isSelected = selectedType == item.type;

          final Color activeBg = isDark ? AppColors.darkSurfaceAlt : Colors.white;
          final Color activeFg = isDark ? Colors.white : AppColors.lightTextPrimary;
          final Color inactiveBg = Colors.transparent;
          final Color inactiveFg = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: isSelected ? activeBg : inactiveBg,
              borderRadius: BorderRadius.circular(14),
              border: isSelected
                  ? Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 1,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.3)
                            : const Color(0xFF191A23).withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => workspace.setCategory(item.type),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TackIcon(
                        item.icon,
                        size: 15,
                        color: isSelected ? activeFg : inactiveFg,
                        style: isSelected ? HeroIconStyle.solid : HeroIconStyle.outline,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? activeFg : inactiveFg,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
