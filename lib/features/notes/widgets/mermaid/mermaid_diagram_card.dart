import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/tack_icons.dart';
import '../../../whiteboard/models/whiteboard_item.dart';
import '../../../whiteboard/screens/whiteboard_canvas_screen.dart';
import 'mermaid_diagram_parser.dart';
import 'mermaid_extra_renderers.dart';

/// Card container that cleanly visualizes Mermaid graphs and diagrams (Flowcharts,
/// Pie Charts, Sequence Diagrams, Timelines) with responsive auto-fit,
/// interactive pan/zoom, and ZERO distracting buttons, headers, or toggles.
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

  void _openInWhiteboard(BuildContext context) {
    HapticFeedback.lightImpact();
    try {
      final whiteboardItem = _convertToWhiteboardItem();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WhiteboardCanvasScreen(item: whiteboardItem),
        ),
      );
    } catch (e, stack) {
      debugPrint('Error opening diagram in whiteboard: $e\n$stack');
    }
  }

  WhiteboardCanvasItem _convertToWhiteboardItem() {
    final id = 'wb_mermaid_${DateTime.now().millisecondsSinceEpoch}';
    final title = _parsed.title?.isNotEmpty == true
        ? _parsed.title!
        : 'Mermaid Diagram';

    final nodes = <CanvasNode>[];
    final edges = <CanvasEdge>[];

    const defaultNodeW = 140.0;
    const defaultNodeH = 64.0;
    const hGap = 40.0;
    const vGap = 56.0;

    if (_parsed.type == MermaidDiagramType.flowchart && _parsed.nodes.isNotEmpty) {
      final layout = _computeFlowchartLayout(_parsed, defaultNodeW, defaultNodeH, hGap, vGap);
      final startX = (3000.0 - layout.totalSize.width / 2).clamp(200.0, 5000.0);
      final startY = (3000.0 - layout.totalSize.height / 2).clamp(200.0, 5000.0);

      for (final n in _parsed.nodes) {
        final pos = layout.positions[n.id] ?? Offset.zero;
        final size = layout.nodeSizes[n.id] ?? const Size(defaultNodeW, defaultNodeH);

        CanvasNodeType shapeType;
        String nodePalette = 'lime';
        switch (n.shape) {
          case MermaidNodeShape.decision:
            shapeType = CanvasNodeType.decision;
            nodePalette = 'amber';
            break;
          case MermaidNodeShape.circle:
            shapeType = CanvasNodeType.connector;
            nodePalette = 'lavender';
            break;
          case MermaidNodeShape.parallelogram:
            shapeType = CanvasNodeType.inputOutput;
            nodePalette = 'cyan';
            break;
          case MermaidNodeShape.pill:
          case MermaidNodeShape.rounded:
            shapeType = CanvasNodeType.startEnd;
            nodePalette = 'coral';
            break;
          case MermaidNodeShape.process:
          default:
            shapeType = CanvasNodeType.process;
            nodePalette = 'lime';
            break;
        }

        nodes.add(CanvasNode(
          id: n.id,
          text: n.shape == MermaidNodeShape.classBox ? n.label.replaceAll('---\n', '') : n.label,
          shapeType: shapeType,
          x: pos.dx + startX,
          y: pos.dy + startY,
          width: size.width,
          height: size.height,
          paletteId: nodePalette,
        ));
      }

      final isLR = _parsed.direction == 'LR' || _parsed.direction == 'RL';
      for (int i = 0; i < _parsed.edges.length; i++) {
        final e = _parsed.edges[i];
        edges.add(CanvasEdge(
          id: 'edge_${e.fromId}_${e.toId}_$i',
          fromNodeId: e.fromId,
          toNodeId: e.toId,
          label: e.label,
          fromPort: isLR ? 'right' : 'bottom',
          toPort: isLR ? 'left' : 'top',
        ));
      }
    } else if (_parsed.type == MermaidDiagramType.sequence && _parsed.sequenceMessages.isNotEmpty) {
      final participants = <String>{};
      for (final msg in _parsed.sequenceMessages) {
        participants.add(msg.from);
        participants.add(msg.to);
      }
      final pList = participants.toList();
      final pNodes = <String, CanvasNode>{};
      for (int i = 0; i < pList.length; i++) {
        final name = pList[i];
        final node = CanvasNode(
          id: 'part_$i',
          text: name,
          shapeType: CanvasNodeType.process,
          x: 2400.0 + (i * 240.0),
          y: 2800.0,
          width: 140,
          height: 56,
          paletteId: 'lavender',
        );
        nodes.add(node);
        pNodes[name] = node;
      }
      for (int i = 0; i < _parsed.sequenceMessages.length; i++) {
        final msg = _parsed.sequenceMessages[i];
        final fromN = pNodes[msg.from];
        final toN = pNodes[msg.to];
        if (fromN != null && toN != null) {
          edges.add(CanvasEdge(
            id: 'seq_edge_$i',
            fromNodeId: fromN.id,
            toNodeId: toN.id,
            label: msg.text,
            fromPort: 'right',
            toPort: 'left',
          ));
        }
      }
    } else if (_parsed.type == MermaidDiagramType.timeline && _parsed.timelineItems.isNotEmpty) {
      CanvasNode? prevNode;
      for (int i = 0; i < _parsed.timelineItems.length; i++) {
        final item = _parsed.timelineItems[i];
        final text = '${item.period}\n${item.events.join(", ")}';
        final node = CanvasNode(
          id: 'tl_$i',
          text: text,
          shapeType: CanvasNodeType.process,
          x: 2400.0 + (i * 220.0),
          y: 2900.0,
          width: 160,
          height: 72,
          paletteId: 'cyan',
        );
        nodes.add(node);
        if (prevNode != null) {
          edges.add(CanvasEdge(
            id: 'tl_edge_$i',
            fromNodeId: prevNode.id,
            toNodeId: node.id,
            fromPort: 'right',
            toPort: 'left',
          ));
        }
        prevNode = node;
      }
    } else if (_parsed.type == MermaidDiagramType.pie && _parsed.pieSlices.isNotEmpty) {
      for (int i = 0; i < _parsed.pieSlices.length; i++) {
        final slice = _parsed.pieSlices[i];
        final angle = (i / _parsed.pieSlices.length) * 2 * math.pi;
        final x = 3000.0 + 200.0 * math.cos(angle);
        final y = 3000.0 + 200.0 * math.sin(angle);
        nodes.add(CanvasNode(
          id: 'pie_$i',
          text: '${slice.label}\n${slice.value.toStringAsFixed(1)}',
          shapeType: CanvasNodeType.startEnd,
          x: x,
          y: y,
          width: 130,
          height: 60,
          paletteId: 'coral',
        ));
      }
    } else if (_parsed.type == MermaidDiagramType.erDiagram && _parsed.erEntities.isNotEmpty) {
      final layout = _computeErEntitiesForBoard(_parsed.erEntities);
      for (int i = 0; i < _parsed.erEntities.length; i++) {
        final ent = _parsed.erEntities[i];
        final pos = layout[i];
        final fields = ent.attributes.take(4).map((a) => '${a.name}: ${a.type}').join('\n');
        nodes.add(CanvasNode(
          id: ent.name,
          text: fields.isEmpty ? ent.displayName : '${ent.displayName}\n$fields',
          shapeType: CanvasNodeType.process,
          x: pos.dx,
          y: pos.dy,
          width: 165,
          height: math.max(64.0, 42.0 + ent.attributes.take(4).length * 16.0),
          paletteId: 'cyan',
        ));
      }
      for (int i = 0; i < _parsed.erRelations.length; i++) {
        final r = _parsed.erRelations[i];
        edges.add(CanvasEdge(
          id: 'er_edge_$i',
          fromNodeId: r.fromEntity,
          toNodeId: r.toEntity,
          label: r.label.isEmpty ? null : r.label,
          fromPort: 'right',
          toPort: 'left',
        ));
      }
    } else if (_parsed.type == MermaidDiagramType.gantt && _parsed.ganttTasks.isNotEmpty) {
      CanvasNode? prev;
      for (int i = 0; i < _parsed.ganttTasks.length; i++) {
        final t = _parsed.ganttTasks[i];
        final days = math.max(1, t.endDate.difference(t.startDate).inDays);
        final n = CanvasNode(
          id: 'gantt_$i',
          text: '${t.name}\n(${t.isMilestone ? 'Milestone' : '${days}d'})',
          shapeType: t.isMilestone ? CanvasNodeType.decision : CanvasNodeType.process,
          x: 2400.0 + (i % 4) * 200.0,
          y: 2600.0 + (i ~/ 4) * 130.0,
          width: 155,
          height: 66,
          paletteId: t.isCrit ? 'coral' : (t.isDone ? 'lime' : 'amber'),
        );
        nodes.add(n);
        if (prev != null) {
          edges.add(CanvasEdge(
            id: 'gantt_edge_$i',
            fromNodeId: prev.id,
            toNodeId: n.id,
            fromPort: 'right',
            toPort: 'left',
          ));
        }
        prev = n;
      }
    } else if (_parsed.type == MermaidDiagramType.mindmap && _parsed.mindmapRoot != null) {
      void collectMindmap(MermaidMindmapNode node, int rowOffset, double xPos, String? parentId) {
        final cNode = CanvasNode(
          id: node.id,
          text: node.label,
          shapeType: node.depth == 0 ? CanvasNodeType.startEnd : CanvasNodeType.process,
          x: xPos,
          y: 2700.0 + rowOffset * 95.0,
          width: 140,
          height: 54,
          paletteId: node.depth == 0 ? 'lavender' : 'cyan',
        );
        nodes.add(cNode);
        if (parentId != null) {
          edges.add(CanvasEdge(
            id: 'mm_edge_${parentId}_${node.id}',
            fromNodeId: parentId,
            toNodeId: node.id,
            fromPort: 'right',
            toPort: 'left',
          ));
        }
        int offset = rowOffset;
        for (final c in node.children) {
          collectMindmap(c, offset, xPos + 210.0, node.id);
          offset += math.max(1, c.children.length);
        }
      }
      collectMindmap(_parsed.mindmapRoot!, 0, 2400.0, null);
    } else {
      nodes.add(CanvasNode(
        id: 'node_0',
        text: _parsed.title ?? 'Diagram',
        shapeType: CanvasNodeType.process,
        x: 2900,
        y: 2900,
        width: 160,
        height: 70,
        paletteId: 'peach',
      ));
    }

    return WhiteboardCanvasItem(
      id: id,
      title: title,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      paletteId: widget.paletteId ?? 'lavender',
      nodes: nodes,
      edges: edges,
    );
  }

  List<Offset> _computeErEntitiesForBoard(List<MermaidErEntity> entities) {
    return [
      for (int i = 0; i < entities.length; i++)
        Offset(2500.0 + (i % 3) * 240.0, 2600.0 + (i ~/ 3) * 180.0),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_parsed.isValid) {
      return _buildRawCodeView(isDark);
    }

    final tokens = context.tokens;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openInWhiteboard(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: ShapeDecoration(
          color: tokens.surfacePrimary,
          shape: SmoothRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            smoothness: AppSpacing.defaultSmoothing,
            side: BorderSide(
              color: tokens.borderSubtle,
              width: 1.0,
            ),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _buildDiagramView(isDark),
        ),
      ),
    );
  }

  Widget _buildRawCodeView(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141720) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
          width: 0.8,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          widget.rawCode,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12.0,
            height: 1.45,
            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
          ),
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
          transformController: _transformController,
        );
      case MermaidDiagramType.timeline:
        return MermaidTimelineWidget(
          diagram: _parsed,
          isDark: isDark,
          palette: _palette,
        );
      case MermaidDiagramType.erDiagram:
        return MermaidErWidget(
          diagram: _parsed,
          isDark: isDark,
          transformController: _transformController,
        );
      case MermaidDiagramType.gantt:
        return MermaidGanttWidget(
          diagram: _parsed,
          isDark: isDark,
          palette: _palette,
        );
      case MermaidDiagramType.mindmap:
        return MermaidMindmapWidget(
          diagram: _parsed,
          isDark: isDark,
          transformController: _transformController,
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
// 1. FLOWCHART RENDERER & LAYOUT ENGINE (AUTO-FIT, NO CLIPPING)
// -------------------------------------------------------------

class _FlowchartLayoutResult {
  final Map<String, Offset> positions;
  final Map<String, Size> nodeSizes;
  final Map<String, Rect> subgraphRects;
  final Size totalSize;

  const _FlowchartLayoutResult({
    required this.positions,
    required this.nodeSizes,
    this.subgraphRects = const {},
    required this.totalSize,
  });
}

_FlowchartLayoutResult _computeFlowchartLayout(
  ParsedMermaidDiagram diagram,
  double defaultNodeW,
  double defaultNodeH,
  double hGap,
  double vGap,
) {
  final nodes = diagram.nodes;
  final edges = diagram.edges;
  final subgraphs = diagram.subgraphs;
  final isLR = diagram.direction == 'LR' || diagram.direction == 'RL';

  // Measure dynamic node sizes according to label length
  final nodeSizes = <String, Size>{};
  for (final n in nodes) {
    final textLen = n.label.length;
    double w;
    double h;
    if (n.shape == MermaidNodeShape.classBox) {
      final lns = n.label.split('\n');
      final longest = lns.fold<int>(0, (m, s) => math.max(m, s.length));
      w = math.max(150.0, math.min(230.0, longest * 6.2 + 28.0));
      h = lns.where((s) => s != '---').length * 15.0 + 22.0;
    } else if (n.shape == MermaidNodeShape.decision) {
      w = math.max(130.0, math.min(210.0, textLen * 6.5 + 46.0));
      h = 64.0;
    } else if (n.shape == MermaidNodeShape.circle) {
      final diam = math.max(68.0, math.min(100.0, textLen * 6.0 + 24.0));
      w = diam;
      h = diam;
    } else {
      w = math.max(110.0, math.min(200.0, textLen * 6.5 + 32.0));
      h = 54.0;
    }
    nodeSizes[n.id] = Size(w, h);
  }

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

  for (final n in nodes) {
    if ((inDegree[n.id] ?? 0) == 0) {
      queue.add(n.id);
      nodeLayer[n.id] = 0;
    }
  }

  if (queue.isEmpty && nodes.isNotEmpty) {
    queue.add(nodes.first.id);
    nodeLayer[nodes.first.id] = 0;
  }

  int safetyCounter = 0;
  final maxSteps = math.max(nodes.length * 4, 30);
  while (queue.isNotEmpty && safetyCounter < maxSteps) {
    safetyCounter++;
    final curr = queue.removeAt(0);
    final currL = nodeLayer[curr] ?? 0;

    for (final next in adj[curr] ?? []) {
      if (!nodeLayer.containsKey(next) || (nodeLayer[next]! < currL + 1)) {
        nodeLayer[next] = currL + 1;
        queue.add(next);
      }
    }
  }

  for (final n in nodes) {
    nodeLayer.putIfAbsent(n.id, () => 0);
  }

  final nodeById = <String, MermaidNode>{for (final n in nodes) n.id: n};
  final sgById = <String, MermaidSubgraph>{for (final s in subgraphs) s.id: s};

  String subgraphChainKey(String nodeId) {
    String? cur = nodeById[nodeId]?.subgraphId;
    if (cur == null) return '';
    final parts = <String>[];
    int guard = 0;
    while (cur != null && guard++ < 16) {
      parts.add(cur);
      cur = sgById[cur]?.parentId;
    }
    return parts.reversed.join('/');
  }

  // Group by layers
  final layers = <int, List<String>>{};
  int maxLayer = 0;
  if (diagram.isClassDiagram) {
    final byLayer = <int, List<String>>{};
    for (final n in nodes) {
      byLayer.putIfAbsent(nodeLayer[n.id] ?? 0, () => []).add(n.id);
    }
    final keys = byLayer.keys.toList()..sort();
    int row = 0;
    for (final k in keys) {
      final ids = byLayer[k]!;
      for (int s = 0; s < ids.length; s += 2) {
        layers[row++] = ids.sublist(s, math.min(s + 2, ids.length));
      }
    }
    maxLayer = math.max(0, row - 1);
  } else {
    for (final entry in nodeLayer.entries) {
      layers.putIfAbsent(entry.value, () => []).add(entry.key);
      if (entry.value > maxLayer) maxLayer = entry.value;
    }
    if (subgraphs.isNotEmpty) {
      final sgFirstSeenOrder = <String, int>{};
      for (int idx = 0; idx < subgraphs.length; idx++) {
        sgFirstSeenOrder[subgraphs[idx].id] = idx;
      }
      for (final list in layers.values) {
        final origIdx = <String, int>{
          for (int i = 0; i < list.length; i++) list[i]: i,
        };
        list.sort((a, b) {
          final ka = subgraphChainKey(a);
          final kb = subgraphChainKey(b);
          if (ka != kb) return ka.compareTo(kb);
          return (origIdx[a] ?? 0).compareTo(origIdx[b] ?? 0);
        });
      }
    }
  }

  final positions = <String, Offset>{};
  final crossGap = isLR ? vGap : hGap;
  const sgGroupSep = 20.0;

  // Compute breadth per layer including subgraph separator padding
  final layerBreadths = <int, double>{};
  for (int l = 0; l <= maxLayer; l++) {
    final list = layers[l] ?? [];
    double breadth = 0;
    String? prevKey;
    for (int col = 0; col < list.length; col++) {
      final key = subgraphs.isEmpty ? '' : subgraphChainKey(list[col]);
      final size = nodeSizes[list[col]] ?? Size(defaultNodeW, defaultNodeH);
      breadth += isLR ? size.height : size.width;
      if (col > 0) {
        breadth += crossGap + (subgraphs.isNotEmpty && prevKey != key ? sgGroupSep : 0.0);
      }
      prevKey = key;
    }
    layerBreadths[l] = breadth;
  }

  double maxBreadth = 0;
  for (final b in layerBreadths.values) {
    if (b > maxBreadth) maxBreadth = b;
  }

  // Track which subgraphs start/end per layer so stacked subgraphs don't collide
  final sgMinLayer = <String, int>{};
  final sgMaxLayer = <String, int>{};
  if (subgraphs.isNotEmpty) {
    for (final n in nodes) {
      String? cur = n.subgraphId;
      final layer = nodeLayer[n.id] ?? 0;
      int guard = 0;
      while (cur != null && guard++ < 16) {
        sgMinLayer[cur] = math.min(sgMinLayer[cur] ?? layer, layer);
        sgMaxLayer[cur] = math.max(sgMaxLayer[cur] ?? layer, layer);
        cur = sgById[cur]?.parentId;
      }
    }
  }

  // Position nodes
  double currentLayerDepth = 16.0;
  for (int l = 0; l <= maxLayer; l++) {
    final list = layers[l] ?? [];
    if (subgraphs.isNotEmpty) {
      int startingCount = 0;
      for (final s in subgraphs) {
        if (sgMinLayer[s.id] == l) startingCount++;
      }
      if (startingCount > 0 && l > 0) {
        currentLayerDepth += 26.0;
      }
    }

    final currentBreadth = layerBreadths[l] ?? 0;
    final startOffset = (maxBreadth - currentBreadth) / 2 + 16.0;

    double currentColOffset = startOffset;
    double maxDepthInLayer = 0;
    String? prevKey;

    for (int col = 0; col < list.length; col++) {
      final id = list[col];
      final key = subgraphs.isEmpty ? '' : subgraphChainKey(id);
      if (col > 0 && subgraphs.isNotEmpty && prevKey != key) {
        currentColOffset += sgGroupSep;
      }
      prevKey = key;

      final size = nodeSizes[id] ?? Size(defaultNodeW, defaultNodeH);

      double x, y;
      if (isLR) {
        x = currentLayerDepth;
        y = currentColOffset;
        currentColOffset += size.height + crossGap;
        if (size.width > maxDepthInLayer) maxDepthInLayer = size.width;
      } else {
        x = currentColOffset;
        y = currentLayerDepth;
        currentColOffset += size.width + crossGap;
        if (size.height > maxDepthInLayer) maxDepthInLayer = size.height;
      }

      positions[id] = Offset(x, y);
    }

    currentLayerDepth += maxDepthInLayer + (isLR ? hGap : vGap);
    if (subgraphs.isNotEmpty && subgraphs.any((s) => sgMaxLayer[s.id] == l)) {
      currentLayerDepth += 16.0;
    }
  }

  // Compute subgraph bounding rectangles bottom-up (innermost subgraphs first)
  final subgraphRects = <String, Rect>{};
  if (subgraphs.isNotEmpty) {
    int depthOf(MermaidSubgraph sg) {
      int d = 0;
      String? p = sg.parentId;
      while (p != null && d < 16) {
        d++;
        p = sgById[p]?.parentId;
      }
      return d;
    }

    final sortedSgs = [...subgraphs]..sort((a, b) => depthOf(b).compareTo(depthOf(a)));
    for (final sg in sortedSgs) {
      Rect? bounds;
      void includeRect(Rect r) {
        bounds = bounds == null ? r : bounds!.expandToInclude(r);
      }

      for (final nid in sg.nodeIds) {
        final pos = positions[nid];
        final sz = nodeSizes[nid];
        if (pos != null && sz != null) {
          includeRect(pos & sz);
        }
      }
      for (final childSg in subgraphs) {
        if (childSg.parentId == sg.id && subgraphRects.containsKey(childSg.id)) {
          includeRect(subgraphRects[childSg.id]!);
        }
      }

      if (bounds != null) {
        var expanded = Rect.fromLTRB(
          bounds!.left - 14.0,
          bounds!.top - 30.0,
          bounds!.right + 14.0,
          bounds!.bottom + 14.0,
        );
        final minTitleW = sg.title.length * 6.8 + 36.0;
        if (expanded.width < minTitleW) {
          final extra = (minTitleW - expanded.width) / 2;
          expanded = Rect.fromLTRB(
            expanded.left - extra,
            expanded.top,
            expanded.right + extra,
            expanded.bottom,
          );
        }
        subgraphRects[sg.id] = expanded;
      }
    }
  }

  // Normalize all positions & subgraphRects so minX / minY = 16.0 (no negative clipping)
  double minX = double.infinity;
  double minY = double.infinity;
  double maxX = 0;
  double maxY = 0;

  for (final n in nodes) {
    final pos = positions[n.id];
    final sz = nodeSizes[n.id];
    if (pos == null || sz == null) continue;
    minX = math.min(minX, pos.dx);
    minY = math.min(minY, pos.dy);
    maxX = math.max(maxX, pos.dx + sz.width);
    maxY = math.max(maxY, pos.dy + sz.height);
  }
  for (final r in subgraphRects.values) {
    minX = math.min(minX, r.left);
    minY = math.min(minY, r.top);
    maxX = math.max(maxX, r.right);
    maxY = math.max(maxY, r.bottom);
  }

  if (minX.isFinite && minY.isFinite) {
    final shiftX = 16.0 - minX;
    final shiftY = 16.0 - minY;
    if (shiftX != 0 || shiftY != 0) {
      for (final key in positions.keys.toList()) {
        positions[key] = positions[key]!.translate(shiftX, shiftY);
      }
      for (final key in subgraphRects.keys.toList()) {
        subgraphRects[key] = subgraphRects[key]!.shift(Offset(shiftX, shiftY));
      }
      maxX += shiftX;
      maxY += shiftY;
    }
  } else {
    maxX = 240.0;
    maxY = 140.0;
  }

  return _FlowchartLayoutResult(
    positions: positions,
    nodeSizes: nodeSizes,
    subgraphRects: subgraphRects,
    totalSize: Size(maxX + 16.0, maxY + 16.0),
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
    const defaultNodeW = 120.0;
    const defaultNodeH = 54.0;
    const hGap = 28.0;
    const vGap = 36.0;

    final layout = _computeFlowchartLayout(diagram, defaultNodeW, defaultNodeH, hGap, vGap);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final totalW = layout.totalSize.width;
        final totalH = layout.totalSize.height;

        // Auto-scale to fit available width perfectly without horizontal overflow or clipping!
        final fitScale = (availableWidth / totalW).clamp(0.0, 1.0);
        final displayW = totalW * fitScale;
        final displayH = totalH * fitScale;

        final canvasContent = SizedBox(
          width: totalW,
          height: totalH,
          child: CustomPaint(
            painter: _FlowchartPainter(
              diagram: diagram,
              positions: layout.positions,
              nodeSizes: layout.nodeSizes,
              subgraphRects: layout.subgraphRects,
              isDark: isDark,
            ),
            child: Stack(
              children: [
                for (final node in diagram.nodes)
                  if (layout.positions.containsKey(node.id))
                    Positioned(
                      left: layout.positions[node.id]!.dx,
                      top: layout.positions[node.id]!.dy,
                      width: layout.nodeSizes[node.id]?.width ?? defaultNodeW,
                      height: layout.nodeSizes[node.id]?.height ?? defaultNodeH,
                      child: _buildNodeCard(
                        node,
                        isDark,
                        layout.nodeSizes[node.id] ?? const Size(defaultNodeW, defaultNodeH),
                      ),
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

  Widget _buildClassBox(MermaidNode node, bool isDark) {
    final border = isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8);
    final bg = isDark ? const Color(0xFF1E2430) : const Color(0xFFF8FAFC);
    final headBg = isDark ? const Color(0xFF2A3345) : const Color(0xFFE2E8F0);
    final fg = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final lines = node.label.split('\n');
    final divider = lines.indexOf('---');
    final head = divider < 0 ? lines : lines.sublist(0, divider);
    final body = divider < 0 ? <String>[] : lines.sublist(divider + 1);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: headBg,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < head.length; i++)
                  Text(
                    head[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: i == head.length - 1 ? 11.5 : 9.5,
                      fontWeight: i == head.length - 1 ? FontWeight.w800 : FontWeight.w500,
                      fontStyle: i == head.length - 1 ? FontStyle.normal : FontStyle.italic,
                      color: fg,
                      height: 1.2,
                    ),
                  ),
              ],
            ),
          ),
          if (body.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final m in body)
                      Text(
                        m,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 9.5,
                          color: fg,
                          height: 1.2,
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

  Widget _buildNodeCard(MermaidNode node, bool isDark, Size size) {
    Color bgColor;
    Color borderColor;
    Color textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    switch (node.shape) {
      case MermaidNodeShape.decision:
        bgColor = isDark ? const Color(0xFF2C241B) : const Color(0xFFFFFBEB);
        borderColor = isDark ? AppColors.accentAmber : const Color(0xFFF59E0B);
        break;
      case MermaidNodeShape.pill:
        bgColor = isDark ? const Color(0xFF192823) : const Color(0xFFF0FDF4);
        borderColor = isDark ? AppColors.pastelLimeLight : const Color(0xFF22C55E);
        break;
      case MermaidNodeShape.database:
        bgColor = isDark ? const Color(0xFF1B2635) : const Color(0xFFF0F9FF);
        borderColor = isDark ? AppColors.accentCyan : const Color(0xFF0284C7);
        break;
      case MermaidNodeShape.circle:
        bgColor = isDark ? const Color(0xFF261D2E) : const Color(0xFFFAF5FF);
        borderColor = isDark ? AppColors.pastelLavenderLight : const Color(0xFF9333EA);
        break;
      case MermaidNodeShape.rounded:
      case MermaidNodeShape.process:
      default:
        bgColor = isDark ? const Color(0xFF202531) : const Color(0xFFF8FAFC);
        borderColor = isDark ? const Color(0xFF384358) : const Color(0xFFCBD5E1);
        break;
    }

    final content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          node.label,
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: textColor,
            height: 1.25,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );

    if (node.shape == MermaidNodeShape.classBox) {
      return _buildClassBox(node, isDark);
    }

    switch (node.shape) {
      case MermaidNodeShape.decision:
        return CustomPaint(
          painter: _DiamondNodePainter(fillColor: bgColor, borderColor: borderColor, isDark: isDark),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: content,
          ),
        );
      case MermaidNodeShape.database:
        return CustomPaint(
          painter: _DatabaseNodePainter(fillColor: bgColor, borderColor: borderColor, isDark: isDark),
          child: Padding(padding: const EdgeInsets.only(top: 8), child: content),
        );
      case MermaidNodeShape.hexagon:
        return CustomPaint(
          painter: _HexagonNodePainter(fillColor: bgColor, borderColor: borderColor, isDark: isDark),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: content,
          ),
        );
      case MermaidNodeShape.circle:
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: content,
        );
      case MermaidNodeShape.pill:
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: content,
        );
      case MermaidNodeShape.rounded:
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: content,
        );
      case MermaidNodeShape.subroutine:
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1.3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(left: 8, top: 0, bottom: 0, child: Container(width: 1.2, color: borderColor)),
              Positioned(right: 8, top: 0, bottom: 0, child: Container(width: 1.2, color: borderColor)),
              content,
            ],
          ),
        );
      case MermaidNodeShape.parallelogram:
      case MermaidNodeShape.flag:
      case MermaidNodeShape.process:
      default:
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: content,
        );
    }
  }
}

