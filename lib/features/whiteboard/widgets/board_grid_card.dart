import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/whiteboard_item.dart';

/// Uniform Soft Monochrome Board Grid Card.
///
/// Matches `NeoNoteCard` geometry (`AppSpacing.cardAspectRatio`) and top header
/// hierarchy (Title + `...` + Date subtitle), with an inset node-and-edge graph
/// preview occupying the lower preview region.
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
      child: AspectRatio(
        aspectRatio: AppSpacing.cardAspectRatio,
        child: Container(
          decoration: ShapeDecoration(
            color: tokens.surfacePrimary,
            shadows: AppSpacing.elev1(tokens.isDark),
            shape: SmoothRectangleBorder(
              borderRadius: AppSpacing.roundedMd,
              smoothness: AppSpacing.defaultSmoothing,
              side: BorderSide(
                color: _isPressed
                    ? tokens.borderStrong
                    : tokens.borderSubtle.withValues(alpha: 0.7),
                width: 1,
              ),
            ),
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
                padding: const EdgeInsets.all(AppSpacing.s5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Top Header Row: Title + optional Pin + More (...)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleSm(
                              color: tokens.textPrimary,
                              fontSize: 15.5,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (widget.board.isFavorite) ...[
                          const SizedBox(width: AppSpacing.s2),
                          TackPinBadge(color: tokens.accentPin, size: 10),
                        ],
                        if (widget.onLongPress != null) ...[
                          const SizedBox(width: AppSpacing.s1),
                          InkWell(
                            borderRadius: AppSpacing.roundedPill,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onLongPress!();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.s1),
                              child: TackIcon(
                                TackIcons.more,
                                size: 16,
                                color: tokens.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: AppSpacing.s1),

                    // 2. Calm Date & Node Count Subtitle
                    Text(
                      '${DateFormatter.formatCardDate(widget.board.updatedAt)} · ${widget.board.nodes.length} ${widget.board.nodes.length == 1 ? 'node' : 'nodes'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption(
                        color: tokens.textTertiary,
                        weight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.s3),

                    // 3. Lower Node Graph Preview Thumbnail
                    Expanded(
                      child: ClipRRect(
                        borderRadius: AppSpacing.roundedSm,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: tokens.canvasSunken,
                            borderRadius: AppSpacing.roundedSm,
                            border: Border.all(
                              color: tokens.borderSubtle.withValues(alpha: 0.7),
                              width: 0.8,
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
                    ),
                  ],
                ),
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
    // 1. Subtle grid-paper lines
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

    if (nodes.isEmpty) {
      _paintEmptySilhouette(canvas, size);
      return;
    }

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

  void _paintEmptySilhouette(Canvas canvas, Size size) {
    final outlinePaint = Paint()
      ..color = tokens.borderStrong.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final fillPaint = Paint()
      ..color = accentBandColor.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    final leftBox = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.30, size.height * 0.44),
        width: math.min(28, size.width * 0.22),
        height: 14,
      ),
      const Radius.circular(4),
    );
    final rightBox = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.70, size.height * 0.58),
        width: math.min(28, size.width * 0.22),
        height: 14,
      ),
      const Radius.circular(4),
    );
    canvas.drawLine(
      Offset(leftBox.right, leftBox.center.dy),
      Offset(rightBox.left, rightBox.center.dy),
      outlinePaint,
    );
    canvas.drawRRect(leftBox, fillPaint);
    canvas.drawRRect(leftBox, outlinePaint);
    canvas.drawRRect(rightBox, fillPaint);
    canvas.drawRRect(rightBox, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _BoardMiniThumbnailPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.edges != edges ||
        oldDelegate.tokens != tokens;
  }
}
