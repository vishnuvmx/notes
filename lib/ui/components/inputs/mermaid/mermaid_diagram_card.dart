import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/whiteboard_item.dart';
import '../../../../state/workspace_provider.dart';
import '../../../screens/whiteboard/whiteboard_canvas_screen.dart';
import 'mermaid_diagram_parser.dart';

/// Card container that visualizes Mermaid graphs and diagrams (Flowcharts,
/// Pie Charts, Sequence Diagrams) with interactive pan/zoom, theme adaptation,
/// syntax code toggle, and direct "Open in Whiteboard" bridge.
class MermaidDiagramCard extends StatefulWidget {
  final String rawCode;
  final String? paletteId;

  const MermaidDiagramCard({
    super.key,
    required this.rawCode,
    this.paletteId,
  });

  @override
  State<MermaidDiagramCard> createState() => _MermaidDiagramCardState();
}

class _MermaidDiagramCardState extends State<MermaidDiagramCard> {
  late ParsedMermaidDiagram _parsed;
  bool _showCode = false;
  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    _parsed = MermaidDiagramParser.parse(widget.rawCode);
  }

  @override
  void didUpdateWidget(covariant MermaidDiagramCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rawCode != widget.rawCode) {
      _parsed = MermaidDiagramParser.parse(widget.rawCode);
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  TackColorPalette get _palette => AppColors.getPaletteById(widget.paletteId);

  void _copyRawCode() {
    Clipboard.setData(ClipboardData(text: widget.rawCode));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mermaid diagram code copied!'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openInWhiteboard() {
    if (_parsed.type != MermaidDiagramType.flowchart || _parsed.nodes.isEmpty) return;

    HapticFeedback.mediumImpact();

    // Map Mermaid nodes to Whiteboard Canvas nodes with coordinates
    final layout = _computeFlowchartLayout(_parsed, 120, 56, 40, 60);
    final whiteboardNodes = <CanvasNode>[];
    final whiteboardEdges = <CanvasEdge>[];

    final paletteNames = ['peach', 'cyan', 'lavender', 'lime', 'amber', 'bubble'];

    for (int i = 0; i < _parsed.nodes.length; i++) {
      final mNode = _parsed.nodes[i];
      final pos = layout.positions[mNode.id] ?? Offset(100.0 + (i % 3) * 160.0, 100.0 + (i ~/ 3) * 100.0);

      CanvasNodeType shape;
      switch (mNode.shape) {
        case MermaidNodeShape.decision:
          shape = CanvasNodeType.decision;
          break;
        case MermaidNodeShape.pill:
          shape = CanvasNodeType.startEnd;
          break;
        case MermaidNodeShape.circle:
          shape = CanvasNodeType.connector;
          break;
        case MermaidNodeShape.database:
        case MermaidNodeShape.rounded:
        case MermaidNodeShape.process:
          shape = CanvasNodeType.process;
          break;
      }

      whiteboardNodes.add(CanvasNode(
        id: mNode.id,
        text: mNode.label,
        shapeType: shape,
        x: pos.dx + 2500, // Center around Tack's canvas center
        y: pos.dy + 2500,
        width: 140,
        height: 64,
        paletteId: paletteNames[i % paletteNames.length],
      ));
    }

    // Map edges
    for (int i = 0; i < _parsed.edges.length; i++) {
      final edge = _parsed.edges[i];
      whiteboardEdges.add(CanvasEdge(
        id: 'edge_${edge.fromId}_${edge.toId}_$i',
        fromNodeId: edge.fromId,
        toNodeId: edge.toId,
        label: edge.label,
        fromPort: _parsed.direction == 'LR' ? 'right' : 'bottom',
        toPort: _parsed.direction == 'LR' ? 'left' : 'top',
      ));
    }

    final now = DateTime.now();
    final whiteboardItem = WhiteboardCanvasItem(
      id: 'wb_${now.millisecondsSinceEpoch}',
      title: _parsed.title ?? 'Diagram Whiteboard',
      createdAt: now,
      updatedAt: now,
      paletteId: widget.paletteId ?? 'cyan',
      nodes: whiteboardNodes,
      edges: whiteboardEdges,
      panOffset: const Offset(-2500.0, -2500.0),
    );

    // Save to workspace provider so it persists in Whiteboard list
    try {
      final provider = Provider.of<WorkspaceProvider>(context, listen: false);
      provider.saveItem(whiteboardItem);
    } catch (_) {}

    // Navigate to Whiteboard Canvas
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WhiteboardCanvasScreen(item: whiteboardItem),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String typeLabel = 'DIAGRAM';
    IconData typeIcon = LucideIcons.network;

    switch (_parsed.type) {
      case MermaidDiagramType.flowchart:
        typeLabel = 'FLOWCHART';
        typeIcon = LucideIcons.gitFork;
        break;
      case MermaidDiagramType.pie:
        typeLabel = 'PIE CHART';
        typeIcon = LucideIcons.chartPie;
        break;
      case MermaidDiagramType.sequence:
        typeLabel = 'SEQUENCE';
        typeIcon = LucideIcons.arrowRightLeft;
        break;
      case MermaidDiagramType.unsupported:
        typeLabel = 'CODE';
        typeIcon = LucideIcons.code;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16181D) : const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _palette.resolveTableBorder(isDark),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black12).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F222A) : const Color(0xFFEFF2F5),
              border: Border(
                bottom: BorderSide(
                  color: _palette.resolveTableBorder(isDark),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  typeIcon,
                  size: 14,
                  color: _palette.resolveAccentColor(isDark),
                ),
                const SizedBox(width: 6),
                Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: _palette.resolveAccentColor(isDark),
                  ),
                ),
                if (_parsed.title != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _parsed.title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),

                // "Open in Whiteboard" Button (Only for flowcharts)
                if (_parsed.type == MermaidDiagramType.flowchart && !_showCode) ...[
                  InkWell(
                    onTap: _openInWhiteboard,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: _palette.resolveAccentColor(isDark).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.penTool,
                            size: 11,
                            color: _palette.resolveAccentColor(isDark),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Whiteboard',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _palette.resolveAccentColor(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // View Toggle: Diagram / Code
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF282C37) : const Color(0xFFDEE2E6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildToggleButton(
                        label: 'Diagram',
                        isActive: !_showCode,
                        isDark: isDark,
                        onTap: () => setState(() => _showCode = false),
                      ),
                      _buildToggleButton(
                        label: 'Code',
                        isActive: _showCode,
                        isDark: isDark,
                        onTap: () => setState(() => _showCode = true),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // Copy Code Action
                InkWell(
                  onTap: _copyRawCode,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      LucideIcons.copy,
                      size: 13,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          if (_showCode || !_parsed.isValid)
            _buildRawCodeView(isDark)
          else
            _buildDiagramView(isDark),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? const Color(0xFF3B4050) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive
                ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          ),
        ),
      ),
    );
  }

  Widget _buildRawCodeView(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: SelectableText(
        widget.rawCode,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12.5,
          height: 1.45,
          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF2D3748),
        ),
      ),
    );
  }

  Widget _buildDiagramView(bool isDark) {
    switch (_parsed.type) {
      case MermaidDiagramType.pie:
        return MermaidPieWidget(
          diagram: _parsed,
          isDark: isDark,
        );
      case MermaidDiagramType.sequence:
        return MermaidSequenceWidget(
          diagram: _parsed,
          isDark: isDark,
        );
      case MermaidDiagramType.flowchart:
        return MermaidFlowchartWidget(
          diagram: _parsed,
          isDark: isDark,
          transformController: _transformController,
        );
      case MermaidDiagramType.unsupported:
        return _buildRawCodeView(isDark);
    }
  }
}

