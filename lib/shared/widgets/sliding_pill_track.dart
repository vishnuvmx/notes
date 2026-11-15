import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Shared pill-shaped segmented track with a single continuous gliding indicator
/// pill, matching the smooth sliding feel of `SettingsScreen`'s `TabBar`.
///
/// Using one animated pill inside a `Stack` avoids the jarring two-pill
/// cross-fade blink that occurs when each segment animates its own background.
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
    this.curve = Curves.easeOutCubic,
  }) : assert(itemCount > 0 && children.length == itemCount);

  @override
  State<SlidingPillTrack> createState() => _SlidingPillTrackState();
}

class _SlidingPillTrackState extends State<SlidingPillTrack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late CurvedAnimation _curvedAnimation;
  late Animation<Offset> _slideAnimation;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = _safeIndex(widget.selectedIndex, widget.itemCount);
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1.0,
    );
    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
    _slideAnimation = AlwaysStoppedAnimation<Offset>(
      Offset(_currentIndex.toDouble(), 0),
    );
  }

  int _safeIndex(int index, int count) => index.clamp(0, count - 1);

  @override
  void didUpdateWidget(covariant SlidingPillTrack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.curve != widget.curve) {
      _curvedAnimation.dispose();
      _curvedAnimation = CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      );
    }

    final nextIndex = _safeIndex(widget.selectedIndex, widget.itemCount);
    if (nextIndex != _currentIndex || oldWidget.itemCount != widget.itemCount) {
      final fromOffset = Offset(
        _slideAnimation.value.dx.clamp(0.0, (widget.itemCount - 1).toDouble()),
        0,
      );
      _currentIndex = nextIndex;
      _slideAnimation = Tween<Offset>(
        begin: fromOffset,
        end: Offset(nextIndex.toDouble(), 0),
      ).animate(_curvedAnimation);
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _curvedAnimation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        height: widget.height,
        clipBehavior: Clip.antiAlias,
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
                alignment: Alignment.centerLeft,
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
