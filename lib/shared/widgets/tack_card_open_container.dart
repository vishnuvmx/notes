import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Fast, zero-glitch card wrapper that pushes the destination screen immediately
/// with a crisp 160ms hardware-composited slide (no fade ghosting, no
/// `GlobalKey` reparenting, no `OverflowBox` scale clipping).
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
    this.transitionDuration = const Duration(milliseconds: 160),
  });

  void _open(BuildContext context) {
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        transitionDuration: transitionDuration,
        reverseTransitionDuration: const Duration(milliseconds: 130),
        pageBuilder: (routeContext, _, _) => openBuilder(routeContext),
        transitionsBuilder: (_, animation, _, child) {
          final offset =
              Tween<Offset>(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: AppSpacing.silky120Hz,
                  reverseCurve: Curves.easeInCubic,
                ),
              );
          return SlideTransition(position: offset, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final resolvedClosedColor = closedColor ?? tokens.surfacePrimary;
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

    return Container(
      decoration: ShapeDecoration(
        color: resolvedClosedColor,
        shadows: closedShadows ?? AppSpacing.elev1(tokens.isDark),
        shape: resolvedShape,
      ),
      clipBehavior: Clip.antiAlias,
      child: closedBuilder(context, () => _open(context)),
    );
  }
}
