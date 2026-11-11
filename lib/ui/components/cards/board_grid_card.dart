import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/whiteboard_item.dart';

/// Soft Monochrome Board Grid Card (`docs/design/11-reference-ui-style.md` §4).
///
/// Anatomy:
/// - Outer container: `surface/primary`, `r-md` (`18dp`), soft diffused shadow (`elev/1`)
/// - Top header row: `BOARD` tinted pill + relative date + `TackPinBadge` if pinned
/// - Inset rounded `112dp` mini-canvas thumbnail (`CustomPaint` on grid-paper `canvas/sunken`)
/// - Bottom row: board title (`title-sm`) + node count pill (`3n`)
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
      scale: _isPressed ? 0.98 : 1.0,
      duration: AppSpacing.durationFast,
      curve: AppSpacing.curveStandard,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surfacePrimary,
          borderRadius: AppSpacing.roundedMd,
          border: _isPressed
              ? Border.all(color: tokens.borderStrong, width: 1)
              : null,
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
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Inset Mini-Canvas Thumbnail
                  ClipRRect(
                    borderRadius: AppSpacing.roundedSm,
                    child: SizedBox(
                      height: 104,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: tokens.canvasSunken,
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
                  ),

                  const SizedBox(height: 10),

                  // 2. Title & Pin Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleSm(
                            color: tokens.textPrimary,
                            fontSize: 15.5,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (widget.board.isFavorite) ...[
                        const SizedBox(width: 6),
                        TackPinBadge(color: tokens.accentPin, size: 12),
                      ],
                    ],
                  ),

                  const SizedBox(height: 3),

                  // 3. Calm Metadata Subtitle
                  Text(
                    '${widget.board.nodes.length} ${widget.board.nodes.length == 1 ? 'node' : 'nodes'}  •  ${DateFormatter.formatTimestamp(widget.board.updatedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption(
                      color: tokens.textTertiary,
                    ),
                  ),
                ],
              ),
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
    // 1. Subtle grid-paper lines (matching Screenshot 1 right-side grid paper)
    final gridPaint = Paint()
      ..color = tokens.borderSubtle.withValues(alpha: 0.65)
      ..strokeWidth = 0.7;
    const step = 16.0;
    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
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
    const pad = 12.0;
    final availW = math.max(size.width - pad * 2, 20.0);
    final availH = math.max(size.height - pad * 2, 20.0);
    final scale =
        math.min(availW / contentW, availH / contentH).clamp(0.06, 0.42);

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
          final rrect =
              RRect.fromRectAndRadius(rect, const Radius.circular(3));
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