class _FlowchartPainter extends CustomPainter {
  final ParsedMermaidDiagram diagram;
  final Map<String, Offset> positions;
  final Map<String, Size> nodeSizes;
  final Map<String, Rect> subgraphRects;
  final bool isDark;

  _FlowchartPainter({
    required this.diagram,
    required this.positions,
    required this.nodeSizes,
    this.subgraphRects = const {},
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Paint Subgraph Group Containers first (shallowest first so nested subgraphs layer cleanly)
    if (subgraphRects.isNotEmpty) {
      final sgById = {for (final s in diagram.subgraphs) s.id: s};
      int sgDepth(MermaidSubgraph sg) {
        int d = 0;
        String? p = sg.parentId;
        while (p != null && d < 16) {
          d++;
          p = sgById[p]?.parentId;
        }
        return d;
      }

      final orderedSgs = diagram.subgraphs
          .where((s) => subgraphRects.containsKey(s.id))
          .toList()
        ..sort((a, b) => sgDepth(a).compareTo(sgDepth(b)));

      const sgPalettes = ['lavender', 'cyan', 'amber', 'peach', 'lime'];
      for (int i = 0; i < orderedSgs.length; i++) {
        final sg = orderedSgs[i];
        final rect = subgraphRects[sg.id]!;
        final accent = AppColors.getPaletteById(sgPalettes[i % sgPalettes.length])
            .resolveAccentColor(isDark);

        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = accent.withValues(alpha: isDark ? 0.08 : 0.05)
            ..style = PaintingStyle.fill,
        );
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = accent.withValues(alpha: isDark ? 0.35 : 0.30)
            ..strokeWidth = 1.2
            ..style = PaintingStyle.stroke,
        );

        if (sg.title.isNotEmpty) {
          final tp = TextPainter(
            text: TextSpan(
              text: sg.title,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
                color: accent,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: math.max(40, rect.width - 20));

          final pillRect = Rect.fromLTWH(
            rect.left + 8,
            rect.top + 6,
            tp.width + 12,
            tp.height + 4,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(pillRect, const Radius.circular(6)),
            Paint()
              ..color = accent.withValues(alpha: isDark ? 0.16 : 0.12)
              ..style = PaintingStyle.fill,
          );
          tp.paint(canvas, Offset(pillRect.left + 6, pillRect.top + 2));
        }
      }
    }

    final arrowPaint = Paint()
      ..color = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)
      ..style = PaintingStyle.fill;

