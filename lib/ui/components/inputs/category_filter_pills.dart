import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/models/base_item.dart';
import '../../../state/workspace_provider.dart';

/// Horizontal scrollable category filter pills ("All", "Notes", "Sticky", "Whiteboard", "Clipboard").
class CategoryFilterPills extends StatelessWidget {
  const CategoryFilterPills({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workspace = context.watch<WorkspaceProvider>();
    final selectedType = workspace.selectedCategory;

    final categories = <({ItemType? type, String label, IconData icon})>[
      (type: null, label: 'All', icon: Icons.grid_view_rounded),
      (type: ItemType.note, label: 'Notes', icon: Icons.article_outlined),
      (type: ItemType.sticky, label: 'Sticky', icon: Icons.sticky_note_2_outlined),
      (type: ItemType.whiteboard, label: 'Whiteboard', icon: Icons.gesture_rounded),
      (type: ItemType.clipboard, label: 'Clipboard', icon: Icons.assignment_outlined),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),

        itemBuilder: (context, index) {
          final item = categories[index];
          final isSelected = selectedType == item.type;

          final Color activeBg = isDark ? AppColors.lightSurface : AppColors.primaryDark;
          final Color activeFg = isDark ? AppColors.darkBackground : AppColors.lightSurface;
          final Color inactiveBg = isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;
          final Color inactiveFg = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

          return AnimatedContainer(
            duration: AppSpacing.fastAnim,
            curve: AppSpacing.smoothCurve,
            child: Material(
              color: isSelected ? activeBg : inactiveBg,
              borderRadius: AppSpacing.roundedPill,
              child: InkWell(
                onTap: () => workspace.setCategory(item.type),
                borderRadius: AppSpacing.roundedPill,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 16,
                        color: isSelected ? activeFg : inactiveFg.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.label,
                        style: AppTypography.lightTextTheme.labelLarge?.copyWith(
                          color: isSelected ? activeFg : inactiveFg,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
