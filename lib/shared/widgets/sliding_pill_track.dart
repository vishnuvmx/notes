import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Shared pill-shaped segmented track with a single continuous gliding indicator
/// pill, matching the smooth sliding feel of `SettingsScreen`'s `TabBar`.
///
/// Using one animated pill inside a `Stack` avoids the jarring two-pill
/// cross-fade blink that occurs when each segment animates its own background.
class SlidingPillTrack extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final safeIndex = selectedIndex.clamp(0, itemCount - 1);
    final alignX = itemCount == 1 ? 0.0 : -1.0 + (2.0 * safeIndex / (itemCount - 1));

    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      padding: padding,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: AppSpacing.roundedPill,
        boxShadow: trackShadow,
      ),
      child: Stack(
        fit: height != null ? StackFit.expand : StackFit.passthrough,
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              alignment: Alignment(alignX, 0),
              duration: duration,
              curve: curve,
              child: FractionallySizedBox(
                widthFactor: 1 / itemCount,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: indicatorColor,
                    borderRadius: AppSpacing.roundedPill,
                    boxShadow: indicatorShadow,
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final child in children) Expanded(child: child),
            ],
          ),
        ],
      ),
    );
  }
}
