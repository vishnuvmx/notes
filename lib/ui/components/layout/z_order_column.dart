import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A [Flex] column that paints its children in reverse (bottom-to-top) order.
///
/// This ensures that earlier (top-most) sections and cards are painted on top
/// of later (bottom-most) sections on the Z-axis. Consequently, downward-facing
/// drop shadows cast by upper containers naturally fall on top of lower
/// containers instead of being clipped by subsequent opaque sibling surfaces.
class ZOrderColumn extends Flex {
  const ZOrderColumn({
    super.key,
    super.mainAxisAlignment = MainAxisAlignment.start,
    super.mainAxisSize = MainAxisSize.max,
    super.crossAxisAlignment = CrossAxisAlignment.center,
    super.textDirection,
    super.verticalDirection = VerticalDirection.down,
    super.textBaseline,
    super.clipBehavior = Clip.none,
    super.children,
  }) : super(direction: Axis.vertical);

  @override
  RenderZOrderFlex createRenderObject(BuildContext context) {
    return RenderZOrderFlex(
      direction: direction,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: getEffectiveTextDirection(context),
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderZOrderFlex renderObject) {
    super.updateRenderObject(context, renderObject);
  }
}

class RenderZOrderFlex extends RenderFlex {
  RenderZOrderFlex({
    super.direction = Axis.vertical,
    super.mainAxisAlignment = MainAxisAlignment.start,
    super.mainAxisSize = MainAxisSize.max,
    super.crossAxisAlignment = CrossAxisAlignment.center,
    super.textDirection,
    super.verticalDirection = VerticalDirection.down,
    super.textBaseline,
    super.clipBehavior = Clip.none,
    List<RenderBox>? children,
  }) {
    addAll(children);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (firstChild == null) return;

    // Collect children in layout order
    final children = <RenderBox>[];
    RenderBox? child = firstChild;
    while (child != null) {
      children.add(child);
      child = (child.parentData! as FlexParentData).nextSibling;
    }

    // Paint in reverse order: bottom children first (lowest Z),
    // top children last (highest Z, closest to user).
    // This allows top containers' drop shadows to cast over lower containers.
    for (int i = children.length - 1; i >= 0; i--) {
      final childBox = children[i];
      final childParentData = childBox.parentData! as FlexParentData;
      context.paintChild(childBox, childParentData.offset + offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (firstChild == null) return false;

    // Hit test in Z-order: top-most child (closest to user) tested first
    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData! as FlexParentData;
      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          return child!.hitTest(result, position: transformed);
        },
      );
      if (isHit) return true;
      child = childParentData.nextSibling;
    }
    return false;
  }
}
