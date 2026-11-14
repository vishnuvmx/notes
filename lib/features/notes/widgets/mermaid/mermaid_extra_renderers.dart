import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'mermaid_diagram_parser.dart';

// -------------------------------------------------------------
// Shared Branch / Schema Accent Palette
// -------------------------------------------------------------

const List<String> _branchPaletteIds = [
  'cyan',
  'peach',
  'lavender',
  'lime',
  'amber',
  'rose',
  'coral',
];

Color _branchAccentColor(int index, bool isDark) {
  final id = _branchPaletteIds[index % _branchPaletteIds.length];
  return AppColors.getPaletteById(id).resolveAccentColor(isDark);
}

// -------------------------------------------------------------
// 5. ER DIAGRAM RENDERER
// -------------------------------------------------------------

class MermaidErWidget extends StatelessWidget {
  final ParsedMermaidDiagram diagram;
  final bool isDark;
  final TransformationController transformController;

  const MermaidErWidget({
    super.key,
    required this.diagram,
    required this.isDark,
    required this.transformController,
  });

  @override
  Widget build(BuildContext context) {
    final entities = diagram.erEntities;
    if (entities.isEmpty) return const SizedBox.shrink();

    final layout = _computeErLayout(diagram);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final totalW = layout.totalSize.width;
        final totalH = layout.totalSize.height;

        final fitScale = (availableWidth / totalW).clamp(0.0, 1.0);
        final displayW = totalW * fitScale;
        final displayH = totalH * fitScale;

        final canvasContent = SizedBox(
          width: totalW,
          height: totalH,
          child: CustomPaint(
            painter: _ErRelationPainter(
              diagram: diagram,
              positions: layout.positions,
              cardSizes: layout.sizes,
              isDark: isDark,
            ),
            child: Stack(
              children: [
                for (final entity in entities)
                  if (layout.positions.containsKey(entity.name))
                    Positioned(
                      left: layout.positions[entity.name]!.dx,
                      top: layout.positions[entity.name]!.dy,
                      width: layout.sizes[entity.name]!.width,
                      height: layout.sizes[entity.name]!.height,
                      child: _buildEntityCard(entity, isDark),
                    ),
              ],
            ),
          ),
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (diagram.title != null && diagram.title!.isNotEmpty) ...[
              Text(
                diagram.title!,
                style: AppTypography.titleSm(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
            ],
            InteractiveViewer(
              transformationController: transformController,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 1.0,
              maxScale: 3.0,
              child: Center(
                child: SizedBox(
                  width: displayW,
                  height: displayH,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: canvasContent,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEntityCard(MermaidErEntity entity, bool isDark) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final headBg = isDark ? AppColors.darkSunken : AppColors.lightSunken;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final mutedText = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final entityDot = isDark ? AppColors.darkStateInfo : AppColors.lightStateInfo;

    return Container(
      decoration: ShapeDecoration(
        color: bg,
        shape: SmoothRectangleBorder(
          borderRadius: AppSpacing.roundedSm,
          smoothness: AppSpacing.defaultSmoothing,
          side: BorderSide(color: border, width: 1.2),
        ),
        shadows: AppSpacing.elev1(isDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: headBg,
              border: Border(bottom: BorderSide(color: border, width: 1.0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: entityDot,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    entity.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (entity.attributes.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'entity',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: mutedText,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final attr in entity.attributes)
                      SizedBox(
                        height: 19,
                        child: Row(
                          children: [
                            if (attr.keyType != null) ...[
                              _buildKeyBadge(attr.keyType!, isDark),
                              const SizedBox(width: 5),
                            ],
                            Expanded(
                              child: Text(
                                attr.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 10.5,
                                  fontWeight: attr.keyType != null ? FontWeight.w700 : FontWeight.w500,
                                  color: primaryText,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              attr.type,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9.5,
                                color: mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKeyBadge(String keyType, bool isDark) {
    final Color badgeColor;
    if (keyType.contains('PK')) {
      badgeColor = isDark ? AppColors.darkStateWarning : AppColors.lightStateWarning;
    } else if (keyType.contains('FK')) {
      badgeColor = isDark ? AppColors.darkStateInfo : AppColors.lightStateInfo;
    } else {
      badgeColor = AppColors.getPaletteById('lavender').resolveAccentColor(isDark);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: isDark ? 0.24 : 0.16),
        borderRadius: BorderRadius.circular(3.5),
      ),
      child: Text(
        keyType,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          color: badgeColor,
        ),
      ),
    );
  }
}

class _ErLayoutResult {
  final Map<String, Offset> positions;
  final Map<String, Size> sizes;
  final Size totalSize;

  const _ErLayoutResult({
    required this.positions,
    required this.sizes,
    required this.totalSize,
  });
}

_ErLayoutResult _computeErLayout(ParsedMermaidDiagram diagram) {
  final entities = diagram.erEntities;
  final relations = diagram.erRelations;

  final sizes = <String, Size>{};
  for (final e in entities) {
    int maxRowChars = e.displayName.length + 4;
    for (final a in e.attributes) {
      final len = a.name.length + a.type.length + (a.keyType != null ? a.keyType!.length + 3 : 0);
      if (len > maxRowChars) maxRowChars = len;
    }
    final w = math.max(152.0, math.min(240.0, maxRowChars * 6.5 + 36.0));
    final attrHeight = e.attributes.isEmpty ? 26.0 : (e.attributes.length * 19.0 + 10.0);
    final h = 29.0 + attrHeight;
    sizes[e.name] = Size(w, h);
  }

  // Group into balanced rows of max 2 cards so relationships and fields stay crisp.
  const hGap = 72.0;
  const vGap = 54.0;
  const cols = 2;

  // Put strongly referenced entities earlier via degree order while preserving declaration fallback.
  final outCount = <String, int>{for (final e in entities) e.name: 0};
  for (final r in relations) {
    outCount[r.fromEntity] = (outCount[r.fromEntity] ?? 0) + 1;
  }
  final ordered = [...entities]
    ..sort((a, b) => (outCount[b.name] ?? 0).compareTo(outCount[a.name] ?? 0));

  final rows = <List<MermaidErEntity>>[];
  for (int i = 0; i < ordered.length; i += cols) {
    rows.add(ordered.sublist(i, math.min(i + cols, ordered.length)));
  }

  double maxRowW = 0;
  final rowWidths = <double>[];
  for (final row in rows) {
    double w = 0;
    for (int c = 0; c < row.length; c++) {
      w += sizes[row[c].name]!.width;
      if (c > 0) w += hGap;
    }
    rowWidths.add(w);
    if (w > maxRowW) maxRowW = w;
  }

  final positions = <String, Offset>{};
  double y = 18.0;
  double maxW = 0;

  for (int r = 0; r < rows.length; r++) {
    final row = rows[r];
    double x = (maxRowW - rowWidths[r]) / 2 + 18.0;
    double rowMaxH = 0;

    for (final entity in row) {
      final sz = sizes[entity.name]!;
      positions[entity.name] = Offset(x, y);
      x += sz.width + hGap;
      if (sz.height > rowMaxH) rowMaxH = sz.height;
      if (x - hGap > maxW) maxW = x - hGap;
    }
    y += rowMaxH + vGap;
  }

  final totalH = rows.isEmpty ? 120.0 : y - vGap + 24.0;
  return _ErLayoutResult(
    positions: positions,
    sizes: sizes,
    totalSize: Size(math.max(maxW + 18.0, 260.0), totalH),
  );
}

class _ErRelationPainter extends CustomPainter {
  final ParsedMermaidDiagram diagram;
  final Map<String, Offset> positions;
  final Map<String, Size> cardSizes;
  final bool isDark;

  _ErRelationPainter({
    required this.diagram,
    required this.positions,
    required this.cardSizes,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final lineColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pairOffsetTracker = <String, int>{};

    for (final rel in diagram.erRelations) {
      final fromPos = positions[rel.fromEntity];
      final toPos = positions[rel.toEntity];
      final fromSz = cardSizes[rel.fromEntity];
      final toSz = cardSizes[rel.toEntity];
      if (fromPos == null || toPos == null || fromSz == null || toSz == null) continue;

      final fromRect = fromPos & fromSz;
      final toRect = toPos & toSz;

      final pairKey = [rel.fromEntity, rel.toEntity]..sort();
      final keyStr = pairKey.join('::');
      final multiIdx = pairOffsetTracker[keyStr] ?? 0;
      pairOffsetTracker[keyStr] = multiIdx + 1;
      final shift = (multiIdx - 0) * 10.0;

      // Self-referential loop
      if (rel.fromEntity == rel.toEntity) {
        final start = Offset(fromRect.right, fromRect.center.dy - 10);
        final end = Offset(fromRect.right, fromRect.center.dy + 10);
        final loopPath = Path()
          ..moveTo(start.dx, start.dy)
          ..cubicTo(
            start.dx + 36, start.dy - 14,
            end.dx + 36, end.dy + 14,
            end.dx, end.dy,
          );
        _drawStyledPath(canvas, loopPath, linePaint, rel.isNonIdentifying);
        _drawCrowFoot(canvas, start, const Offset(1, 0), rel.leftCardinality, linePaint, isDark);
        _drawCrowFoot(canvas, end, const Offset(1, 0), rel.rightCardinality, linePaint, isDark);
        if (rel.label.isNotEmpty) {
          _drawLabelPill(canvas, Offset(start.dx + 28, fromRect.center.dy), rel.label);
        }
        continue;
      }

      final dx = toRect.center.dx - fromRect.center.dx;
      final dy = toRect.center.dy - fromRect.center.dy;

      Offset start;
      Offset end;
      Offset startOutDir;
      Offset endOutDir;

      if (dx.abs() >= dy.abs()) {
        // Horizontal connection
        if (dx >= 0) {
          start = Offset(fromRect.right, fromRect.center.dy + shift);
          end = Offset(toRect.left, toRect.center.dy + shift);
          startOutDir = const Offset(1, 0);
          endOutDir = const Offset(-1, 0);
        } else {
          start = Offset(fromRect.left, fromRect.center.dy + shift);
          end = Offset(toRect.right, toRect.center.dy + shift);
          startOutDir = const Offset(-1, 0);
          endOutDir = const Offset(1, 0);
        }
      } else {
        // Vertical connection
        if (dy >= 0) {
          start = Offset(fromRect.center.dx + shift, fromRect.bottom);
          end = Offset(toRect.center.dx + shift, toRect.top);
          startOutDir = const Offset(0, 1);
          endOutDir = const Offset(0, -1);
        } else {
          start = Offset(fromRect.center.dx + shift, fromRect.top);
          end = Offset(toRect.center.dx + shift, toRect.bottom);
          startOutDir = const Offset(0, -1);
          endOutDir = const Offset(0, 1);
        }
      }

      final path = Path()..moveTo(start.dx, start.dy);
      if (startOutDir.dx != 0) {
        final ctrl = math.max(24.0, (end.dx - start.dx).abs() * 0.45);
        path.cubicTo(
          start.dx + startOutDir.dx * ctrl, start.dy,
          end.dx + endOutDir.dx * ctrl, end.dy,
          end.dx, end.dy,
        );
      } else {
        final ctrl = math.max(24.0, (end.dy - start.dy).abs() * 0.45);
        path.cubicTo(
          start.dx, start.dy + startOutDir.dy * ctrl,
          end.dx, end.dy + endOutDir.dy * ctrl,
          end.dx, end.dy,
        );
      }

      _drawStyledPath(canvas, path, linePaint, rel.isNonIdentifying);
      _drawCrowFoot(canvas, start, startOutDir, rel.leftCardinality, linePaint, isDark);
      _drawCrowFoot(canvas, end, endOutDir, rel.rightCardinality, linePaint, isDark);

      if (rel.label.isNotEmpty) {
        final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
        _drawLabelPill(canvas, mid, rel.label);
      }
    }
  }

  void _drawStyledPath(Canvas canvas, Path path, Paint paint, bool dashed) {
    if (!dashed) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      double dist = 0.0;
      while (dist < metric.length) {
        final next = math.min(dist + 5.0, metric.length);
        canvas.drawPath(metric.extractPath(dist, next), paint);
        dist += 9.0;
      }
    }
  }

  void _drawCrowFoot(
    Canvas canvas,
    Offset anchor,
    Offset outDir,
    String cardinality,
    Paint paint,
    bool isDark,
  ) {
    // outDir points AWAY from the entity card along the edge.
    final perp = Offset(-outDir.dy, outDir.dx);
    final hasMany = cardinality.contains('{') || cardinality.contains('}') || cardinality.contains('+');
    final hasZero = cardinality.contains('o') || cardinality.contains('0');
    final hasOne = cardinality.contains('|') || cardinality.contains('1');

    if (hasMany) {
      final tipAnchor = anchor;
      final stem = anchor + outDir * 10.0;
      canvas.drawLine(stem, tipAnchor + perp * 6.0, paint);
      canvas.drawLine(stem, tipAnchor - perp * 6.0, paint);
    } else if (hasOne) {
      final barPos = anchor + outDir * 6.0;
      canvas.drawLine(barPos - perp * 5.5, barPos + perp * 5.5, paint);
    }

    if (cardinality == '||' || cardinality == '|{' || cardinality == '}|') {
      final barPos2 = anchor + outDir * 11.0;
      canvas.drawLine(barPos2 - perp * 5.0, barPos2 + perp * 5.0, paint);
    }

    if (hasZero) {
      final circleCenter = anchor + outDir * (hasMany ? 14.0 : 12.0);
      canvas.drawCircle(
        circleCenter,
        3.5,
        Paint()
          ..color = isDark ? AppColors.darkSurface : AppColors.lightSurface
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(circleCenter, 3.5, paint);
    }
  }

  void _drawLabelPill(Canvas canvas, Offset center, String label) {
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rect = Rect.fromCenter(
      center: center,
      width: tp.width + 10,
      height: tp.height + 4,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()
        ..color = isDark ? AppColors.darkSunken : AppColors.lightSurface
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()
        ..color = isDark ? AppColors.darkBorder : AppColors.lightBorder
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _ErRelationPainter oldDelegate) => true;
}

// -------------------------------------------------------------
// 6. GANTT CHART RENDERER
// -------------------------------------------------------------

class MermaidGanttWidget extends StatelessWidget {
  final ParsedMermaidDiagram diagram;
  final bool isDark;
  final TackColorPalette palette;

  const MermaidGanttWidget({
    super.key,
    required this.diagram,
    required this.isDark,
    required this.palette,
  });

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final tasks = diagram.ganttTasks;
    if (tasks.isEmpty) return const SizedBox.shrink();

    DateTime minStart = tasks.first.startDate;
    DateTime maxEnd = tasks.first.endDate;
    for (final t in tasks) {
      if (t.startDate.isBefore(minStart)) minStart = t.startDate;
      if (t.endDate.isAfter(maxEnd)) maxEnd = t.endDate;
    }
    final totalDays = math.max(1, maxEnd.difference(minStart).inDays);

    // Group rows with section headers so label column and timeline track stay height-locked.
    final rows = <_GanttRow>[];
    String? lastSection;
    for (final t in tasks) {
      if (t.section.isNotEmpty && t.section != lastSection) {
        rows.add(_GanttRow.section(t.section));
        lastSection = t.section;
      }
      rows.add(_GanttRow.task(t));
    }

    const double labelColWidth = 116.0;
    const double headerHeight = 28.0;
    const double sectionRowHeight = 24.0;
    const double taskRowHeight = 32.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availablePlotW = math.max(180.0, constraints.maxWidth - labelColWidth - 2);
        final double dayPx = math.max(14.0, math.min(34.0, availablePlotW / totalDays));
        final double chartW = math.max(availablePlotW, totalDays * dayPx);
        final int tickStep = totalDays <= 10
            ? 1
            : (totalDays <= 24 ? 3 : (totalDays <= 60 ? 7 : 14));

        final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
        final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
        final accent = palette.resolveAccentColor(isDark);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (diagram.title != null && diagram.title!.isNotEmpty) ...[
              Text(
                diagram.title!,
                style: AppTypography.titleSm(color: textPrimary),
              ),
              const SizedBox(height: AppSpacing.s2),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fixed Left Task Label Column
                SizedBox(
                  width: labelColWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: headerHeight,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                        ),
                        child: Text(
                          'Task',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: textMuted,
                          ),
                        ),
                      ),
                      for (final r in rows)
                        if (r.isSection)
                          Container(
                            height: sectionRowHeight,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(right: 8),
                            color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
                            child: Text(
                              r.sectionTitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: accent,
                              ),
                            ),
                          )
                        else
                          Container(
                            height: taskRowHeight,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: borderColor.withValues(alpha: 0.45),
                                  width: 0.6,
                                ),
                              ),
                            ),
                            child: Text(
                              r.task!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ),
                    ],
                  ),
                ),

                Container(width: 1, height: headerHeight + _rowsHeight(rows, sectionRowHeight, taskRowHeight), color: borderColor),

                // Horizontal Scrollable Timeline Plot
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: SizedBox(
                      width: chartW,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Date Axis Header
                          SizedBox(
                            height: headerHeight,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                                    ),
                                  ),
                                ),
                                for (int d = 0; d <= totalDays; d += tickStep)
                                  Positioned(
                                    left: math.min(d * dayPx, chartW - 44),
                                    top: 6,
                                    child: Text(
                                      _formatShortDate(minStart.add(Duration(days: d))),
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: textMuted,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Section & Task Bars
                          for (final r in rows)
                            if (r.isSection)
                              Container(
                                height: sectionRowHeight,
                                color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
                              )
                            else
                              _buildTaskTrackRow(
                                r.task!,
                                minStart: minStart,
                                dayPx: dayPx,
                                chartW: chartW,
                                rowHeight: taskRowHeight,
                                totalDays: totalDays,
                                tickStep: tickStep,
                                borderColor: borderColor,
                                accent: accent,
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  double _rowsHeight(List<_GanttRow> rows, double sectionH, double taskH) {
    double sum = 0;
    for (final r in rows) {
      sum += r.isSection ? sectionH : taskH;
    }
    return sum;
  }

  String _formatShortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  Widget _buildTaskTrackRow(
    MermaidGanttTask task, {
    required DateTime minStart,
    required double dayPx,
    required double chartW,
    required double rowHeight,
    required int totalDays,
    required int tickStep,
    required Color borderColor,
    required Color accent,
  }) {
    final startOffsetDays = math.max(0, task.startDate.difference(minStart).inDays);
    final durationDays = math.max(1, task.endDate.difference(task.startDate).inDays);
    final left = startOffsetDays * dayPx;

    Color barColor;
    if (task.isCrit) {
      barColor = isDark ? AppColors.darkStateDanger : AppColors.lightStateDanger;
    } else if (task.isDone) {
      barColor = isDark ? AppColors.darkStateSuccess : AppColors.lightStateSuccess;
    } else if (task.isActive) {
      barColor = isDark ? AppColors.darkStateInfo : AppColors.lightStateInfo;
    } else {
      barColor = accent;
    }

    return SizedBox(
      height: rowHeight,
      width: chartW,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: borderColor.withValues(alpha: 0.45),
                    width: 0.6,
                  ),
                ),
              ),
            ),
          ),
          for (int d = 0; d <= totalDays; d += tickStep)
            Positioned(
              left: d * dayPx,
              top: 0,
              bottom: 0,
              child: Container(
                width: 0.6,
                color: borderColor.withValues(alpha: 0.35),
              ),
            ),
          if (task.isMilestone)
            Positioned(
              left: math.max(2.0, left - 6.0),
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkStateWarning : AppColors.lightStateWarning,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            )
          else
            Positioned(
              left: left + 1,
              width: math.max(14.0, durationDays * dayPx - 2),
              height: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: task.isDone ? 0.55 : 0.88),
                  borderRadius: BorderRadius.circular(5),
                ),
                alignment: Alignment.centerLeft,
                child: durationDays * dayPx >= 32
                    ? Text(
                        '${durationDays}d',
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _GanttRow {
  final String? sectionTitle;
  final MermaidGanttTask? task;

  const _GanttRow.section(this.sectionTitle) : task = null;
  const _GanttRow.task(this.task) : sectionTitle = null;

  bool get isSection => sectionTitle != null;
}

// -------------------------------------------------------------
// 7. MINDMAP TREE RENDERER
// -------------------------------------------------------------

class MermaidMindmapWidget extends StatelessWidget {
  final ParsedMermaidDiagram diagram;
  final bool isDark;
  final TransformationController transformController;

  const MermaidMindmapWidget({
    super.key,
    required this.diagram,
    required this.isDark,
    required this.transformController,
  });

  @override
  Widget build(BuildContext context) {
    final root = diagram.mindmapRoot;
    if (root == null) return const SizedBox.shrink();

    final layout = _computeMindmapLayout(root, isDark);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final totalW = layout.totalSize.width;
        final totalH = layout.totalSize.height;

        final fitScale = (availableWidth / totalW).clamp(0.0, 1.0);
        final displayW = totalW * fitScale;
        final displayH = totalH * fitScale;

        final canvasContent = SizedBox(
          width: totalW,
          height: totalH,
          child: CustomPaint(
            painter: _MindmapBranchPainter(
              edges: layout.edges,
              isDark: isDark,
            ),
            child: Stack(
              children: [
                for (final placed in layout.nodes)
                  Positioned(
                    left: placed.rect.left,
                    top: placed.rect.top,
                    width: placed.rect.width,
                    height: placed.rect.height,
                    child: _buildMindmapNodeChip(placed, isDark),
                  ),
              ],
            ),
          ),
        );

        return InteractiveViewer(
          transformationController: transformController,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 1.0,
          maxScale: 3.0,
          child: Center(
            child: SizedBox(
              width: displayW,
              height: displayH,
              child: FittedBox(
                fit: BoxFit.contain,
                child: canvasContent,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMindmapNodeChip(_PlacedMindmapNode placed, bool isDark) {
    final isRoot = placed.node.depth == 0;
    final color = placed.branchColor;
    final bg = isRoot
        ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
        : color.withValues(alpha: isDark ? 0.18 : 0.12);
    final fg = isRoot
        ? (isDark ? AppColors.darkSurface : AppColors.lightSurface)
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
    final border = isRoot ? color : color.withValues(alpha: isDark ? 0.55 : 0.45);

    final BorderRadius br;
    if (isRoot || placed.node.shape == MermaidNodeShape.circle || placed.node.shape == MermaidNodeShape.pill) {
      br = AppSpacing.roundedPill;
    } else if (placed.node.shape == MermaidNodeShape.process) {
      br = AppSpacing.roundedSm;
    } else {
      br = BorderRadius.circular(12);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: ShapeDecoration(
        color: bg,
        shape: SmoothRectangleBorder(
          borderRadius: br,
          smoothness: AppSpacing.defaultSmoothing,
          side: BorderSide(color: border, width: isRoot ? 2.0 : 1.2),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        placed.node.label,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: isRoot ? 12.5 : (placed.node.depth == 1 ? 11.5 : 10.5),
          fontWeight: isRoot || placed.node.depth == 1 ? FontWeight.w700 : FontWeight.w600,
          letterSpacing: -0.2,
          color: fg,
        ),
      ),
    );
  }
}

class _PlacedMindmapNode {
  final MermaidMindmapNode node;
  final Rect rect;
  final Color branchColor;

  const _PlacedMindmapNode({
    required this.node,
    required this.rect,
    required this.branchColor,
  });
}

class _MindmapEdge {
  final Offset start;
  final Offset end;
  final Color color;
  final bool goesRight;
  final int depth;

  const _MindmapEdge({
    required this.start,
    required this.end,
    required this.color,
    required this.goesRight,
    required this.depth,
  });
}

class _MindmapLayoutResult {
  final List<_PlacedMindmapNode> nodes;
  final List<_MindmapEdge> edges;
  final Size totalSize;

  const _MindmapLayoutResult({
    required this.nodes,
    required this.edges,
    required this.totalSize,
  });
}

Size _measureMindmapNode(MermaidMindmapNode node) {
  final isRoot = node.depth == 0;
  final w = math.max(
    isRoot ? 96.0 : 78.0,
    math.min(168.0, node.label.length * (isRoot ? 7.4 : 6.6) + 26.0),
  );
  final h = isRoot ? 38.0 : 30.0;
  return Size(w, h);
}

double _subtreeHeight(MermaidMindmapNode node, double rowSlotH) {
  if (node.children.isEmpty) return rowSlotH;
  double total = 0;
  for (final c in node.children) {
    total += _subtreeHeight(c, rowSlotH);
  }
  return math.max(rowSlotH, total);
}

_MindmapLayoutResult _computeMindmapLayout(MermaidMindmapNode root, bool isDark) {
  const double rowSlotH = 38.0;
  const double hGap = 36.0;

  // Balance top-level branches across right and left when there are >= 2 children.
  final rightChildren = <MermaidMindmapNode>[];
  final leftChildren = <MermaidMindmapNode>[];
  for (int i = 0; i < root.children.length; i++) {
    if (root.children.length == 1 || i < (root.children.length / 2).ceil()) {
      rightChildren.add(root.children[i]);
    } else {
      leftChildren.add(root.children[i]);
    }
  }

  double sideHeight(List<MermaidMindmapNode> list) {
    if (list.isEmpty) return rowSlotH;
    return list.fold<double>(0.0, (s, n) => s + _subtreeHeight(n, rowSlotH));
  }

  final rightH = sideHeight(rightChildren);
  final leftH = leftChildren.isEmpty ? 0.0 : sideHeight(leftChildren);
  final totalH = math.max(rightH, leftH) + 32.0;

  final rootSize = _measureMindmapNode(root);
  final placed = <_PlacedMindmapNode>[];
  final edges = <_MindmapEdge>[];

  // Place tentatively around x = 0 for root, then normalize minLeft -> 16.0.
  final rootRect = Rect.fromCenter(
    center: Offset(0, totalH / 2),
    width: rootSize.width,
    height: rootSize.height,
  );
  placed.add(_PlacedMindmapNode(
    node: root,
    rect: rootRect,
    branchColor: _branchAccentColor(2, isDark),
  ));

  void placeSide({
    required List<MermaidMindmapNode> branches,
    required bool goesRight,
    required int colorOffset,
  }) {
    final spanH = sideHeight(branches);
    double cursorY = (totalH - spanH) / 2;

    void placeRecursive(
      MermaidMindmapNode node,
      Rect parentRect,
      double startY,
      Color color,
    ) {
      final boxH = _subtreeHeight(node, rowSlotH);
      final sz = _measureMindmapNode(node);
      final centerY = startY + boxH / 2;
      final leftX = goesRight
          ? parentRect.right + hGap
          : parentRect.left - hGap - sz.width;
      final rect = Rect.fromLTWH(leftX, centerY - sz.height / 2, sz.width, sz.height);

      placed.add(_PlacedMindmapNode(node: node, rect: rect, branchColor: color));

      final parentPort = Offset(
        goesRight ? parentRect.right : parentRect.left,
        parentRect.center.dy,
      );
      final childPort = Offset(
        goesRight ? rect.left : rect.right,
        rect.center.dy,
      );
      edges.add(_MindmapEdge(
        start: parentPort,
        end: childPort,
        color: color,
        goesRight: goesRight,
        depth: node.depth,
      ));

      double childY = startY;
      for (final c in node.children) {
        final ch = _subtreeHeight(c, rowSlotH);
        placeRecursive(c, rect, childY, color);
        childY += ch;
      }
    }

    for (int i = 0; i < branches.length; i++) {
      final branch = branches[i];
      final color = _branchAccentColor(colorOffset + i, isDark);
      final h = _subtreeHeight(branch, rowSlotH);
      placeRecursive(branch, rootRect, cursorY, color);
      cursorY += h;
    }
  }

  if (rightChildren.isNotEmpty) {
    placeSide(branches: rightChildren, goesRight: true, colorOffset: 0);
  }
  if (leftChildren.isNotEmpty) {
    placeSide(
      branches: leftChildren,
      goesRight: false,
      colorOffset: rightChildren.length,
    );
  }

  double minX = double.infinity;
  double maxX = double.negativeInfinity;
  double minY = double.infinity;
  double maxY = double.negativeInfinity;
  for (final p in placed) {
    if (p.rect.left < minX) minX = p.rect.left;
    if (p.rect.right > maxX) maxX = p.rect.right;
    if (p.rect.top < minY) minY = p.rect.top;
    if (p.rect.bottom > maxY) maxY = p.rect.bottom;
  }

  const pad = 16.0;
  final dx = pad - minX;
  final dy = pad - minY;

  final normalizedNodes = [
    for (final p in placed)
      _PlacedMindmapNode(
        node: p.node,
        rect: p.rect.shift(Offset(dx, dy)),
        branchColor: p.branchColor,
      ),
  ];
  final normalizedEdges = [
    for (final e in edges)
      _MindmapEdge(
        start: e.start.translate(dx, dy),
        end: e.end.translate(dx, dy),
        color: e.color,
        goesRight: e.goesRight,
        depth: e.depth,
      ),
  ];

  return _MindmapLayoutResult(
    nodes: normalizedNodes,
    edges: normalizedEdges,
    totalSize: Size((maxX - minX) + pad * 2, (maxY - minY) + pad * 2),
  );
}

class _MindmapBranchPainter extends CustomPainter {
  final List<_MindmapEdge> edges;
  final bool isDark;

  _MindmapBranchPainter({
    required this.edges,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in edges) {
      final paint = Paint()
        ..color = e.color.withValues(alpha: isDark ? 0.72 : 0.8)
        ..strokeWidth = e.depth <= 1 ? 2.2 : 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final ctrlOffset = (e.end.dx - e.start.dx).abs() * 0.5;
      final dir = e.goesRight ? 1.0 : -1.0;

      final path = Path()
        ..moveTo(e.start.dx, e.start.dy)
        ..cubicTo(
          e.start.dx + dir * ctrlOffset,
          e.start.dy,
          e.end.dx - dir * ctrlOffset,
          e.end.dy,
          e.end.dx,
          e.end.dy,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MindmapBranchPainter oldDelegate) => true;
}