// -------------------------------------------------------------
// 1. FLOWCHART RENDERER & LAYOUT ENGINE
// -------------------------------------------------------------

class _FlowchartLayoutResult {
  final Map<String, Offset> positions;
  final Size totalSize;

  const _FlowchartLayoutResult({
    required this.positions,
    required this.totalSize,
  });
}

_FlowchartLayoutResult _computeFlowchartLayout(
  ParsedMermaidDiagram diagram,
  double nodeWidth,
  double nodeHeight,
  double hGap,
  double vGap,
) {
  final nodes = diagram.nodes;
  final edges = diagram.edges;
  final isLR = diagram.direction == 'LR' || diagram.direction == 'RL';

  // Compute incoming degree for layers
  final inDegree = <String, int>{for (var n in nodes) n.id: 0};
  final adj = <String, List<String>>{for (var n in nodes) n.id: []};

  for (final e in edges) {
    if (adj.containsKey(e.fromId) && inDegree.containsKey(e.toId)) {
      adj[e.fromId]!.add(e.toId);
      inDegree[e.toId] = (inDegree[e.toId] ?? 0) + 1;
    }
  }

  // Assign layers via topological BFS
  final nodeLayer = <String, int>{};
  final queue = <String>[];

  // Start with nodes having 0 in-degree
  for (final n in nodes) {
    if ((inDegree[n.id] ?? 0) == 0) {
      queue.add(n.id);
      nodeLayer[n.id] = 0;
    }
  }

  // If cycle or no 0-degree, pick first
  if (queue.isEmpty && nodes.isNotEmpty) {
    queue.add(nodes.first.id);
    nodeLayer[nodes.first.id] = 0;
  }

  while (queue.isNotEmpty) {
    final curr = queue.removeAt(0);
    final currL = nodeLayer[curr] ?? 0;

    for (final next in adj[curr] ?? []) {
      if (!nodeLayer.containsKey(next) || (nodeLayer[next]! < currL + 1)) {
        nodeLayer[next] = currL + 1;
        queue.add(next);
      }
    }
  }

  // Any unassigned nodes default to layer 0
  for (final n in nodes) {
    nodeLayer.putIfAbsent(n.id, () => 0);
  }

  // Group by layers
  final layers = <int, List<String>>{};
  int maxLayer = 0;
  for (final entry in nodeLayer.entries) {
    layers.putIfAbsent(entry.value, () => []).add(entry.key);
    if (entry.value > maxLayer) maxLayer = entry.value;
  }

  final positions = <String, Offset>{};
  double maxColWidth = 0;
  double maxRowHeight = 0;

  for (int l = 0; l <= maxLayer; l++) {
    final list = layers[l] ?? [];
    for (int col = 0; col < list.length; col++) {
      final id = list[col];
      double x, y;
      if (isLR) {
        x = l * (nodeWidth + hGap) + 30;
        y = col * (nodeHeight + vGap) + 30;
      } else {
        x = col * (nodeWidth + hGap) + 30;
        y = l * (nodeHeight + vGap) + 30;
      }
      positions[id] = Offset(x, y);

      if (x + nodeWidth > maxColWidth) maxColWidth = x + nodeWidth;
      if (y + nodeHeight > maxRowHeight) maxRowHeight = y + nodeHeight;
    }
  }

  return _FlowchartLayoutResult(
    positions: positions,
    totalSize: Size(maxColWidth + 30, maxRowHeight + 30),
  );
}

