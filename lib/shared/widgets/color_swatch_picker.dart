import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/tack_icons.dart';
import 'tactile_ink_target.dart';

/// Interactive color swatch picker for the 8 curated Paper & Pin object palettes (`07` §2.3).
/// Enforces 48×48dp minimum touch targets (`07` §5.3).
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
    final tokens = context.tokens;
    final normalizedSelected = AppColors.normalizePaletteId(selectedPaletteId);

    return SizedBox(
      height: AppSpacing.minTouchTarget,
      child: ListView.separated(
        clipBehavior: Clip.none,
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        itemCount: AppColors.presetPalettes.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s2),
        itemBuilder: (context, index) {
          final palette = AppColors.presetPalettes[index];
          final isSelected = palette.id == normalizedSelected;
          final swatchColor = palette.lightColor;

          return Semantics(
            button: true,
            selected: isSelected,
            label: '${palette.name} color',
            child: TactileInkTarget(
              useCircleShape: true,
              width: isSelected ? 34 : 30,
              height: isSelected ? 34 : 30,
              duration: AppSpacing.durationFast,
              curve: AppSpacing.curveStandard,
              triggerHaptics: true,
              color: swatchColor,
              border: Border.all(
                color: isSelected
                    ? tokens.textPrimary
                    : tokens.borderStrong.withValues(alpha: 0.45),
                width: isSelected ? 2.0 : 1.0,
              ),
              splashColor: AppColors.lightTextPrimary.withValues(alpha: 0.16),
              hoverColor: AppColors.lightTextPrimary.withValues(alpha: 0.08),
              onTap: () => onPaletteSelected(palette.id),
              child: isSelected
                  ? const TackIcon(
                      TackIcons.check,
                      size: 16,
                      color: AppColors.lightTextPrimary,
                      style: HeroIconStyle.solid,
                    )
                  : const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
