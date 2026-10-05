import 'dart:math';

class Point2D {
  final double x;
  final double y;

  const Point2D(this.x, this.y);

  double distanceTo(Point2D other) {
    final dx = x - other.x;
    final dy = y - other.y;

    return sqrt((dx * dx) + (dy * dy));
  }
}

class GeometryUtils {
  const GeometryUtils._();

  static Point2D midpoint(Point2D a, Point2D b) {
    return Point2D(
      (a.x + b.x) / 2,
      (a.y + b.y) / 2,
    );
  }

  static double distance(Point2D a, Point2D b) {
    return a.distanceTo(b);
  }

  static double clamp(
    double value,
    double min,
    double max,
  ) {
    if (value < min) return min;
    if (value > max) return max;

    return value;
  }

  static bool isPointNear(
    Point2D point,
    Point2D target,
    double tolerance,
  ) {
    return distance(point, target) <= tolerance;
  }
}
