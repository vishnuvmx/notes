import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Shared Container Transform wrapper built on `package:animations`'s
/// [OpenContainer] so any Note or Board card expands organically into its
/// full-screen detail view and collapses smoothly back into its card on Back.
///
/// Sets `tappable: false` so inner card `InkWell`s keep tactile press scales,
/// long-press peek menus, and independent action buttons without gesture conflicts.
class TackCardOpenContainer extends StatelessWidget {
  final WidgetBuilder openBuilder;
  final Widget Function(BuildContext context, VoidCallback openContainer)
  closedBuilder;
  final ShapeBorder? closedShape;
  final Color? closedColor;
  final Color? openColor;
  final List<BoxShadow>? closedShadows;
  final Duration transitionDuration;

  const TackCardOpenContainer({
    super.key,
    required this.openBuilder,
    required this.closedBuilder,
    this.closedShape,
    this.closedColor,
    this.openColor,
    this.closedShadows,
    this.transitionDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final resolvedClosedColor = closedColor ?? tokens.surfacePrimary;
    final resolvedOpenColor = openColor ?? tokens.canvasPrimary;
    final resolvedShape =
        closedShape ??
        SmoothRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          smoothness: AppSpacing.defaultSmoothing,
          side: BorderSide(
            color: tokens.borderSubtle.withValues(alpha: 0.7),
            width: 1,
          ),
        );

    return OpenContainer<void>(
      transitionDuration: transitionDuration,
      transitionType: ContainerTransitionType.fade,
      tappable: false,
      closedElevation: 0,
      openElevation: 0,
      closedColor: resolvedClosedColor,
      openColor: resolvedOpenColor,
      middleColor: resolvedOpenColor,
      closedShape: resolvedShape,
      openShape: const RoundedRectangleBorder(),
      closedShadows: closedShadows ?? AppSpacing.elev1(tokens.isDark),
      openShadows: const [],
      closedBuilder: closedBuilder,
      openBuilder: (context, _) => RepaintBoundary(child: openBuilder(context)),
    );
  }
}
