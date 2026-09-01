import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/tack_icons.dart';

/// Interactive color swatch picker with cute HeroIcon checkmark.
class ColorSwatchPicker extends StatelessWidget {
  final String selectedPaletteId;
  final ValueChanged<String> onPaletteSelected;

  const ColorSwatchPicker({
    super.key,
    required this.selectedPaletteId,
    required this.onPaletteSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AppColors.presetPalettes.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final palette = AppColors.presetPalettes[index];
          final isSelected = palette.id == selectedPaletteId;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onPaletteSelected(palette.id);
            },
            child: AnimatedContainer(
              duration: AppSpacing.fastAnim,
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.resolveCardColor(isDark),
                border: Border.all(
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.primaryDark)
                      : Colors.transparent,
                  width: isSelected ? 2.5 : 0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: palette.lightColor.withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: isSelected
                  ? const Center(
                      child: TackIcon(
                        TackIcons.check,
                        size: 20,
                        color: Colors.white,
                        style: HeroIconStyle.solid,
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