    final isLR = diagram.direction == 'LR' || diagram.direction == 'RL';

    for (final edge in diagram.edges) {
      final fromPos = positions[edge.fromId];
      final toPos = positions[edge.toId];
      if (fromPos == null || toPos == null) continue;

      final fromSize = nodeSizes[edge.fromId] ?? const Size(120, 54);
      final toSize = nodeSizes[edge.toId] ?? const Size(120, 54);

      Offset startPort;
      Offset endPort;

      if (isLR) {
        startPort = Offset(fromPos.dx + fromSize.width, fromPos.dy + fromSize.height / 2);
        endPort = Offset(toPos.dx, toPos.dy + toSize.height / 2);
      } else {
        startPort = Offset(fromPos.dx + fromSize.width / 2, fromPos.dy + fromSize.height);
        endPort = Offset(toPos.dx + toSize.width / 2, toPos.dy);
      }

      // Smooth connector path
      final path = Path();
      path.moveTo(startPort.dx, startPort.dy);

      final midX = (startPort.dx + endPort.dx) / 2;
      final midY = (startPort.dy + endPort.dy) / 2;

      if (isLR) {
        final ctrlX = (endPort.dx - startPort.dx).abs() * 0.45;
        path.cubicTo(
          startPort.dx + ctrlX, startPort.dy,
          endPort.dx - ctrlX, endPort.dy,
          endPort.dx, endPort.dy,
        );
      } else {
        final ctrlY = (endPort.dy - startPort.dy).abs() * 0.45;
        path.cubicTo(
          startPort.dx, startPort.dy + ctrlY,
          endPort.dx, endPort.dy - ctrlY,
          endPort.dx, endPort.dy,
        );
      }

      final edgePaint = Paint()
        ..color = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)
        ..strokeWidth = edge.isThick ? 2.6 : 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (edge.isDotted) {
        for (final metric in path.computeMetrics()) {
          double dist = 0.0;
          while (dist < metric.length) {
            final next = math.min(dist + 4.5, metric.length);
            canvas.drawPath(metric.extractPath(dist, next), edgePaint);
            dist += 8.5;
          }
        }
      } else {
        canvas.drawPath(path, edgePaint);
      }

