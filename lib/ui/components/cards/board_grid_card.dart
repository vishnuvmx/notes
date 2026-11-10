import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/whiteboard_item.dart';

/// Board Grid Card (`07-design-system.md` §7, `04-feature-strategy.md` M8/F7).
///
/// Anatomy:
/// - Outer container: `surface/primary`, `1dp` `border/subtle`, `r-md` (`12dp`), `elev/1`
/// - Top `120dp`: live mini-canvas thumbnail (`CustomPaint` of actual node shapes and
///   connector edges in their object colours) on `canvas/sunken`
/// - Bottom section: board title (`title-sm`, 1 line) + node/link count & updated date (`caption`)
///   + `TackPinBadge` if pinned
class BoardGridCard extends StatefulWidget {
  final WhiteboardCanvasItem board;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const BoardGridCard({
    super.key,
    required this.board,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<BoardGridCard> createState() => _BoardGridCardState();
}

class _BoardGridCardState extends State<BoardGridCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final palette = AppColors.getPaletteById(widget.board.paletteId);
    final bandColor = palette.resolveCardColor(tokens.isDark);
    final displayTitle =
        (widget.board.iconEmoji != null && widget.board.iconEmoji!.isNotEmpty)
            ? '${widget.board.iconEmoji} ${widget.board.title}'
            : (widget.board.title.trim().isEmpty
                ? 'Untitled Board'
                : widget.board.title);

    return AnimatedScale(
      scale: _isPressed ? 0.985 : 1.0,
      duration: AppSpacing.durationFast,
      curve: AppSpacing.curveStandard,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surfacePrimary,
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(
            color: _isPressed ? tokens.borderStrong : tokens.borderSubtle,
            width: 1,
          ),
          boxShadow: AppSpacing.elev1(tokens.isDark),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTapDown: (_) {
              HapticFeedback.selectionClick();
              setState(() => _isPressed = true);
            },
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: () {
              setState(() => _isPressed = false);
              HapticFeedback.lightImpact();
              widget.onTap();
            },
            onLongPress: widget.onLongPress != null
                ? () {
                    setState(() => _isPressed = false);
                    HapticFeedback.mediumImpact();
                    widget.onLongPress!();
                  }
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top 120dp live mini-canvas thumbnail
                SizedBox(
                  height: 120,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tokens.canvasSunken,
                      border: Border(
                        bottom: BorderSide(
                          color: tokens.borderSubtle,
                          width: 1,
                        ),
                      ),
                    ),
                    child: CustomPaint(
                      painter: _BoardMiniThumbnailPainter(
                        nodes: widget.board.nodes,
                        edges: widget.board.edges,
                        tokens: tokens,
                        accentBandColor: bandColor,
                      ),
                    ),
                  ),
                ),

                // Bottom info bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s3,
                    AppSpacing.s3,
                    AppSpacing.s3,
                    AppSpacing.s3,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: bandColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s2),
                          Expanded(
                            child: Text(
                              displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleSm(
                                color: tokens.textPrimary,
                              ),
                            ),
                          ),
                          if (widget.board.isFavorite) ...[
                            const SizedBox(width: AppSpacing.s2),
                            TackPinBadge(color: tokens.accentPin),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.board.nodes.length} node${widget.board.nodes.length == 1 ? '' : 's'} · ${DateFormatter.formatTimestamp(widget.board.updatedAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption(
                          color: tokens.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BoardMiniThumbnailPainter extends CustomPainter {
  final List<CanvasNode> nodes;
  final List<CanvasEdge> edges;
  final TackTokens tokens;
  final Color accentBandColor;

  _BoardMiniThumbnailPainter({
    required this.nodes,
    required this.edges,
    required this.tokens,
    required this.accentBandColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Subtle dot grid background
    final dotPaint = Paint()
      ..color = tokens.borderSubtle.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    const step = 14.0;
    for (double x = 10; x < size.width; x += step) {
      for (double y = 10; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.9, dotPaint);
      }
    }

    if (nodes.isEmpty) return;

    // 2. Compute bounding box of all nodes
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    for (final n in nodes) {
      minX = math.min(minX, n.x);
      minY = math.min(minY, n.y);
      maxX = math.max(maxX, n.x + n.width);
      maxY = math.max(maxY, n.y + n.height);
    }

    final contentW = math.max(maxX - minX, 200.0);
    final contentH = math.max(maxY - minY, 120.0);
    const pad = 14.0;
    final availW = math.max(size.width - pad * 2, 20.0);
    final availH = math.max(size.height - pad * 2, 20.0);
    final scale = math.min(availW / contentW, availH / contentH).clamp(0.06, 0.42);

    final scaledW = contentW * scale;
    final scaledH = contentH * scale;
    final offsetX = (size.width - scaledW) / 2 - minX * scale;
    final offsetY = (size.height - scaledH) / 2 - minY * scale;

    Offset toThumb(Offset world) =>
        Offset(world.dx * scale + offsetX, world.dy * scale + offsetY);

    final nodeMap = <String, CanvasNode>{for (final n in nodes) n.id: n};

    // 3. Draw connector edges
    final edgePaint = Paint()
      ..color = tokens.borderStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round;

    for (final edge in edges) {
      final from = nodeMap[edge.fromNodeId];
      final to = nodeMap[edge.toNodeId];
      if (from == null || to == null) continue;
      final p1 = toThumb(from.center);
      final p2 = toThumb(to.center);
      final midY = (p1.dy + p2.dy) / 2;
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..cubicTo(p1.dx, midY, p2.dx, midY, p2.dx, p2.dy);
      canvas.drawPath(path, edgePaint);
    }

    // 4. Draw node shapes in their object palettes
    final strokePaint = Paint()
      ..color = tokens.borderStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final node in nodes) {
      final topLeft = toThumb(Offset(node.x, node.y));
      final w = math.max(node.width * scale, 14.0);
      final h = math.max(node.height * scale, 8.0);
      final rect = Rect.fromLTWH(topLeft.dx, topLeft.dy, w, h);

      final nodePalette = AppColors.getPaletteById(node.paletteId);
      final fillPaint = Paint()
        ..color = nodePalette.resolveCardColor(tokens.isDark)
        ..style = PaintingStyle.fill;

      switch (node.shapeType) {
        case CanvasNodeType.startEnd:
          final rrect = RRect.fromRectAndRadius(rect, Radius.circular(h / 2));
          canvas.drawRRect(rrect, fillPaint);
          canvas.drawRRect(rrect, strokePaint);
          break;
        case CanvasNodeType.decision:
          final path = Path()
            ..moveTo(rect.center.dx, rect.top)
            ..lineTo(rect.right, rect.center.dy)
            ..lineTo(rect.center.dx, rect.bottom)
            ..lineTo(rect.left, rect.center.dy)
            ..close();
          canvas.drawPath(path, fillPaint);
          canvas.drawPath(path, strokePaint);
          break;
        case CanvasNodeType.connector:
          final r = math.min(w, h) / 2;
          canvas.drawCircle(rect.center, r, fillPaint);
          canvas.drawCircle(rect.center, r, strokePaint);
          break;
        default:
          final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
          canvas.drawRRect(rrect, fillPaint);
          canvas.drawRRect(rrect, strokePaint);
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardMiniThumbnailPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.edges != edges ||
        oldDelegate.tokens != tokens;
  }
}

