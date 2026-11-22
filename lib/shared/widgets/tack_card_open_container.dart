import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Zero-rebuild, 120fps GPU-composited Container Transform wrapper.
///
/// Expands any Note or Board card physically from its exact grid rectangle
/// into its full-screen destination and collapses it cleanly back into its
/// slot on Back — without rebuilding the destination screen during flight,
/// without `Opacity`/`FadeTransition` ghosting, and without per-frame path
/// or shadow re-rasterization.
class TackCardOpenContainer extends StatefulWidget {
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
    this.transitionDuration = const Duration(milliseconds: 260),
  });

  @override
  State<TackCardOpenContainer> createState() => _TackCardOpenContainerState();
}

class _TackCardOpenContainerState extends State<TackCardOpenContainer> {
  final GlobalKey _sourceCardKey = GlobalKey();
  bool _isCardHidden = false;

  void _setCardHidden(bool hidden) {
    if (!mounted || _isCardHidden == hidden) return;
    setState(() => _isCardHidden = hidden);
  }

  Rect? _measureSourceRect(BuildContext navigatorContext) {
    final cardContext = _sourceCardKey.currentContext;
    if (cardContext == null) return null;
    final cardBox = cardContext.findRenderObject() as RenderBox?;
    final navBox =
        Navigator.of(navigatorContext).context.findRenderObject() as RenderBox?;
    if (cardBox == null ||
        navBox == null ||
        !cardBox.attached ||
        !navBox.attached ||
        !cardBox.hasSize ||
        !navBox.hasSize) {
      return null;
    }
    return MatrixUtils.transformRect(
      cardBox.getTransformTo(navBox),
      Offset.zero & cardBox.size,
    );
  }

  double _resolveClosedRadius() {
    final shape = widget.closedShape;
    if (shape is SmoothRectangleBorder) {
      return shape.borderRadius.resolve(TextDirection.ltr).topLeft.x;
    }
    if (shape is RoundedRectangleBorder) {
      return shape.borderRadius.resolve(TextDirection.ltr).topLeft.x;
    }
    return AppSpacing.radiusMd;
  }

  void _openContainer() {
    final tokens = context.tokens;
    final initialRect = _measureSourceRect(context);
    final openColor = widget.openColor ?? tokens.canvasPrimary;

    Navigator.of(context).push<void>(
      _TackContainerTransformRoute(
        openBuilder: widget.openBuilder,
        initialRect: initialRect,
        measureRect: () => _measureSourceRect(context),
        onVisibilityChanged: _setCardHidden,
        openColor: openColor,
        closedRadius: _resolveClosedRadius(),
        forwardDuration: widget.transitionDuration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final resolvedClosedColor = widget.closedColor ?? tokens.surfacePrimary;
    final resolvedShape =
        widget.closedShape ??
        SmoothRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          smoothness: AppSpacing.defaultSmoothing,
          side: BorderSide(
            color: tokens.borderSubtle.withValues(alpha: 0.7),
            width: 1,
          ),
        );

    return Visibility(
      key: _sourceCardKey,
      visible: !_isCardHidden,
      maintainSize: true,
      maintainState: true,
      maintainAnimation: true,
      child: Container(
        decoration: ShapeDecoration(
          color: resolvedClosedColor,
          shadows: widget.closedShadows ?? AppSpacing.elev1(tokens.isDark),
          shape: resolvedShape,
        ),
        clipBehavior: Clip.antiAlias,
        child: widget.closedBuilder(context, _openContainer),
      ),
    );
  }
}

/// Custom [ModalRoute] implementing a pure GPU-composited Container Transform:
/// - Builds [openBuilder] once and caches it inside a single [RepaintBoundary].
/// - Locks child layout to final viewport constraints via [OverflowBox] so
///   complex note readers and whiteboards never relayout mid-flight.
/// - Animates geometry using hardware-accelerated [ClipRRect] + [Matrix4]
///   uniform scale on a single cached [CurvedAnimation] (zero per-frame leaks).
class _TackContainerTransformRoute extends ModalRoute<void> {
  final WidgetBuilder openBuilder;
  final Rect? initialRect;
  final Rect? Function() measureRect;
  final ValueChanged<bool> onVisibilityChanged;
  final Color openColor;
  final double closedRadius;
  final Duration forwardDuration;

  _TackContainerTransformRoute({
    required this.openBuilder,
    required this.initialRect,
    required this.measureRect,
    required this.onVisibilityChanged,
    required this.openColor,
    required this.closedRadius,
    required this.forwardDuration,
  });

  final GlobalKey _openChildKey = GlobalKey();
  Widget? _cachedOpenChild;
  CurvedAnimation? _curvedAnimation;
  Rect? _beginRect;

  @override
  Duration get transitionDuration => forwardDuration;

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 210);

  @override
  bool get opaque => true;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  TickerFuture didPush() {
    _beginRect = initialRect;
    onVisibilityChanged(true);

    final anim = animation!;
    _curvedAnimation = CurvedAnimation(
      parent: anim,
      curve: AppSpacing.silky120Hz,
      reverseCurve: AppSpacing.silky120Hz.flipped,
    );
    anim.addStatusListener(_handleStatus);
    return super.didPush();
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      onVisibilityChanged(false);
    } else if (status == AnimationStatus.forward ||
        status == AnimationStatus.completed) {
      onVisibilityChanged(true);
    }
  }

  @override
  bool didPop(void result) {
    // Re-measure source card rect in case the grid scrolled or viewport rotated.
    final freshRect = measureRect();
    if (freshRect != null) {
      _beginRect = freshRect;
    }
    return super.didPop(result);
  }

  @override
  void dispose() {
    animation?.removeStatusListener(_handleStatus);
    _curvedAnimation?.dispose();
    _curvedAnimation = null;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      onVisibilityChanged(false);
    });
    super.dispose();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    _cachedOpenChild ??= KeyedSubtree(
      key: _openChildKey,
      child: RepaintBoundary(child: openBuilder(context)),
    );

    final curved = _curvedAnimation ?? animation;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fullSize = constraints.biggest;
        final fullRect = Offset.zero & fullSize;
        final startRect =
            _beginRect ??
            Rect.fromCenter(
              center: fullRect.center,
              width: fullSize.width * 0.44,
              height: fullSize.height * 0.28,
            );

        return AnimatedBuilder(
          animation: animation,
          child: _cachedOpenChild,
          builder: (context, child) {
            if (animation.isCompleted) {
              return child!;
            }

            final t = curved.value.clamp(0.0, 1.0);
            final rect = Rect.lerp(startRect, fullRect, t)!;
            final radius = (closedRadius * (1.0 - t)).clamp(0.0, closedRadius);
            final scale = fullSize.width > 0
                ? (rect.width / fullSize.width).clamp(0.05, 1.0)
                : 1.0;

            return Stack(
              fit: StackFit.expand,
              children: [
                if (t > 0.001)
                  IgnorePointer(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.14 * t),
                    ),
                  ),
                Positioned(
                  left: rect.left,
                  top: rect.top,
                  width: rect.width,
                  height: rect.height,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: ColoredBox(
                      color: openColor,
                      child: OverflowBox(
                        alignment: Alignment.topLeft,
                        minWidth: fullSize.width,
                        maxWidth: fullSize.width,
                        minHeight: fullSize.height,
                        maxHeight: fullSize.height,
                        child: Transform(
                          alignment: Alignment.topLeft,
                          transform: Matrix4.diagonal3Values(scale, scale, 1.0),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