      // Arrowhead at endPort
      final arrowPath = Path();
      const arrowSize = 5.5;
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

      // Label pill if present
      if (edge.label != null && edge.label!.trim().isNotEmpty) {
        final textSpan = TextSpan(
          text: edge.label!.trim(),
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
          ),
        );
        final tp = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        final labelRect = Rect.fromCenter(
          center: Offset(midX, midY),
          width: tp.width + 10,
          height: tp.height + 4,
        );

        final bgPaint = Paint()
          ..color = isDark ? const Color(0xFF1A1D27) : const Color(0xFFF1F5F9)
          ..style = PaintingStyle.fill;
        final borderPaint = Paint()
          ..color = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)
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

class _DiamondNodePainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final bool isDark;

  _DiamondNodePainter({
    required this.fillColor,
    required this.borderColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height / 2)
      ..close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: isDark ? 0.35 : 0.06), 4, false);
    canvas.drawPath(path, Paint()..color = fillColor..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = borderColor..strokeWidth = 1.4..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant _DiamondNodePainter oldDelegate) => true;
}

class _DatabaseNodePainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final bool isDark;

  _DatabaseNodePainter({
    required this.fillColor,
    required this.borderColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const ellipseHeight = 9.0;

    final path = Path()
      ..moveTo(0, ellipseHeight)
      ..lineTo(0, size.height - ellipseHeight)
      ..arcToPoint(Offset(size.width, size.height - ellipseHeight), radius: Radius.elliptical(size.width / 2, ellipseHeight), clockwise: false)
      ..lineTo(size.width, ellipseHeight)
      ..arcToPoint(Offset(0, ellipseHeight), radius: Radius.elliptical(size.width / 2, ellipseHeight), clockwise: true)
      ..close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: isDark ? 0.35 : 0.06), 4, false);
    canvas.drawPath(path, Paint()..color = fillColor..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = borderColor..strokeWidth = 1.3..style = PaintingStyle.stroke);

    final topRim = Path()
      ..moveTo(0, ellipseHeight)
      ..arcToPoint(Offset(size.width, ellipseHeight), radius: Radius.elliptical(size.width / 2, ellipseHeight), clockwise: false);
    canvas.drawPath(topRim, Paint()..color = borderColor..strokeWidth = 1.3..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant _DatabaseNodePainter oldDelegate) => true;
}

