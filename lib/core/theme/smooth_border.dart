import 'dart:math' as math;
import 'package:flutter/material.dart';

/// An [OutlinedBorder] providing Figma / iOS squircle continuous corner smoothing (40-60%).
///
/// Features:
/// - Eliminates sharp curvature jumps ($G^2$ continuous curvature) between straight edges and rounded corners.
/// - [smoothness]: Value between 0.0 (standard circular arc) and 1.0 (maximum superellipse).
///   Defaults to 0.6 (60% iOS / Figma squircle continuous curvature).
/// - Fully compatible with [ShapeDecoration], [Material], [Card], [Dialog], and button shapes.
class SmoothRectangleBorder extends OutlinedBorder {
  final BorderRadius borderRadius;
  final double smoothness;

  const SmoothRectangleBorder({
    super.side,
    this.borderRadius = BorderRadius.zero,
    this.smoothness = 0.6,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ShapeBorder scale(double t) {
    return SmoothRectangleBorder(
      side: side.scale(t),
      borderRadius: borderRadius * t,
      smoothness: smoothness,
    );
  }

  @override
  OutlinedBorder copyWith({
    BorderSide? side,
    BorderRadius? borderRadius,
    double? smoothness,
  }) {
    return SmoothRectangleBorder(
      side: side ?? this.side,
      borderRadius: borderRadius ?? this.borderRadius,
      smoothness: smoothness ?? this.smoothness,
    );
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    final innerRect = rect.deflate(side.width);
    if (innerRect.isEmpty) return Path();
    return _buildSmoothPath(
      innerRect,
      borderRadius.resolve(textDirection),
      smoothness,
    );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return _buildSmoothPath(
      rect,
      borderRadius.resolve(textDirection),
      smoothness,
    );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (rect.isEmpty) return;

    if (side.style == BorderStyle.solid && side.width > 0.0) {
      final paint = side.toPaint();
      final path = getOuterPath(rect, textDirection: textDirection);
      if (side.width <= 1.0) {
        canvas.drawPath(path, paint);
      } else {
        final innerPath = getInnerPath(rect, textDirection: textDirection);
        final diff = Path.combine(PathOperation.difference, path, innerPath);
        paint.style = PaintingStyle.fill;
        canvas.drawPath(diff, paint);
      }
    }
  }

  static Path _buildSmoothPath(
    Rect rect,
    BorderRadius resolvedRadius,
    double smoothness,
  ) {
    final path = Path();
    final width = rect.width;
    final height = rect.height;
    if (width <= 0 || height <= 0) return path;

    final halfW = width / 2.0;
    final halfH = height / 2.0;
    final maxRadius = math.min(halfW, halfH);

    final tl = resolvedRadius.topLeft.x.clamp(0.0, maxRadius);
    final tr = resolvedRadius.topRight.x.clamp(0.0, maxRadius);
    final br = resolvedRadius.bottomRight.x.clamp(0.0, maxRadius);
    final bl = resolvedRadius.bottomLeft.x.clamp(0.0, maxRadius);

    final s = smoothness.clamp(0.0, 1.0);

    // If smoothing is 0 or all radii are 0, use standard RRect
    if (s == 0.0 || (tl == 0 && tr == 0 && br == 0 && bl == 0)) {
      path.addRRect(RRect.fromRectAndCorners(
        rect,
        topLeft: Radius.circular(tl),
        topRight: Radius.circular(tr),
        bottomRight: Radius.circular(br),
        bottomLeft: Radius.circular(bl),
      ));
      return path;
    }

    // Build continuous squircle path
    // 1. Top edge -> Top-Right Corner
    path.moveTo(rect.left + _cornerP(tl, s, maxRadius), rect.top);
    path.lineTo(rect.right - _cornerP(tr, s, maxRadius), rect.top);
    _addSmoothCorner(
      path: path,
      cornerCenterX: rect.right,
      cornerCenterY: rect.top,
      r: tr,
      s: s,
      maxR: maxRadius,
      corner: _Corner.topRight,
    );

    // 2. Right edge -> Bottom-Right Corner
    path.lineTo(rect.right, rect.bottom - _cornerP(br, s, maxRadius));
    _addSmoothCorner(
      path: path,
      cornerCenterX: rect.right,
      cornerCenterY: rect.bottom,
      r: br,
      s: s,
      maxR: maxRadius,
      corner: _Corner.bottomRight,
    );

    // 3. Bottom edge -> Bottom-Left Corner
    path.lineTo(rect.left + _cornerP(bl, s, maxRadius), rect.bottom);
    _addSmoothCorner(
      path: path,
      cornerCenterX: rect.left,
      cornerCenterY: rect.bottom,
      r: bl,
      s: s,
      maxR: maxRadius,
      corner: _Corner.bottomLeft,
    );

    // 4. Left edge -> Top-Left Corner
    path.lineTo(rect.left, rect.top + _cornerP(tl, s, maxRadius));
    _addSmoothCorner(
      path: path,
      cornerCenterX: rect.left,
      cornerCenterY: rect.top,
      r: tl,
      s: s,
      maxR: maxRadius,
      corner: _Corner.topLeft,
    );

    path.close();
    return path;
  }

  static double _cornerP(double r, double s, double maxR) {
    if (r <= 0) return 0.0;
    final p = (1.0 + s) * r;
    return p > maxR ? maxR : p;
  }

  static void _addSmoothCorner({
    required Path path,
    required double cornerCenterX,
    required double cornerCenterY,
    required double r,
    required double s,
    required double maxR,
    required _Corner corner,
  }) {
    if (r <= 0.0) {
      path.lineTo(cornerCenterX, cornerCenterY);
      return;
    }

    double p = (1.0 + s) * r;
    double effectiveR = r;
    if (p > maxR) {
      final ratio = maxR / p;
      p = maxR;
      effectiveR = r * ratio;
    }

    final alpha = (math.pi / 4.0) * (1.0 - s);
    final sinA = math.sin(alpha);
    final cosA = math.cos(alpha);

    // Distance from the corner along axes
    final aX = effectiveR * (1.0 - sinA);
    final aY = effectiveR * (1.0 - cosA);

    // Control point metrics
    final c1x = p - (p - aX) * 0.45;
    final c1y = 0.0;

    final tanA = math.max(0.001, math.tan(alpha));
    final c2x = aX + (aY / tanA) * 0.35;
    final c2y = aY * 0.65;

    // Transform normalized top-right corner to actual target corner orientation
    Offset transform(double localX, double localY) {
      switch (corner) {
        case _Corner.topRight:
          return Offset(cornerCenterX - localX, cornerCenterY + localY);
        case _Corner.bottomRight:
          return Offset(cornerCenterX - localY, cornerCenterY - localX);
        case _Corner.bottomLeft:
          return Offset(cornerCenterX + localX, cornerCenterY - localY);
        case _Corner.topLeft:
          return Offset(cornerCenterX + localY, cornerCenterY + localX);
      }
    }

    // 1. First easing cubic Bezier curve (straight edge -> circular arc)
    final p1 = transform(aX, aY);
    final cp1 = transform(c1x, c1y);
    final cp2 = transform(c2x, c2y);
    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);

    // 2. Circular middle arc (between alpha and 90 deg - alpha)
    final p2 = transform(aY, aX);
    path.arcToPoint(
      p2,
      radius: Radius.circular(effectiveR),
      clockwise: true,
    );

    // 3. Second easing cubic Bezier curve (circular arc -> exit straight edge)
    final p3 = transform(0.0, p);
    final cp3 = transform(c2y, c2x);
    final cp4 = transform(c1y, c1x);
    path.cubicTo(cp3.dx, cp3.dy, cp4.dx, cp4.dy, p3.dx, p3.dy);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is SmoothRectangleBorder &&
        other.side == side &&
        other.borderRadius == borderRadius &&
        other.smoothness == smoothness;
  }

  @override
  int get hashCode => Object.hash(side, borderRadius, smoothness);
}

enum _Corner { topRight, bottomRight, bottomLeft, topLeft }

