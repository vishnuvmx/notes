import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Immutable slide specification for Tack's first-run onboarding flow.
class OnboardingSlideData {
  final String imageAsset;
  final String title;
  final String description;

  const OnboardingSlideData({
    required this.imageAsset,
    required this.title,
    required this.description,
  });
}

/// Framed showcase stage displaying each onboarding slide's artwork inside a
/// smooth rounded container matching Tack's Soft Monochrome geometry.
class OnboardingSlideStage extends StatelessWidget {
  final OnboardingSlideData slide;

  const OnboardingSlideStage({super.key, required this.slide});

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
            side: BorderSide(color: tokens.borderSubtle, width: 1),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              slide.imageAsset,
              fit: BoxFit.cover,
              cacheWidth: 1080,
              filterQuality: FilterQuality.medium,
            ),
            if (tokens.isDark)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppSpacing.scrim.withValues(alpha: 0.24),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