class _HexagonNodePainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final bool isDark;

  _HexagonNodePainter({
    required this.fillColor,
    required this.borderColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const pointW = 12.0;
    final path = Path()
      ..moveTo(pointW, 0)
      ..lineTo(size.width - pointW, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width - pointW, size.height)
      ..lineTo(pointW, size.height)
      ..lineTo(0, size.height / 2)
      ..close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: isDark ? 0.35 : 0.06), 4, false);
    canvas.drawPath(path, Paint()..color = fillColor..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = borderColor..strokeWidth = 1.3..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant _HexagonNodePainter oldDelegate) => true;
}

// -------------------------------------------------------------
// 2. PIE / DONUT CHART RENDERER
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

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (diagram.title != null) ...[
                Text(
                  diagram.title!,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Donut Chart Canvas
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CustomPaint(
                      painter: _PieChartPainter(
                        slices: slices,
                        total: total,
                        colors: _paletteColors,
                        isDark: isDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

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
                          if (i < slices.length - 1) const SizedBox(height: 5),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendRow(MermaidPieSlice slice, Color color, double total, bool isDark) {
    final pct = total > 0 ? (slice.value / total * 100).toStringAsFixed(1) : '0';

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            slice.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$pct%',
            style: TextStyle(
              fontSize: 10,
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
    const innerRadius = 34.0;

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
        ..color = isDark ? const Color(0xFF161820) : Colors.white
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
  final TransformationController transformController;

  const MermaidSequenceWidget({
    super.key,
    required this.diagram,
    required this.isDark,
    required this.transformController,
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
    final totalWidth = math.max(participants.length * (colWidth + 20), 280.0);
    final totalHeight = 60.0 + messages.length * msgHeight + 20.0;

    final sequenceCanvas = SizedBox(
      width: totalWidth,
      height: totalHeight,
      child: Stack(
        children: [
          // Participant columns & lifelines
          for (int i = 0; i < participants.length; i++) ...[
            Positioned(
              left: i * (colWidth + 20),
              top: 0,
              width: colWidth,
              child: _buildParticipantHeader(participants[i], isDark),
            ),
            Positioned(
              left: i * (colWidth + 20) + colWidth / 2 - 0.5,
              top: 34,
              bottom: 0,
              child: Container(
                width: 1.2,
                color: isDark ? const Color(0xFF333D52) : const Color(0xFFCBD5E1),
              ),
            ),
          ],

          // Message horizontal arrows
          for (int m = 0; m < messages.length; m++) ...[
            _buildMessageRow(
              messages[m],
              participants,
              colWidth,
              58.0 + m * msgHeight,
              isDark,
            ),
          ],
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableW = constraints.maxWidth;
        if (totalWidth <= availableW) {
          return Center(child: sequenceCanvas);
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: sequenceCanvas,
        );
      },
    );
  }

  Widget _buildParticipantHeader(String name, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222836) : const Color(0xFFEAEFF5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? const Color(0xFF3A445C) : const Color(0xFFCBD5E1),
          width: 1.0,
        ),
      ),
      child: Text(
        name,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 11,
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

    final fromX = fromIdx * (colWidth + 20) + colWidth / 2;
    final toX = toIdx * (colWidth + 20) + colWidth / 2;
    final isRight = toX > fromX;
    final left = math.min(fromX, toX);
    final width = (toX - fromX).abs();

    final arrowColor = isDark ? AppColors.pastelLavenderLight : const Color(0xFF6D28D9);

    return Positioned(
      left: left,
      top: topY,
      width: width,
      height: 38,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E222D) : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isDark ? const Color(0xFF333B4F) : const Color(0xFFE2E8F0),
                width: 0.6,
              ),
            ),
            child: Text(
              msg.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (!isRight)
                Icon(TackIcons.chevronLeft, size: 13, color: arrowColor)
              else
                const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 1.2,
                  color: arrowColor,
                ),
              ),
              if (isRight)
                TackIcon(TackIcons.chevronRight, size: 13, color: arrowColor)
              else
                const SizedBox(width: 4),
            ],
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 4. TIMELINE DIAGRAM RENDERER
// -------------------------------------------------------------

class MermaidTimelineWidget extends StatelessWidget {
  final ParsedMermaidDiagram diagram;
  final bool isDark;
  final TackColorPalette palette;

  const MermaidTimelineWidget({
    super.key,
    required this.diagram,
    required this.isDark,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final items = diagram.timelineItems;
    if (items.isEmpty) return const SizedBox.shrink();

    const itemWidth = 150.0;
    const itemGap = 20.0;
    final totalWidth = items.length * (itemWidth + itemGap) + 40.0;
    const totalHeight = 280.0;

    final axisColor = palette.resolveAccentColor(isDark).withValues(alpha: 0.35);
    final dotColor = palette.resolveAccentColor(isDark);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: math.max(totalWidth, 300.0),
        height: totalHeight,
        child: Stack(
          children: [
            // Title if present
            if (diagram.title != null)
              Positioned(
                left: 16,
                top: 8,
                child: Text(
                  diagram.title!,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),

            // Horizontal Axis Line
            Positioned(
              left: 20,
              right: 20,
              top: 90,
              height: 2.5,
              child: Container(
                decoration: BoxDecoration(
                  color: axisColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Timeline items
            for (int i = 0; i < items.length; i++) ...[
              _buildTimelineColumn(
                item: items[i],
                index: i,
                leftX: 20.0 + i * (itemWidth + itemGap),
                itemWidth: itemWidth,
                dotColor: dotColor,
                isDark: isDark,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineColumn({
    required MermaidTimelineItem item,
    required int index,
    required double leftX,
    required double itemWidth,
    required Color dotColor,
    required bool isDark,
  }) {
    return Positioned(
      left: leftX,
      top: 36,
      width: itemWidth,
      bottom: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Section Tag (if available)
          if (item.section != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: dotColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.section!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: dotColor,
                ),
              ),
            ),
          ] else
            const SizedBox(height: 16),

          // Period pill (e.g. 2002, Q1, Phase 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF222631) : const Color(0xFFEAEFF5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: dotColor.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Text(
              item.period,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Axis Connector Node Dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF161820) : Colors.white,
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.35),
                  blurRadius: 4,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Events cards
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: item.events.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, eIdx) {
                final event = item.events[eIdx];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1F28) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2E3342) : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : Colors.black12).withValues(alpha: 0.04),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    event,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
