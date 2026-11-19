import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../core/theme/app_spacing.dart';

/// Shared pill-shaped segmented track with a single continuous gliding indicator
/// pill driven by a critically-damped 120Hz [SpringSimulation] so rapid taps
/// preserve velocity and settle with zero overshoot or cross-fade flicker.
class SlidingPillTrack extends StatefulWidget {
  final int itemCount;
  final int selectedIndex;
  final Color trackColor;
  final Color indicatorColor;
  final List<BoxShadow>? indicatorShadow;
  final List<BoxShadow>? trackShadow;
  final double? height;
  final EdgeInsetsGeometry padding;
  final Duration duration;
  final Curve curve;
  final List<Widget> children;

  const SlidingPillTrack({
    super.key,
    required this.itemCount,
    required this.selectedIndex,
    required this.trackColor,
    required this.indicatorColor,
    required this.children,
    this.indicatorShadow,
    this.trackShadow,
    this.height,
    this.padding = const EdgeInsets.all(4),
    this.duration = const Duration(milliseconds: 220),
    this.curve = AppSpacing.silky120Hz,
  }) : assert(itemCount > 0 && children.length == itemCount);

  @override
  State<SlidingPillTrack> createState() => _SlidingPillTrackState();
}

class _SlidingPillTrackState extends State<SlidingPillTrack>
    with SingleTickerProviderStateMixin {
  /// Critically-damped spring (ζ ≈ 1.0): responsive 120Hz glide, zero bounce.
  static const SpringDescription _glideSpring = SpringDescription(
    mass: 1.0,
    stiffness: 520.0,
    damping: 46.0,
  );

  late final AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late int _currentIndex;
  bool _isRtl = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = _safeIndex(widget.selectedIndex, widget.itemCount);
    _controller = AnimationController.unbounded(
      vsync: this,
      value: _signedDx(_currentIndex.toDouble()),
    );
    _slideAnimation = _OffsetXAnimation(_controller);
  }

  double _signedDx(double dx) => _isRtl ? -dx : dx;

  int _safeIndex(int index, int count) => index.clamp(0, count - 1);

  void _animateToIndex(int nextIndex) {
    final target = _signedDx(nextIndex.toDouble());
    final current = _controller.value;
    if ((current - target).abs() < 0.0005 &&
        _controller.velocity.abs() < 0.01) {
      _controller.value = target;
      return;
    }
    final simulation = SpringSimulation(
      _glideSpring,
      current,
      target,
      _controller.velocity,
      tolerance: const Tolerance(distance: 0.0005, velocity: 0.005),
    );
    _controller.animateWith(simulation);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextRtl = Directionality.of(context) == TextDirection.rtl;
    if (nextRtl != _isRtl) {
      _isRtl = nextRtl;
      _controller.value = _signedDx(_currentIndex.toDouble());
    }
  }

  @override
  void didUpdateWidget(covariant SlidingPillTrack oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = _safeIndex(widget.selectedIndex, widget.itemCount);
    if (nextIndex != _currentIndex || oldWidget.itemCount != widget.itemCount) {
      final minDx = _isRtl ? -(widget.itemCount - 1).toDouble() : 0.0;
      final maxDx = _isRtl ? 0.0 : (widget.itemCount - 1).toDouble();
      _controller.value = _controller.value.clamp(minDx, maxDx);
      _currentIndex = nextIndex;
      _animateToIndex(nextIndex);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        height: widget.height,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.trackColor,
          borderRadius: AppSpacing.roundedPill,
          boxShadow: widget.trackShadow,
        ),
        child: Stack(
          fit: widget.height != null ? StackFit.expand : StackFit.passthrough,
          children: [
            Positioned.fill(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: 1 / widget.itemCount,
                  heightFactor: 1,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: RepaintBoundary(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: widget.indicatorColor,
                          borderRadius: AppSpacing.roundedPill,
                          boxShadow: widget.indicatorShadow,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (final child in widget.children) Expanded(child: child),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Zero-allocation [Animation<Offset>] mapping a scalar X controller directly
/// into `Offset(x, 0)` for GPU-composited [SlideTransition].
class _OffsetXAnimation extends Animation<Offset>
    with AnimationWithParentMixin<double> {
  @override
  final Animation<double> parent;

  _OffsetXAnimation(this.parent);

  @override
  Offset get value => Offset(parent.value, 0.0);
}
