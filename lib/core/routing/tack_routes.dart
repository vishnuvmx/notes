import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Shared page-route transition factories tailored to Tack's navigation hierarchy.
///
/// - [sharedAxisHorizontal]: Animates both incoming (`animation`) and outgoing
///   (`secondaryAnimation`) pages along the X axis for nested drill-downs
///   (`Note → Sub-note/WikiLink`, `Settings → About/Trash`, `Folder → Item`).
/// - [slideUp]: Vertical rise transition for modal context switches (`Settings`,
///   `KnowledgeGraphScreen`, `Mermaid` board expand, `Welcome Guide` replay)
///   with subtle secondary retreat when another route stacks above it.
/// - [heroImageShuttle]: Rounded-to-square clip morph for inline image → lightbox
///   [Hero] flights without hard corner pops.
class TackRoutes {
  TackRoutes._();

  static Route<T> sharedAxisHorizontal<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        return _SecondaryAxisMotion(
          secondaryAnimation: secondaryAnimation,
          endOffset: const Offset(-0.08, 0),
          child: TackAnimatedTransition(
            animation: animation,
            slideBegin: const Offset(0.14, 0),
            child: child,
          ),
        );
      },
    );
  }

  static Route<T> slideUp<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        return _SecondaryAxisMotion(
          secondaryAnimation: secondaryAnimation,
          endOffset: const Offset(0, -0.025),
          child: TackAnimatedTransition(
            animation: animation,
            slideBegin: const Offset(0, 0.10),
            child: child,
          ),
        );
      },
    );
  }

  static Widget heroImageShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final targetHero = flightDirection == HeroFlightDirection.push
        ? toHeroContext.widget as Hero
        : fromHeroContext.widget as Hero;

    return AnimatedBuilder(
      animation: animation,
      child: RepaintBoundary(child: targetHero.child),
      builder: (_, child) {
        final t = AppSpacing.silky120Hz.transform(animation.value);
        final radius = BorderRadius.lerp(
          BorderRadius.circular(AppSpacing.radiusMd),
          BorderRadius.zero,
          t,
        );
        return ClipRRect(
          borderRadius: radius ?? BorderRadius.zero,
          child: child,
        );
      },
    );
  }
}

/// Animates the underlying route smoothly (`secondaryAnimation`) when another
/// route is pushed above it, properly managing and disposing its [CurvedAnimation].
class _SecondaryAxisMotion extends StatefulWidget {
  final Animation<double> secondaryAnimation;
  final Offset endOffset;
  final Widget child;

  const _SecondaryAxisMotion({
    required this.secondaryAnimation,
    this.endOffset = Offset.zero,
    required this.child,
  });

  @override
  State<_SecondaryAxisMotion> createState() => _SecondaryAxisMotionState();
}

class _SecondaryAxisMotionState extends State<_SecondaryAxisMotion> {
  late CurvedAnimation _curved;
  Animation<Offset>? _offsetAnim;

  @override
  void initState() {
    super.initState();
    _initCurve();
  }

  @override
  void didUpdateWidget(covariant _SecondaryAxisMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.secondaryAnimation != widget.secondaryAnimation ||
        oldWidget.endOffset != widget.endOffset) {
      _curved.dispose();
      _initCurve();
    }
  }

  void _initCurve() {
    _curved = CurvedAnimation(
      parent: widget.secondaryAnimation,
      curve: AppSpacing.silky120Hz,
      reverseCurve: Curves.easeInCubic,
    );
    _offsetAnim = widget.endOffset == Offset.zero
        ? null
        : Tween<Offset>(
            begin: Offset.zero,
            end: widget.endOffset,
          ).animate(_curved);
  }

  @override
  void dispose() {
    _curved.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_offsetAnim != null) {
      return SlideTransition(
        position: _offsetAnim!,
        child: RepaintBoundary(child: widget.child),
      );
    }
    return widget.child;
  }
}
