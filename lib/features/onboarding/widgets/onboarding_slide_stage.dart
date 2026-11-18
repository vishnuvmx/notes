import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/tack_icons.dart';

/// Immutable slide specification for Tack's first-run onboarding flow.
class OnboardingSlideData {
  final String imageAsset;
  final String title;
  final List<({String text, bool highlight})> bodySpans;
  final bool showFloatingTileDock;

  const OnboardingSlideData({
    required this.imageAsset,
    required this.title,
    required this.bodySpans,
    this.showFloatingTileDock = false,
  });
}

/// Framed showcase stage displaying each onboarding slide's artwork inside a
/// smooth rounded container matching Tack's Soft Monochrome geometry.
class OnboardingSlideStage extends StatelessWidget {
  final OnboardingSlideData slide;

  const OnboardingSlideStage({
    super.key,
    required this.slide,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return RepaintBoundary(
      child: Container(
        decoration: ShapeDecoration(
          color: tokens.canvasSunken,
          shadows: AppSpacing.elev1(tokens.isDark),
          shape: SmoothRectangleBorder(
            borderRadius: AppSpacing.roundedXl,
            smoothness: AppSpacing.defaultSmoothing,
            side: BorderSide(
              color: tokens.borderSubtle,
              width: 1,
            ),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              slide.imageAsset,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
            if (tokens.isDark)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppSpacing.scrim.withValues(alpha: 0.24),
                ),
              ),
            if (slide.showFloatingTileDock)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s5),
                  child: _FloatingWorkspaceTiles(tokens: tokens),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tactile clustered workspace badges shown along the bottom horizon of the
/// floating cloud-meadow slide (`notes · stickies · boards · clips`).
class _FloatingWorkspaceTiles extends StatelessWidget {
  final TackTokens tokens;

  const _FloatingWorkspaceTiles({required this.tokens});

  @override
  Widget build(BuildContext context) {
    final isDark = tokens.isDark;
    final items = [
      (
        icon: TackIcons.notes,
        color: AppColors.getPaletteById('amber').resolveCardColor(isDark),
        angle: -0.09,
        offsetY: 4.0,
      ),
      (
        icon: TackIcons.stickyNote,
        color: AppColors.getPaletteById('peach').resolveCardColor(isDark),
        angle: -0.03,
        offsetY: -3.0,
      ),
      (
        icon: TackIcons.boards,
        color: AppColors.getPaletteById('cyan').resolveCardColor(isDark),
        angle: 0.04,
        offsetY: -1.0,
      ),
      (
        icon: TackIcons.clipboard,
        color: AppColors.getPaletteById('lavender').resolveCardColor(isDark),
        angle: 0.10,
        offsetY: 5.0,
      ),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.s3),
          Transform.translate(
            offset: Offset(0, items[i].offsetY),
            child: Transform.rotate(
              angle: items[i].angle,
              child: Container(
                width: 48,
                height: 48,
                decoration: ShapeDecoration(
                  color: items[i].color,
                  shadows: AppSpacing.elev2(isDark),
                  shape: SmoothRectangleBorder(
                    borderRadius: AppSpacing.roundedSm,
                    smoothness: AppSpacing.defaultSmoothing,
                    side: BorderSide(
                      color: tokens.surfacePrimary.withValues(alpha: 0.88),
                      width: 2,
                    ),
                  ),
                ),
                child: Center(
                  child: TackIcon(
                    items[i].icon,
                    size: 21,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
