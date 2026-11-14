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
      final inset = side.width / 2.0;
      final strokeRect = rect.deflate(inset);
      if (strokeRect.isEmpty) return;
      final resolved = borderRadius.resolve(textDirection);
      final insetRadius = BorderRadius.only(
        topLeft: Radius.circular(math.max(0.0, resolved.topLeft.x - inset)),
        topRight: Radius.circular(math.max(0.0, resolved.topRight.x - inset)),
        bottomRight: Radius.circular(math.max(0.0, resolved.bottomRight.x - inset)),
        bottomLeft: Radius.circular(math.max(0.0, resolved.bottomLeft.x - inset)),
      );
      final strokePath = _buildSmoothPath(strokeRect, insetRadius, smoothness);
      canvas.drawPath(strokePath, side.toPaint());
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
    if (s <= 0.001) return r > maxR ? maxR : r;
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

    // Transform normalized top-right corner to actual target corner orientation.
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

    if (s <= 0.001) {
      final effectiveR = r > maxR ? maxR : r;
      final p2 = transform(0.0, effectiveR);
      path.arcToPoint(
        p2,
        radius: Radius.circular(effectiveR),
        clockwise: true,
      );
      return;
    }

    double p = (1.0 + s) * r;
    double effectiveR = r;
    if (p > maxR) {
      final ratio = maxR / p;
      p = maxR;
      effectiveR = r * ratio;
    }

    // Blend angle from straight edge to circular arc: 0 at s=0 (pure circle), pi/4 at s=1.
    final beta = (math.pi / 4.0) * s;
    final sinB = math.sin(beta);
    final cosB = math.cos(beta);
    final tanB = math.tan(beta);

    // Circular arc anchor (aX, aY) where curvature enters/exits 1/effectiveR.
    final aX = effectiveR * (1.0 - sinB);
    final aY = effectiveR * (1.0 - cosB);

    // Tangent line from (aX, aY) meets straight edge y=0 at xTan; d is handle length.
    final d = aY / sinB;
    final xTan = aX + aY / tanB;

    // Solve c1x for exact G2 curvature match: kappa(0)=0, kappa(1)=1/effectiveR.
    final h = 1.5 * d * d / effectiveR;
    final c1x = math.min(p, xTan + h / sinB);

    // 1. Entry cubic Bezier curve (straight edge -> circular arc)
    final p1 = transform(aX, aY);
    final cp1 = transform(c1x, 0.0);
    final cp2 = transform(xTan, 0.0);
    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);

    // 2. Circular middle arc (omitted cleanly when s approaches 1.0)
    final p2 = transform(aY, aX);
    if ((p1 - p2).distance > 1e-3) {
      path.arcToPoint(
        p2,
        radius: Radius.circular(effectiveR),
        clockwise: true,
      );
    }

    // 3. Symmetric exit cubic Bezier curve (circular arc -> exit straight edge)
    final p3 = transform(0.0, p);
    final cp3 = transform(0.0, xTan);
    final cp4 = transform(0.0, c1x);
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

