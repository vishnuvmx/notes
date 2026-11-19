import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import 'z_order_column.dart';

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
      return Padding(padding: padding ?? EdgeInsets.zero, child: columns);
    }
    return SingleChildScrollView(
      physics:
          physics ??
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: padding,
      child: columns,
    );
  }

  Widget _buildColumns(BuildContext context) {
    final colCount = crossAxisCount.clamp(1, 6);
    final List<List<Widget>> columnChildren = List.generate(
      colCount,
      (_) => [],
    );

    for (var i = 0; i < itemCount; i++) {
      final colIndex = i % colCount;
      if (columnChildren[colIndex].isNotEmpty) {
        columnChildren[colIndex].add(SizedBox(height: mainAxisSpacing));
      }
      columnChildren[colIndex].add(
        RepaintBoundary(child: itemBuilder(context, i)),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var c = 0; c < colCount; c++) ...[
          if (c > 0) SizedBox(width: crossAxisSpacing),
          Expanded(
            child: ZOrderColumn(
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

/// Lazy Sliver variant of [ResponsiveCardGrid] for use inside [CustomScrollView].
/// Builds only visible rows via [SliverList.builder] so large libraries scroll at 120fps.
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
    final colCount = crossAxisCount.clamp(1, 6);
    final rowCount = (itemCount + colCount - 1) ~/ colCount;
    if (rowCount == 0) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverList.builder(
      itemCount: rowCount,
      itemBuilder: (context, rowIndex) {
        final start = rowIndex * colCount;
        final isLastRow = rowIndex == rowCount - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLastRow ? 0 : mainAxisSpacing),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var c = 0; c < colCount; c++) ...[
                if (c > 0) SizedBox(width: crossAxisSpacing),
                Expanded(
                  child: (start + c < itemCount)
                      ? RepaintBoundary(child: itemBuilder(context, start + c))
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