class MermaidFlowchartWidget extends StatelessWidget {
  final ParsedMermaidDiagram diagram;
  final bool isDark;
  final TransformationController transformController;

  const MermaidFlowchartWidget({
    super.key,
    required this.diagram,
    required this.isDark,
    required this.transformController,
  });

  @override
  Widget build(BuildContext context) {
    const nodeW = 120.0;
    const nodeH = 54.0;
    const hGap = 36.0;
    const vGap = 48.0;

    final layout = _computeFlowchartLayout(diagram, nodeW, nodeH, hGap, vGap);

    return Container(
      constraints: const BoxConstraints(minHeight: 180, maxHeight: 420),
      width: double.infinity,
      color: isDark ? const Color(0xFF13151A) : const Color(0xFFF7F9FB),
      child: InteractiveViewer(
        transformationController: transformController,
        boundaryMargin: const EdgeInsets.all(60),
        minScale: 0.5,
        maxScale: 2.5,
        child: Center(
          child: SizedBox(
            width: layout.totalSize.width,
            height: layout.totalSize.height,
            child: CustomPaint(
              painter: _FlowchartPainter(
                diagram: diagram,
                positions: layout.positions,
                nodeWidth: nodeW,
                nodeHeight: nodeH,
                isDark: isDark,
              ),
              child: Stack(
                children: [
                  for (final node in diagram.nodes)
                    if (layout.positions.containsKey(node.id))
                      Positioned(
                        left: layout.positions[node.id]!.dx,
                        top: layout.positions[node.id]!.dy,
                        width: nodeW,
                        height: nodeH,
                        child: _buildNodeCard(node, isDark),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNodeCard(MermaidNode node, bool isDark) {
    // Determine shape styling
    BorderRadius radius = BorderRadius.circular(10);
    if (node.shape == MermaidNodeShape.pill) {
      radius = BorderRadius.circular(999);
    } else if (node.shape == MermaidNodeShape.rounded) {
      radius = BorderRadius.circular(20);
    } else if (node.shape == MermaidNodeShape.circle) {
      radius = BorderRadius.circular(999);
    }

    final isDecision = node.shape == MermaidNodeShape.decision;

    final bgColor = isDark
        ? const Color(0xFF232732)
        : const Color(0xFFFFFFFF);
    final borderColor = isDark
        ? const Color(0xFF3F4657)
        : const Color(0xFFCFD5DF);
    final textColor = isDark ? const Color(0xFFF1F3F7) : const Color(0xFF1A1D24);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: isDecision ? null : radius,
        border: isDecision
            ? null
            : Border.all(color: borderColor, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              node.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.25,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlowchartPainter extends CustomPainter {
  final ParsedMermaidDiagram diagram;
  final Map<String, Offset> positions;
  final double nodeWidth;
  final double nodeHeight;
  final bool isDark;

  _FlowchartPainter({
    required this.diagram,
    required this.positions,
    required this.nodeWidth,
    required this.nodeHeight,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..color = isDark ? const Color(0xFF8E99AB) : const Color(0xFF64748B)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final arrowPaint = Paint()
      ..color = isDark ? const Color(0xFF8E99AB) : const Color(0xFF64748B)
      ..style = PaintingStyle.fill;

    final isLR = diagram.direction == 'LR' || diagram.direction == 'RL';

    for (final edge in diagram.edges) {
      final fromPos = positions[edge.fromId];
      final toPos = positions[edge.toId];
      if (fromPos == null || toPos == null) continue;

      Offset startPort;
      Offset endPort;

      if (isLR) {
        startPort = Offset(fromPos.dx + nodeWidth, fromPos.dy + nodeHeight / 2);
        endPort = Offset(toPos.dx, toPos.dy + nodeHeight / 2);
      } else {
        startPort = Offset(fromPos.dx + nodeWidth / 2, fromPos.dy + nodeHeight);
        endPort = Offset(toPos.dx + nodeWidth / 2, toPos.dy);
      }

      // Draw connector path
      final path = Path();
      path.moveTo(startPort.dx, startPort.dy);

      final midX = (startPort.dx + endPort.dx) / 2;
      final midY = (startPort.dy + endPort.dy) / 2;

      if (isLR) {
        path.cubicTo(
          startPort.dx + 24, startPort.dy,
          endPort.dx - 24, endPort.dy,
          endPort.dx, endPort.dy,
        );
      } else {
        path.cubicTo(
          startPort.dx, startPort.dy + 24,
          endPort.dx, endPort.dy - 24,
          endPort.dx, endPort.dy,
        );
      }

      canvas.drawPath(path, edgePaint);

      // Draw arrowhead at endPort
      final arrowPath = Path();
      const arrowSize = 6.0;
      if (isLR) {
        arrowPath.moveTo(endPort.dx, endPort.dy);
        arrowPath.lineTo(endPort.dx - arrowSize * 1.5, endPort.dy - arrowSize);
        arrowPath.lineTo(endPort.dx - arrowSize * 1.5, endPort.dy + arrowSize);
      } else {
        arrowPath.moveTo(endPort.dx, endPort.dy);
        arrowPath.lineTo(endPort.dx - arrowSize, endPort.dy - arrowSize * 1.5);
        arrowPath.lineTo(endPort.dx + arrowSize, endPort.dy - arrowSize * 1.5);
      }
      arrowPath.close();
      canvas.drawPath(arrowPath, arrowPaint);

      // Draw label pill if present
      if (edge.label != null && edge.label!.trim().isNotEmpty) {
        final textSpan = TextSpan(
          text: edge.label!.trim(),
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
          ),
        );
        final tp = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        final labelRect = Rect.fromCenter(
          center: Offset(midX, midY),
          width: tp.width + 10,
          height: tp.height + 6,
        );

        final bgPaint = Paint()
          ..color = isDark ? const Color(0xFF1E222B) : const Color(0xFFEEF2F6)
          ..style = PaintingStyle.fill;
        final borderPaint = Paint()
          ..color = isDark ? const Color(0xFF3B4252) : const Color(0xFFCBD5E1)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke;

        canvas.drawRRect(RRect.fromRectAndRadius(labelRect, const Radius.circular(4)), bgPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(labelRect, const Radius.circular(4)), borderPaint);
        tp.paint(canvas, Offset(midX - tp.width / 2, midY - tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FlowchartPainter oldDelegate) => true;
}

// -------------------------------------------------------------
// 2. PIE CHART RENDERER
// -------------------------------------------------------------

class MermaidPieWidget extends StatelessWidget {
  final ParsedMermaidDiagram diagram;
  final bool isDark;

  const MermaidPieWidget({
    super.key,
    required this.diagram,
    required this.isDark,
  });

  static const List<Color> _paletteColors = [
    Color(0xFFFF8F6B), // Peach
    Color(0xFF1BA5BA), // Cyan
    Color(0xFFB2CD4D), // Lime
    Color(0xFFF5B842), // Amber
    Color(0xFF9D84D6), // Lavender
    Color(0xFFE05D5D), // Coral
    Color(0xFFF48FB1), // Rose Bubble
    Color(0xFF38BDF8), // Sky
  ];

  @override
  Widget build(BuildContext context) {
    final slices = diagram.pieSlices;
    final total = slices.fold<double>(0.0, (sum, s) => sum + s.value);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Donut Chart Canvas
              SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(
                  painter: _PieChartPainter(
                    slices: slices,
                    total: total,
                    colors: _paletteColors,
                    isDark: isDark,
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < slices.length; i++) ...[
                      _buildLegendRow(
                        slices[i],
                        _paletteColors[i % _paletteColors.length],
                        total,
                        isDark,
                      ),
                      if (i < slices.length - 1) const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(MermaidPieSlice slice, Color color, double total, bool isDark) {
    final pct = total > 0 ? (slice.value / total * 100).toStringAsFixed(1) : '0';

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            slice.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$pct%',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              color: isDark ? Colors.white : color.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<MermaidPieSlice> slices;
  final double total;
  final List<Color> colors;
  final bool isDark;

  _PieChartPainter({
    required this.slices,
    required this.total,
    required this.colors,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const innerRadius = 38.0;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final sweepAngle = (slice.value / total) * 2 * math.pi;

      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      final path = Path();
      path.arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
      );
      path.arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle + sweepAngle,
        -sweepAngle,
        false,
      );
      path.close();

      canvas.drawPath(path, paint);

      // White/dark slice separator line
      final borderPaint = Paint()
        ..color = isDark ? const Color(0xFF16181D) : Colors.white
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, borderPaint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) => true;
}

// -------------------------------------------------------------
// 3. SEQUENCE DIAGRAM RENDERER
// -------------------------------------------------------------

class MermaidSequenceWidget extends StatelessWidget {
  final ParsedMermaidDiagram diagram;
  final bool isDark;

  const MermaidSequenceWidget({
    super.key,
    required this.diagram,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final participants = diagram.participants;
    final messages = diagram.sequenceMessages;

    if (participants.isEmpty) {
      return const SizedBox.shrink();
    }

    const colWidth = 100.0;
    const msgHeight = 44.0;
    final totalWidth = math.max(participants.length * (colWidth + 24), 300.0);
    final totalHeight = 60.0 + messages.length * msgHeight + 30.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: SizedBox(
        width: totalWidth,
        height: totalHeight,
        child: Stack(
          children: [
            // Participant columns & lifelines
            for (int i = 0; i < participants.length; i++) ...[
              Positioned(
                left: i * (colWidth + 24),
                top: 0,
                width: colWidth,
                child: _buildParticipantHeader(participants[i], isDark),
              ),
              Positioned(
                left: i * (colWidth + 24) + colWidth / 2 - 0.5,
                top: 36,
                bottom: 0,
                child: Container(
                  width: 1.2,
                  color: isDark ? const Color(0xFF3A4252) : const Color(0xFFCBD5E1),
                ),
              ),
            ],

            // Message horizontal arrows
            for (int m = 0; m < messages.length; m++) ...[
              _buildMessageRow(
                messages[m],
                participants,
                colWidth,
                60.0 + m * msgHeight,
                isDark,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantHeader(String name, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262A36) : const Color(0xFFE9ECEF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF3F4656) : const Color(0xFFCED4DA),
          width: 1,
        ),
      ),
      child: Text(
        name,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
    );
  }

  Widget _buildMessageRow(
    MermaidSequenceMessage msg,
    List<String> participants,
    double colWidth,
    double topY,
    bool isDark,
  ) {
    final fromIdx = participants.indexOf(msg.from);
    final toIdx = participants.indexOf(msg.to);
    if (fromIdx < 0 || toIdx < 0) return const SizedBox.shrink();

    final fromX = fromIdx * (colWidth + 24) + colWidth / 2;
    final toX = toIdx * (colWidth + 24) + colWidth / 2;
    final isRight = toX > fromX;
    final left = math.min(fromX, toX);
    final width = (toX - fromX).abs();

    final arrowColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return Positioned(
      left: left,
      top: topY,
      width: width,
      height: 36,
      child: Column(
        children: [
          Text(
            msg.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (!isRight)
                Icon(Icons.arrow_left, size: 14, color: arrowColor)
              else
                const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 1.2,
                  color: arrowColor,
                ),
              ),
              if (isRight)
                Icon(Icons.arrow_right, size: 14, color: arrowColor)
              else
                const SizedBox(width: 4),
            ],
          ),
        ],
      ),
    );
  }
}
