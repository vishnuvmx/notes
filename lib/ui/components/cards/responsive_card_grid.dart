import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';

/// Responsive multi-column masonry card grid for Paper & Pin (`07-design-system.md` §4.3).
/// Distributes intrinsic-height cards across 2/3/4 columns without external package dependencies.
class ResponsiveCardGrid extends StatelessWidget {
  final int crossAxisCount;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const ResponsiveCardGrid({
    super.key,
    required this.crossAxisCount,
    required this.itemCount,
    required this.itemBuilder,
    this.mainAxisSpacing = AppSpacing.gapGrid,
    this.crossAxisSpacing = AppSpacing.gapGrid,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final columns = _buildColumns(context);
    if (shrinkWrap) {
      return Padding(
        padding: padding ?? EdgeInsets.zero,
        child: columns,
      );
    }
    return SingleChildScrollView(
      physics: physics ?? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: padding,
      child: columns,
    );
  }

  Widget _buildColumns(BuildContext context) {
    final colCount = crossAxisCount.clamp(1, 6);
    final List<List<Widget>> columnChildren = List.generate(colCount, (_) => []);

    for (var i = 0; i < itemCount; i++) {
      final colIndex = i % colCount;
      if (columnChildren[colIndex].isNotEmpty) {
        columnChildren[colIndex].add(SizedBox(height: mainAxisSpacing));
      }
      columnChildren[colIndex].add(itemBuilder(context, i));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var c = 0; c < colCount; c++) ...[
          if (c > 0) SizedBox(width: crossAxisSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: columnChildren[c],
            ),
          ),
        ],
      ],
    );
  }
}

/// Sliver variant of [ResponsiveCardGrid] for use inside [CustomScrollView].
class SliverResponsiveCardGrid extends StatelessWidget {
  final int crossAxisCount;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  const SliverResponsiveCardGrid({
    super.key,
    required this.crossAxisCount,
    required this.itemCount,
    required this.itemBuilder,
    this.mainAxisSpacing = AppSpacing.gapGrid,
    this.crossAxisSpacing = AppSpacing.gapGrid,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: ResponsiveCardGrid(
        crossAxisCount: crossAxisCount,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        shrinkWrap: true,
      ),
    );
  }
}

