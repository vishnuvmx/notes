import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../domain/models/whiteboard_item.dart';
import '../../../state/workspace_provider.dart';

/// Immutable snapshot for Undo / Redo history ring buffer.
class CanvasSnapshot {
  final List<CanvasNode> nodes;
  final List<CanvasEdge> edges;

  CanvasSnapshot({
    required List<CanvasNode> nodes,
    required List<CanvasEdge> edges,
  })  : nodes = List.unmodifiable(nodes.map((n) => n.copyWith())),
        edges = List.unmodifiable(edges.map((e) => e.copyWith()));
}

/// Canvas History Manager keeping a ring buffer (max 30 snapshots).
class CanvasHistoryManager {
  static const int maxHistory = 30;
  final List<CanvasSnapshot> _undoStack = [];
  final List<CanvasSnapshot> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void recordSnapshot(List<CanvasNode> nodes, List<CanvasEdge> edges) {
    _undoStack.add(CanvasSnapshot(nodes: nodes, edges: edges));
    if (_undoStack.length > maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  CanvasSnapshot? undo(List<CanvasNode> currentNodes, List<CanvasEdge> currentEdges) {
    if (!canUndo) return null;
    final previous = _undoStack.removeLast();
    _redoStack.add(CanvasSnapshot(nodes: currentNodes, edges: currentEdges));
    return previous;
  }

  CanvasSnapshot? redo(List<CanvasNode> currentNodes, List<CanvasEdge> currentEdges) {
    if (!canRedo) return null;
    final next = _redoStack.removeLast();
    _undoStack.add(CanvasSnapshot(nodes: currentNodes, edges: currentEdges));
    return next;
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}

/// Interactive Whiteboard & Flowchart Canvas Screen with complete tools,
/// Undo/Redo history, context actions, edge editing, intelligent ports, and PNG export.
class WhiteboardCanvasScreen extends StatefulWidget {
  final WhiteboardCanvasItem item;

  const WhiteboardCanvasScreen({super.key, required this.item});

  @override
  State<WhiteboardCanvasScreen> createState() => _WhiteboardCanvasScreenState();
}

class _WhiteboardCanvasScreenState extends State<WhiteboardCanvasScreen> with SingleTickerProviderStateMixin {
  late List<CanvasNode> _nodes;
  late List<CanvasEdge> _edges;
  final TransformationController _transformationController = TransformationController();
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final FocusNode _canvasFocusNode = FocusNode();

  final CanvasHistoryManager _history = CanvasHistoryManager();

  late AnimationController _cameraAnimController;
  Animation<Matrix4>? _cameraAnimation;

  String _activeTool = 'select'; // 'select', 'pan', 'connect', 'text', 'sticky', 'image'
  String? _selectedNodeId;
  String? _selectedEdgeId;
  String? _connectingFromNodeId;
  bool _isDraggingNode = false;
  bool _showGrid = true;
  final ValueNotifier<double> _scaleNotifier = ValueNotifier<double>(1.0);
  bool _isExporting = false;

  int _uniqueIdCounter = 0;
  String _generateUniqueId(String prefix) {
    _uniqueIdCounter++;
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_uniqueIdCounter';
  }

  @override
  void initState() {
    super.initState();
    _nodes = List.from(widget.item.nodes);
    _edges = List.from(widget.item.edges);

    _cameraAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    )..addListener(() {
        if (_cameraAnimation != null) {
          _transformationController.value = _cameraAnimation!.value;
        }
      });

    _transformationController.addListener(() {
      final scale = _transformationController.value.getMaxScaleOnAxis();
      if ((scale - _scaleNotifier.value).abs() > 0.01) {
        _scaleNotifier.value = scale;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _nodes.isNotEmpty) {
        _fitCanvasToContent();
      }
    });
  }

  @override
  void dispose() {
    _cameraAnimController.dispose();
    _transformationController.dispose();
    _canvasFocusNode.dispose();
    _scaleNotifier.dispose();
    super.dispose();
  }

  /// Smoothly animates the canvas view matrix with a fluid cubic curve
  void _animateCanvasToMatrix(Matrix4 target) {
    _cameraAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: target,
    ).animate(CurvedAnimation(
      parent: _cameraAnimController,
      curve: Curves.easeOutCubic,
    ));

    _cameraAnimController.forward(from: 0.0);
  }

  void _saveCanvasState() {
    final workspace = context.read<WorkspaceProvider>();
    final updated = widget.item.copyWith(
      nodes: _nodes,
      edges: _edges,
      updatedAt: DateTime.now(),
    );
    workspace.saveItem(updated);
  }

  // ================= 1. Undo / Redo Actions =================
  void _handleUndo() {
    if (!_history.canUndo) return;
    HapticFeedback.lightImpact();
    final snapshot = _history.undo(_nodes, _edges);
    if (snapshot != null) {
      setState(() {
        _nodes = List.from(snapshot.nodes);
        _edges = List.from(snapshot.edges);
        _selectedNodeId = null;
        _selectedEdgeId = null;
      });
      _saveCanvasState();
    }
  }

  void _handleRedo() {
    if (!_history.canRedo) return;
    HapticFeedback.lightImpact();
    final snapshot = _history.redo(_nodes, _edges);
    if (snapshot != null) {
      setState(() {
        _nodes = List.from(snapshot.nodes);
        _edges = List.from(snapshot.edges);
        _selectedNodeId = null;
        _selectedEdgeId = null;
      });
      _saveCanvasState();
    }
  }

  // ================= 2. Node Operations & Context Actions =================
  void _addNode(CanvasNodeType shapeType, {Offset? position, String? imagePath}) {
    HapticFeedback.lightImpact();
    _history.recordSnapshot(_nodes, _edges);

    String paletteId = 'lime';
    switch (shapeType) {
      case CanvasNodeType.startEnd:
        paletteId = 'coral';
        break;
      case CanvasNodeType.decision:
        paletteId = 'lavender';
        break;
      case CanvasNodeType.inputOutput:
        paletteId = 'amber';
        break;
      case CanvasNodeType.sticky:
        paletteId = 'yellow';
        break;
      case CanvasNodeType.textOnly:
        paletteId = 'slate';
        break;
      case CanvasNodeType.image:
        paletteId = 'peach';
        break;
      case CanvasNodeType.process:
      default:
        paletteId = 'lime';
        break;
    }

    final double x = position?.dx ?? 120.0;
    final double y = position?.dy ?? (100.0 + (_nodes.length * 40.0 % 300));
    final double width = shapeType == CanvasNodeType.decision
        ? 140
        : shapeType == CanvasNodeType.sticky
            ? 130
            : shapeType == CanvasNodeType.image
                ? 160
                : 130;
    final double height = shapeType == CanvasNodeType.decision
        ? 64
        : shapeType == CanvasNodeType.sticky
            ? 120
            : shapeType == CanvasNodeType.image
                ? 120
                : shapeType == CanvasNodeType.textOnly
                    ? 42
                    : 52;

    final newNode = CanvasNode(
      id: _generateUniqueId('node'),
      text: shapeType == CanvasNodeType.image ? '' : shapeType.label,
      shapeType: shapeType,
      x: x.clamp(0.0, 1200.0),
      y: y.clamp(0.0, 1200.0),
      width: width,
      height: height,
      paletteId: paletteId,
      imagePath: imagePath,
    );

    setState(() {
      _nodes.add(newNode);
      _selectedNodeId = newNode.id;
      _selectedEdgeId = null;
    });
    _saveCanvasState();

    if (shapeType == CanvasNodeType.textOnly || shapeType == CanvasNodeType.sticky) {
      _editNodeText(newNode);
    }
  }

  void _deleteSelectedNode() {
    if (_selectedNodeId == null) return;
    _history.recordSnapshot(_nodes, _edges);
    HapticFeedback.mediumImpact();

    final targetId = _selectedNodeId!;
    setState(() {
      _nodes.removeWhere((n) => n.id == targetId);
      // Remove any attached edges
      _edges.removeWhere((e) => e.fromNodeId == targetId || e.toNodeId == targetId);
      _selectedNodeId = null;
      _selectedEdgeId = null;
      if (_connectingFromNodeId == targetId) _connectingFromNodeId = null;
    });
    _saveCanvasState();
  }

  void _duplicateSelectedNode() {
    if (_selectedNodeId == null) return;
    final original = _nodes.firstWhere((n) => n.id == _selectedNodeId!);
    _history.recordSnapshot(_nodes, _edges);
    HapticFeedback.lightImpact();

    final cloned = original.copyWith(
      text: original.text,
      x: (original.x + 20).clamp(0.0, 1200.0),
      y: (original.y + 20).clamp(0.0, 1200.0),
    );
    final newNode = CanvasNode(
      id: _generateUniqueId('node'),
      text: cloned.text,
      shapeType: cloned.shapeType,
      x: cloned.x,
      y: cloned.y,
      width: cloned.width,
      height: cloned.height,
      paletteId: cloned.paletteId,
      imagePath: cloned.imagePath,
    );

    setState(() {
      _nodes.add(newNode);
      _selectedNodeId = newNode.id;
    });
    _saveCanvasState();
  }

  /// One-Tap Quick Branching: Spawns a connected child node in the given direction
  void _branchFromNode(CanvasNode parent, String direction) {
    HapticFeedback.lightImpact();
    _history.recordSnapshot(_nodes, _edges);

    double newX = parent.x;
    double newY = parent.y;
    String oppositePort = 'left';

    switch (direction) {
      case 'right':
        newX = (parent.x + parent.width + 75.0).clamp(0.0, 2400.0);
        newY = parent.y;
        oppositePort = 'left';
        break;
      case 'bottom':
        newX = parent.x;
        newY = (parent.y + parent.height + 75.0).clamp(0.0, 2400.0);
        oppositePort = 'top';
        break;
      case 'left':
        newX = (parent.x - parent.width - 75.0).clamp(0.0, 2400.0);
        newY = parent.y;
        oppositePort = 'right';
        break;
      case 'top':
        newX = parent.x;
        newY = (parent.y - parent.height - 75.0).clamp(0.0, 2400.0);
        oppositePort = 'bottom';
        break;
    }

    final childType = parent.shapeType == CanvasNodeType.decision
        ? CanvasNodeType.process
        : parent.shapeType;

    final childId = _generateUniqueId('node');
    final newNode = CanvasNode(
      id: childId,
      text: 'Next Step',
      shapeType: childType,
      x: newX,
      y: newY,
      width: parent.width,
      height: parent.height,
      paletteId: parent.paletteId == 'lime'
          ? 'cyan'
          : (parent.paletteId == 'cyan' ? 'amber' : 'lime'),
    );

    final edgeId = _generateUniqueId('edge');
    final newEdge = CanvasEdge(
      id: edgeId,
      fromNodeId: parent.id,
      toNodeId: childId,
      fromPort: direction,
      toPort: oppositePort,
    );

    setState(() {
      _nodes.add(newNode);
      _edges.add(newEdge);
      _selectedNodeId = newNode.id;
      _selectedEdgeId = null;
    });
    _saveCanvasState();
  }

  /// Auto-Arranges all nodes into a neat hierarchical flowchart layout
  void _autoArrangeFlowchart() {
    if (_nodes.isEmpty) return;
    _history.recordSnapshot(_nodes, _edges);
    HapticFeedback.mediumImpact();

    // 1. Build adjacency and in-degrees
    final inDegree = <String, int>{for (var n in _nodes) n.id: 0};
    final adj = <String, List<String>>{for (var n in _nodes) n.id: []};

    for (final e in _edges) {
      if (inDegree.containsKey(e.toNodeId) && adj.containsKey(e.fromNodeId)) {
        inDegree[e.toNodeId] = (inDegree[e.toNodeId] ?? 0) + 1;
        adj[e.fromNodeId]!.add(e.toNodeId);
      }
    }

    // 2. Identify root nodes
    final roots = _nodes.where((n) => (inDegree[n.id] ?? 0) == 0).map((n) => n.id).toList();
    if (roots.isEmpty && _nodes.isNotEmpty) {
      roots.add(_nodes.first.id);
    }

    // 3. Layer assignment via BFS
    final levels = <String, int>{};
    final queue = <String>[...roots];
    for (final r in roots) {
      levels[r] = 0;
    }

    while (queue.isNotEmpty) {
      final curr = queue.removeAt(0);
      final currLevel = levels[curr] ?? 0;

      for (final neighbor in (adj[curr] ?? [])) {
        if (!levels.containsKey(neighbor) || (levels[neighbor]! < currLevel + 1)) {
          levels[neighbor] = currLevel + 1;
          queue.add(neighbor);
        }
      }
    }

    // Assign any unvisited nodes to level 0
    for (final n in _nodes) {
      levels.putIfAbsent(n.id, () => 0);
    }

    // 4. Group nodes by level
    final levelGroups = <int, List<String>>{};
    levels.forEach((nodeId, lvl) {
      levelGroups.putIfAbsent(lvl, () => []).add(nodeId);
    });

    // 5. Position nodes neatly in horizontal flowchart layout (Left-to-Right)
    const double startX = 60.0;
    const double startY = 80.0;
    const double colSpacing = 220.0;
    const double rowSpacing = 110.0;

    final updatedNodes = <CanvasNode>[];
    for (final n in _nodes) {
      final lvl = levels[n.id] ?? 0;
      final group = levelGroups[lvl] ?? [n.id];
      final indexInGroup = group.indexOf(n.id);

      final newX = (startX + (lvl * colSpacing)).clamp(0.0, 2400.0);
      final newY = (startY + (indexInGroup * rowSpacing)).clamp(0.0, 2400.0);

      updatedNodes.add(n.copyWith(x: newX, y: newY));
    }

    // 6. Update edge ports for horizontal flow
    final updatedEdges = _edges.map((e) {
      return e.copyWith(fromPort: 'right', toPort: 'left');
    }).toList();

    setState(() {
      _nodes = updatedNodes;
      _edges = updatedEdges;
    });
    _saveCanvasState();

    _fitCanvasToContent();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Flowchart auto-arranged neatly'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Automatically fits and centers all flowchart nodes in the mobile viewport
  void _fitCanvasToContent() {
    if (_nodes.isEmpty) {
      _transformationController.value = Matrix4.identity();
      return;
    }
    double minX = _nodes.first.x;
    double maxX = _nodes.first.x + _nodes.first.width;
    double minY = _nodes.first.y;
    double maxY = _nodes.first.y + _nodes.first.height;

    for (final node in _nodes) {
      minX = math.min(minX, node.x);
      maxX = math.max(maxX, node.x + node.width);
      minY = math.min(minY, node.y);
      maxY = math.max(maxY, node.y + node.height);
    }

    const padding = 70.0;
    final contentW = (maxX - minX) + (padding * 2);
    final contentH = (maxY - minY) + (padding * 2);

    final size = MediaQuery.sizeOf(context);
    final scaleX = size.width / contentW;
    final scaleY = (size.height - 220) / contentH;
    final fitScale = math.min(scaleX, scaleY).clamp(0.35, 1.6);

    final centerScreenX = size.width / 2;
    final centerScreenY = (size.height - 100) / 2;
    final centerContentX = (minX + maxX) / 2;
    final centerContentY = (minY + maxY) / 2;

    final transX = centerScreenX - (centerContentX * fitScale);
    final transY = centerScreenY - (centerContentY * fitScale);

    final matrix = Matrix4.identity()
      ..translate(transX, transY)
      ..scale(fitScale, fitScale, 1.0);

    _animateCanvasToMatrix(matrix);
  }

  void _changeNodeColor(String paletteId) {
    if (_selectedNodeId == null) return;
    _history.recordSnapshot(_nodes, _edges);
    HapticFeedback.selectionClick();

    setState(() {
      final index = _nodes.indexWhere((n) => n.id == _selectedNodeId);
      if (index >= 0) {
        _nodes[index] = _nodes[index].copyWith(paletteId: paletteId);
      }
    });
    _saveCanvasState();
  }

  void _editNodeText(CanvasNode node) {
    final controller = TextEditingController(text: node.text);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Node Text'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: node.shapeType == CanvasNodeType.sticky ? 4 : 1,
            decoration: const InputDecoration(hintText: 'Enter node label...'),
            onSubmitted: (val) {
              _saveNodeText(node, val);
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _saveNodeText(node, controller.text);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _saveNodeText(CanvasNode node, String rawText) {
    final newText = rawText.trim();
    _history.recordSnapshot(_nodes, _edges);
    setState(() {
      final index = _nodes.indexWhere((n) => n.id == node.id);
      if (index >= 0) {
        _nodes[index] = _nodes[index].copyWith(text: newText);
      }
    });
    _saveCanvasState();
  }

  // ================= 3. Edge Deletion & Editing =================
  void _handleCanvasTap(Offset localPos) {
    _canvasFocusNode.requestFocus();

    // If waiting to connect and user taps empty canvas, cancel connect mode
    if (_connectingFromNodeId != null) {
      setState(() => _connectingFromNodeId = null);
      return;
    }

    // 1. Tool Rail Placeholders (Sticky & Text)
    if (_activeTool == 'sticky') {
      _addNode(CanvasNodeType.sticky, position: localPos);
      setState(() => _activeTool = 'select');
      return;
    }
    if (_activeTool == 'text') {
      _addNode(CanvasNodeType.textOnly, position: localPos);
      setState(() => _activeTool = 'select');
      return;
    }

    // 2. Edge Hit Testing
    for (final edge in _edges) {
      final from = _nodes.cast<CanvasNode?>().firstWhere(
            (n) => n?.id == edge.fromNodeId,
            orElse: () => null,
          );
      final to = _nodes.cast<CanvasNode?>().firstWhere(
            (n) => n?.id == edge.toNodeId,
            orElse: () => null,
          );
      if (from == null || to == null) continue;

      final ports = _resolveEdgePorts(edge, from, to);
      final start = ports.start;
      final end = ports.end;

      final midY = (start.dy + end.dy) / 2;
      final d1 = _distToSegment(localPos, start, Offset(start.dx, midY));
      final d2 = _distToSegment(localPos, Offset(start.dx, midY), Offset(end.dx, midY));
      final d3 = _distToSegment(localPos, Offset(end.dx, midY), end);

      final minDist = math.min(d1, math.min(d2, d3));
      if (minDist <= 20.0) {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedEdgeId = edge.id;
          _selectedNodeId = null;
        });
        return;
      }
    }

    // Deselect if tapped empty area
    setState(() {
      _selectedNodeId = null;
      _selectedEdgeId = null;
    });
  }

  ({Offset start, Offset end}) _resolveEdgePorts(CanvasEdge edge, CanvasNode from, CanvasNode to) {
    Offset start = from.bottomPort;
    Offset end = to.topPort;

    if (edge.fromPort == 'top') start = from.topPort;
    if (edge.fromPort == 'bottom') start = from.bottomPort;
    if (edge.fromPort == 'left') start = from.leftPort;
    if (edge.fromPort == 'right') start = from.rightPort;

    if (edge.toPort == 'top') end = to.topPort;
    if (edge.toPort == 'bottom') end = to.bottomPort;
    if (edge.toPort == 'left') end = to.leftPort;
    if (edge.toPort == 'right') end = to.rightPort;

    return (start: start, end: end);
  }

  double _distToSegment(Offset p, Offset a, Offset b) {
    final l2 = (b - a).distanceSquared;
    if (l2 == 0) return (p - a).distance;
    final t = (((p.dx - a.dx) * (b.dx - a.dx) + (p.dy - a.dy) * (b.dy - a.dy)) / l2).clamp(0.0, 1.0);
    final projection = Offset(a.dx + t * (b.dx - a.dx), a.dy + t * (b.dy - a.dy));
    return (p - projection).distance;
  }

  void _showEdgeEditDialog(CanvasEdge edge) {
    final controller = TextEditingController(text: edge.label ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Connector Line'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Edge Label',
                  hintText: 'e.g. Yes, No, Approved',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ActionChip(
                    label: const Text('Yes'),
                    onPressed: () => controller.text = 'Yes',
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('No'),
                    onPressed: () => controller.text = 'No',
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              icon: const TackIcon(TackIcons.trash, size: 16, color: AppColors.error),
              label: const Text('Delete', style: TextStyle(color: AppColors.error)),
              onPressed: () {
                _history.recordSnapshot(_nodes, _edges);
                setState(() {
                  _edges.removeWhere((e) => e.id == edge.id);
                  _selectedEdgeId = null;
                });
                _saveCanvasState();
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              onPressed: () {
                final label = controller.text.trim();
                _history.recordSnapshot(_nodes, _edges);
                setState(() {
                  final index = _edges.indexWhere((e) => e.id == edge.id);
                  if (index >= 0) {
                    _edges[index] = _edges[index].copyWith(label: label.isEmpty ? null : label);
                  }
                });
                _saveCanvasState();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // ================= 4. Image Tool Picker =================
  Future<void> _pickAndInsertImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final targetFileName = 'wb_img_${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final savedImage = await File(file.path).copy('${appDir.path}/$targetFileName');
      _addNode(
        CanvasNodeType.image,
        position: const Offset(200, 200),
        imagePath: savedImage.path,
      );
    }
  }

  // ================= 5. Share & Export PNG =================
  Future<void> _exportAndShareCanvas() async {
    if (_isExporting) return;

    // Deselect active node/edge so highlight capsule doesn't get captured
    if (_selectedNodeId != null || _selectedEdgeId != null) {
      setState(() {
        _selectedNodeId = null;
        _selectedEdgeId = null;
      });
      await WidgetsBinding.instance.endOfFrame;
    }

    setState(() => _isExporting = true);

    try {
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Canvas render boundary not ready');
      }

      final ui.Image fullImage = await boundary.toImage(pixelRatio: 2.0);
      ui.Image exportImage = fullImage;

      // Crop to content bounding box if nodes exist
      if (_nodes.isNotEmpty) {
        double minX = _nodes.first.x;
        double maxX = _nodes.first.x + _nodes.first.width;
        double minY = _nodes.first.y;
        double maxY = _nodes.first.y + _nodes.first.height;
        for (final node in _nodes) {
          minX = math.min(minX, node.x);
          maxX = math.max(maxX, node.x + node.width);
          minY = math.min(minY, node.y);
          maxY = math.max(maxY, node.y + node.height);
        }

        const pad = 40.0;
        final cropL = (minX - pad).clamp(0.0, 2600.0);
        final cropT = (minY - pad).clamp(0.0, 2600.0);
        final cropR = (maxX + pad).clamp(0.0, 2600.0);
        final cropB = (maxY + pad).clamp(0.0, 2600.0);
        final cropW = cropR - cropL;
        final cropH = cropB - cropT;

        if (cropW > 20 && cropH > 20) {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, cropW * 2.0, cropH * 2.0));
          final srcRect = Rect.fromLTWH(cropL * 2.0, cropT * 2.0, cropW * 2.0, cropH * 2.0);
          final dstRect = Rect.fromLTWH(0, 0, cropW * 2.0, cropH * 2.0);
          canvas.drawImageRect(fullImage, srcRect, dstRect, Paint());
          exportImage = await recorder.endRecording().toImage((cropW * 2.0).toInt(), (cropH * 2.0).toInt());
        }
      }

      final ByteData? byteData = await exportImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to generate PNG bytes');
      }

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/whiteboard_${widget.item.id}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = await File(filePath).create();
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '${widget.item.title} Flowchart',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return KeyboardListener(
      focusNode: _canvasFocusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.delete ||
              event.logicalKey == LogicalKeyboardKey.backspace) {
            if (_selectedNodeId != null) {
              _deleteSelectedNode();
            } else if (_selectedEdgeId != null) {
              _history.recordSnapshot(_nodes, _edges);
              setState(() {
                _edges.removeWhere((e) => e.id == _selectedEdgeId);
                _selectedEdgeId = null;
              });
              _saveCanvasState();
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFFAFBFD),
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          leading: IconButton(
            icon: const TackIcon(TackIcons.back, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item.title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Row(
                children: [
                  Text(
                    'Whiteboard',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 14),
                ],
              ),
            ],
          ),
          actions: [
            // Undo Button (Disabled when stack is empty)
            IconButton(
              icon: TackIcon(
                TackIcons.undo,
                size: 20,
                color: _history.canUndo
                    ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
              onPressed: _history.canUndo ? _handleUndo : null,
              tooltip: 'Undo',
            ),

            // Redo Button (Disabled when stack is empty)
            IconButton(
              icon: TackIcon(
                TackIcons.redo,
                size: 20,
                color: _history.canRedo
                    ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
              onPressed: _history.canRedo ? _handleRedo : null,
              tooltip: 'Redo',
            ),

            // Export & Share Button
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md, left: AppSpacing.xs),
              child: ElevatedButton(
                onPressed: _isExporting ? null : _exportAndShareCanvas,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.lightSurface : AppColors.primaryDark,
                  foregroundColor: isDark ? AppColors.darkBackground : AppColors.lightSurface,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  minimumSize: const Size(60, 36),
                ),
                child: _isExporting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Share'),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Infinite/Bounded Interactive Canvas
            InteractiveViewer(
              transformationController: _transformationController,
              boundaryMargin: const EdgeInsets.all(1600),
              minScale: 0.25,
              maxScale: 3.5,
              // When dragging a node, disable pan to eliminate gesture conflict
              panEnabled: (_activeTool == 'pan' || _activeTool == 'select') && !_isDraggingNode,
              child: GestureDetector(
                onTapUp: (details) => _handleCanvasTap(details.localPosition),
                onDoubleTapDown: (details) {
                  final tap = details.localPosition;
                  for (final edge in _edges) {
                    final from = _nodes.cast<CanvasNode?>().firstWhere((n) => n?.id == edge.fromNodeId, orElse: () => null);
                    final to = _nodes.cast<CanvasNode?>().firstWhere((n) => n?.id == edge.toNodeId, orElse: () => null);
                    if (from == null || to == null) continue;

                    final ports = _resolveEdgePorts(edge, from, to);
                    final waypoints = _CanvasEdgesPainter.computeWaypoints(
                      ports.start,
                      edge.fromPort ?? 'bottom',
                      ports.end,
                      edge.toPort ?? 'top',
                    );

                    for (int i = 0; i < waypoints.length - 1; i++) {
                      if (_distToSegment(tap, waypoints[i], waypoints[i + 1]) <= 22.0) {
                        _showEdgeEditDialog(edge);
                        return;
                      }
                    }
                  }
                },
                child: RepaintBoundary(
                  key: _repaintBoundaryKey,
                  child: SizedBox(
                    width: 2600,
                    height: 2600,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _CanvasGridPainter(showGrid: _showGrid, isDark: isDark),
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _CanvasEdgesPainter(
                              nodes: _nodes,
                              edges: _edges,
                              selectedEdgeId: _selectedEdgeId,
                              isDark: isDark,
                            ),
                          ),
                        ),
                        ..._nodes.map((node) => RepaintBoundary(
                              key: ValueKey(node.id),
                              child: _buildNodeWidget(node, isDark),
                            )),
                        if (_selectedNodeId != null) ...[
                          _buildSelectedNodeCapsule(isDark),
                          _buildNodeBranchHandles(isDark),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Top Connecting Mode Banner Indicator
            if (_connectingFromNodeId != null)
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.link_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Tap target node to connect',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => setState(() => _connectingFromNodeId = null),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Top Node Shapes Palette
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: _buildTopNodePalette(isDark),
            ),

            // Left Tool Rail (Slim & ergonomic)
            Positioned(
              left: AppSpacing.sm,
              top: 72,
              child: _buildLeftToolRail(isDark),
            ),

            // Bottom Consolidated Controls Dock (Grid, Auto-Align, Fit, Zoom)
            Positioned(
              bottom: AppSpacing.md,
              left: 0,
              right: 0,
              child: Center(
                child: _buildBottomControlsBar(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI Builder Methods =================

  // Top Node Palette: Start/End, Process, Decision, I/O, Connector with true flowchart shape previews
  Widget _buildTopNodePalette(bool isDark) {
    final items = [
      (type: CanvasNodeType.startEnd, label: 'Start / End', color: AppColors.pastelCoralLight),
      (type: CanvasNodeType.process, label: 'Process', color: AppColors.pastelLimeLight),
      (type: CanvasNodeType.decision, label: 'Decision', color: AppColors.pastelLavenderLight),
      (type: CanvasNodeType.inputOutput, label: 'Input / Output', color: AppColors.pastelAmberLight),
      (type: CanvasNodeType.connector, label: 'Connector', color: AppColors.pastelCyanLight),
    ];

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: AppSpacing.roundedPill,
          boxShadow: AppSpacing.floatingControlShadow,
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: items.map((item) {
              return Tooltip(
                message: 'Add ${item.label} to canvas',
                child: InkWell(
                  onTap: () => _addNode(item.type),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildShapePreview(item.type, item.color, isDark),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildShapePreview(CanvasNodeType type, Color color, bool isDark) {
    switch (type) {
      case CanvasNodeType.startEnd:
        return Container(
          width: 26,
          height: 14,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: color, width: 1.5),
          ),
        );
      case CanvasNodeType.decision:
        return Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(1.5),
              border: Border.all(color: color, width: 1.5),
            ),
          ),
        );
      case CanvasNodeType.inputOutput:
        return Transform(
          transform: Matrix4.skewX(-0.25),
          child: Container(
            width: 24,
            height: 14,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: color, width: 1.5),
            ),
          ),
        );
      case CanvasNodeType.connector:
        return Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.35),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
        );
      case CanvasNodeType.process:
      default:
        return Container(
          width: 26,
          height: 14,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: color, width: 1.5),
          ),
        );
    }
  }

  // Left Tool Rail (Slim & ergonomic context icons)
  Widget _buildLeftToolRail(bool isDark) {
    final tools = [
      (id: 'select', icon: Icons.near_me_rounded, tooltip: 'Select & Move Shapes'),
      (id: 'pan', icon: Icons.pan_tool_rounded, tooltip: 'Pan Canvas'),
      (id: 'connect', icon: Icons.alt_route_rounded, tooltip: 'Connect Nodes with Arrows'),
      (id: 'sticky', icon: Icons.sticky_note_2_outlined, tooltip: 'Add Sticky Note'),
      (id: 'text', icon: Icons.title_rounded, tooltip: 'Add Text Label'),
      (id: 'image', icon: Icons.add_photo_alternate_outlined, tooltip: 'Insert Image'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppSpacing.roundedMd,
        boxShadow: AppSpacing.floatingControlShadow,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: tools.map((tool) {
          final isSelected = _activeTool == tool.id;
          return Tooltip(
            message: tool.tooltip,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                if (tool.id == 'image') {
                  _pickAndInsertImage();
                } else {
                  setState(() => _activeTool = tool.id);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.darkSurfaceAlt : const Color(0xFFEFF6FF))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(
                          color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                          width: 1.2,
                        )
                      : null,
                ),
                child: Center(
                  child: Icon(
                    tool.icon,
                    size: 20,
                    color: isSelected
                        ? (isDark ? AppColors.primaryLight : AppColors.primaryDark)
                        : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Consolidated Bottom Controls Bar (Grid, Auto-Align, Fit, Zoom)
  Widget _buildBottomControlsBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppSpacing.roundedPill,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: AppSpacing.floatingControlShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grid toggle
          Tooltip(
            message: _showGrid ? 'Hide Grid' : 'Show Grid',
            child: IconButton(
              icon: Icon(
                _showGrid ? Icons.grid_on_rounded : Icons.grid_off_rounded,
                size: 19,
                color: _showGrid ? AppColors.accentAmber : (isDark ? Colors.white54 : Colors.black45),
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _showGrid = !_showGrid);
              },
              visualDensity: VisualDensity.compact,
            ),
          ),
          Container(
            height: 18,
            width: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            margin: const EdgeInsets.symmetric(horizontal: 2),
          ),
          // Auto-align flowchart (context icon: account_tree_rounded)
          Tooltip(
            message: 'Auto-Align Flowchart',
            child: IconButton(
              icon: const Icon(Icons.account_tree_rounded, size: 19, color: AppColors.accentAmber),
              onPressed: _autoArrangeFlowchart,
              visualDensity: VisualDensity.compact,
            ),
          ),
          // Fit whole flowchart to screen
          Tooltip(
            message: 'Fit to View',
            child: IconButton(
              icon: const Icon(Icons.fit_screen_rounded, size: 19),
              onPressed: () {
                HapticFeedback.lightImpact();
                _fitCanvasToContent();
              },
              visualDensity: VisualDensity.compact,
            ),
          ),
          Container(
            height: 18,
            width: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            margin: const EdgeInsets.symmetric(horizontal: 2),
          ),
          // Zoom out
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 18),
            onPressed: () {
              HapticFeedback.selectionClick();
              final matrix = _transformationController.value.clone()..scaleByDouble(0.8, 0.8, 1.0, 1.0);
              _animateCanvasToMatrix(matrix);
            },
            visualDensity: VisualDensity.compact,
            tooltip: 'Zoom Out',
          ),
          // Scale indicator (ValueListenableBuilder for zero re-renders)
          ValueListenableBuilder<double>(
            valueListenable: _scaleNotifier,
            builder: (context, scale, _) {
              return InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  final matrix = Matrix4.identity();
                  _animateCanvasToMatrix(matrix);
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    '${(scale * 100).toInt()}%',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              );
            },
          ),
          // Zoom in
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 18),
            onPressed: () {
              HapticFeedback.selectionClick();
              final matrix = _transformationController.value.clone()..scaleByDouble(1.25, 1.25, 1.0, 1.0);
              _animateCanvasToMatrix(matrix);
            },
            visualDensity: VisualDensity.compact,
            tooltip: 'Zoom In',
          ),
        ],
      ),
    );
  }

  // Floating Context Actions Capsule Anchored Above/Below Selected Node
  Widget _buildSelectedNodeCapsule(bool isDark) {
    final node = _nodes.cast<CanvasNode?>().firstWhere(
          (n) => n?.id == _selectedNodeId,
          orElse: () => null,
        );
    if (node == null) return const SizedBox.shrink();

    // If node is near top border, place capsule below it to avoid clipping
    final bool placeBelow = node.y < 56;
    final capsuleTop = placeBelow
        ? (node.y + node.height + 8).clamp(8.0, 2500.0)
        : (node.y - 48).clamp(8.0, 2500.0);
    final capsuleLeft = (node.x + (node.width / 2) - 100).clamp(8.0, 2500.0);

    return Positioned(
      left: capsuleLeft,
      top: capsuleTop,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: Opacity(
              opacity: scale.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2028) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF383C4A) : const Color(0xFF191A23),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Color Swatch Picker Popup
                PopupMenuButton<String>(
                  tooltip: 'Change Color',
                  offset: Offset(0, placeBelow ? 40 : -50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  itemBuilder: (context) {
                    return AppColors.presetPalettes.map((palette) {
                      return PopupMenuItem<String>(
                        value: palette.id,
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: palette.lightColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: palette.darkColor,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(palette.name),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  onSelected: (val) => _changeNodeColor(val),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.getPaletteById(node.paletteId).lightColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? Colors.white38 : Colors.black26, width: 1.2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // 2. Edit Text Action
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit Text',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _editNodeText(node),
                ),
                const SizedBox(width: 4),

                // 3. Connect From Node Action
                IconButton(
                  icon: const Icon(Icons.link_rounded, size: 18),
                  tooltip: 'Connect to another node',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () {
                    setState(() {
                      _activeTool = 'connect';
                      _connectingFromNodeId = node.id;
                    });
                  },
                ),
                const SizedBox(width: 4),

                // 4. Delete Action
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                  tooltip: 'Delete Node',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: _deleteSelectedNode,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Quick-Branch (+) Handles on the Cardinal Ports of Selected Node (omitting ports with existing edges)
  Widget _buildNodeBranchHandles(bool isDark) {
    final node = _nodes.cast<CanvasNode?>().firstWhere(
          (n) => n?.id == _selectedNodeId,
          orElse: () => null,
        );
    if (node == null) return const SizedBox.shrink();

    final hasRightEdge = _edges.any((e) =>
        (e.fromNodeId == node.id && (e.fromPort ?? 'bottom') == 'right') ||
        (e.toNodeId == node.id && (e.toPort ?? 'top') == 'right'));
    final hasBottomEdge = _edges.any((e) =>
        (e.fromNodeId == node.id && (e.fromPort ?? 'bottom') == 'bottom') ||
        (e.toNodeId == node.id && (e.toPort ?? 'top') == 'bottom'));
    final hasLeftEdge = _edges.any((e) =>
        (e.fromNodeId == node.id && (e.fromPort ?? 'bottom') == 'left') ||
        (e.toNodeId == node.id && (e.toPort ?? 'top') == 'left'));
    final hasTopEdge = _edges.any((e) =>
        (e.fromNodeId == node.id && (e.fromPort ?? 'bottom') == 'top') ||
        (e.toNodeId == node.id && (e.toPort ?? 'top') == 'top'));

    return Stack(
      children: [
        if (!hasRightEdge)
          Positioned(
            left: node.x + node.width + 6,
            top: node.y + (node.height / 2) - 13,
            child: _buildBranchHandleIcon(
              icon: Icons.add_rounded,
              tooltip: 'Branch Right',
              isDark: isDark,
              onTap: () => _branchFromNode(node, 'right'),
            ),
          ),
        if (!hasBottomEdge)
          Positioned(
            left: node.x + (node.width / 2) - 13,
            top: node.y + node.height + 6,
            child: _buildBranchHandleIcon(
              icon: Icons.add_rounded,
              tooltip: 'Branch Down',
              isDark: isDark,
              onTap: () => _branchFromNode(node, 'bottom'),
            ),
          ),
        if (!hasLeftEdge)
          Positioned(
            left: node.x - 32,
            top: node.y + (node.height / 2) - 13,
            child: _buildBranchHandleIcon(
              icon: Icons.add_rounded,
              tooltip: 'Branch Left',
              isDark: isDark,
              onTap: () => _branchFromNode(node, 'left'),
            ),
          ),
        if (!hasTopEdge)
          Positioned(
            left: node.x + (node.width / 2) - 13,
            top: node.y - 32,
            child: _buildBranchHandleIcon(
              icon: Icons.add_rounded,
              tooltip: 'Branch Up',
              isDark: isDark,
              onTap: () => _branchFromNode(node, 'top'),
            ),
          ),
      ],
    );
  }

  Widget _buildBranchHandleIcon({
    required IconData icon,
    required String tooltip,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: scale.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.pastelLimeLight, // Tactile lime branch button
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF191A23),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: Color(0xFF191A23),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Interactive Flowchart Node Rendering
  Widget _buildNodeWidget(CanvasNode node, bool isDark) {
    final palette = AppColors.getPaletteById(node.paletteId);
    final isSelected = _selectedNodeId == node.id;
    final isConnectingSource = _connectingFromNodeId == node.id;

    Color fillColor = palette.softBackground;
    Color strokeColor = isConnectingSource
        ? AppColors.accentOrange
        : isSelected
            ? AppColors.accentOrange
            : palette.lightColor;

    if (isDark) {
      fillColor = palette.darkColor.withValues(alpha: 0.6);
      strokeColor = isConnectingSource || isSelected ? AppColors.accentOrange : palette.lightColor;
    }

    Widget shapeContent;
    switch (node.shapeType) {
      case CanvasNodeType.startEnd:
        shapeContent = Container(
          width: node.width,
          height: node.height,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(node.height / 2),
            border: Border.all(
              color: strokeColor,
              width: isConnectingSource || isSelected ? 2.5 : 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            node.text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        );
        break;

      case CanvasNodeType.decision:
        shapeContent = SizedBox(
          width: node.width,
          height: node.height,
          child: CustomPaint(
            painter: _DiamondPainter(
              fillColor: fillColor,
              strokeColor: strokeColor,
              strokeWidth: isConnectingSource || isSelected ? 2.5 : 1.5,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  node.text,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
        break;

      case CanvasNodeType.inputOutput:
        shapeContent = SizedBox(
          width: node.width,
          height: node.height,
          child: CustomPaint(
            painter: _ParallelogramPainter(
              fillColor: fillColor,
              strokeColor: strokeColor,
              strokeWidth: isConnectingSource || isSelected ? 2.5 : 1.5,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  node.text,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
        break;

      case CanvasNodeType.sticky:
        shapeContent = Container(
          width: node.width,
          height: node.height,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: palette.lightColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isConnectingSource
                  ? AppColors.accentOrange
                  : isSelected
                      ? AppColors.accentOrange
                      : strokeColor,
              width: isConnectingSource || isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Text(
            node.text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: Color(0xFF191A23),
              height: 1.3,
            ),
          ),
        );
        break;

      case CanvasNodeType.textOnly:
        shapeContent = Container(
          width: node.width,
          height: node.height,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? fillColor.withValues(alpha: 0.5) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isConnectingSource || isSelected
                ? Border.all(color: AppColors.accentOrange, width: 1.5)
                : null,
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            node.text,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        );
        break;

      case CanvasNodeType.image:
        shapeContent = Container(
          width: node.width,
          height: node.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isConnectingSource || isSelected ? AppColors.accentOrange : strokeColor,
              width: isConnectingSource || isSelected ? 2.5 : 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: node.imagePath != null && File(node.imagePath!).existsSync()
                ? Image.file(File(node.imagePath!), fit: BoxFit.cover)
                : Container(
                    color: fillColor,
                    child: const Center(child: Icon(Icons.image_outlined, size: 32)),
                  ),
          ),
        );
        break;

      case CanvasNodeType.process:
      default:
        shapeContent = Container(
          width: node.width,
          height: node.height,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: strokeColor,
              width: isConnectingSource || isSelected ? 2.5 : 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            node.text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        );
        break;
    }

    return Positioned(
      left: node.x,
      top: node.y,
      child: GestureDetector(
        onTap: () {
          _canvasFocusNode.requestFocus();
          setState(() {
            _selectedNodeId = node.id;
            _selectedEdgeId = null;

            if (_activeTool == 'connect') {
              if (_connectingFromNodeId == null) {
                _connectingFromNodeId = node.id;
              } else if (_connectingFromNodeId != node.id) {
                // Intelligent port selection based on relative node positions
                final fromNode = _nodes.firstWhere((n) => n.id == _connectingFromNodeId);
                String fromPort = 'bottom';
                String toPort = 'top';

                if (node.y + node.height < fromNode.y) {
                  fromPort = 'top';
                  toPort = 'bottom';
                } else if (node.y > fromNode.y + fromNode.height) {
                  fromPort = 'bottom';
                  toPort = 'top';
                } else if (node.x > fromNode.x) {
                  fromPort = 'right';
                  toPort = 'left';
                } else {
                  fromPort = 'left';
                  toPort = 'right';
                }

                _history.recordSnapshot(_nodes, _edges);
                _edges.add(CanvasEdge(
                  id: _generateUniqueId('edge'),
                  fromNodeId: _connectingFromNodeId!,
                  toNodeId: node.id,
                  fromPort: fromPort,
                  toPort: toPort,
                ));
                _connectingFromNodeId = null;
                _saveCanvasState();
              }
            }
          });
        },
        onDoubleTap: () => _editNodeText(node),
        onPanStart: (_) {
          // Disable InteractiveViewer pan so gestures don't conflict
          setState(() => _isDraggingNode = true);
          _history.recordSnapshot(_nodes, _edges);
        },
        onPanUpdate: (details) {
          setState(() {
            final index = _nodes.indexWhere((n) => n.id == node.id);
            if (index >= 0) {
              _nodes[index] = _nodes[index].copyWith(
                x: (_nodes[index].x + details.delta.dx).clamp(0.0, 2400.0),
                y: (_nodes[index].y + details.delta.dy).clamp(0.0, 2400.0),
              );
            }
          });
        },
        onPanEnd: (_) {
          setState(() => _isDraggingNode = false);
          _saveCanvasState();
        },
        onPanCancel: () {
          setState(() => _isDraggingNode = false);
        },
        child: shapeContent,
      ),
    );
  }
}

/// Precise Diamond / Rhombus Painter for Decision flowchart nodes
class _DiamondPainter extends CustomPainter {
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;

  _DiamondPainter({
    required this.fillColor,
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height / 2)
      ..close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _DiamondPainter oldDelegate) =>
      oldDelegate.fillColor != fillColor ||
      oldDelegate.strokeColor != strokeColor ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Precise Parallelogram Painter for Input / Output flowchart nodes
class _ParallelogramPainter extends CustomPainter {
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;

  _ParallelogramPainter({
    required this.fillColor,
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const skew = 14.0;
    final path = Path()
      ..moveTo(skew, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - skew, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _ParallelogramPainter oldDelegate) =>
      oldDelegate.fillColor != fillColor ||
      oldDelegate.strokeColor != strokeColor ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Canvas Grid Painter
class _CanvasGridPainter extends CustomPainter {
  final bool showGrid;
  final bool isDark;

  _CanvasGridPainter({required this.showGrid, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (!showGrid) return;
    final dotPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.07)
      ..strokeWidth = 1.5;

    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.9, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasGridPainter oldDelegate) =>
      oldDelegate.showGrid != showGrid || oldDelegate.isDark != isDark;
}

/// Canvas Flowchart Connector Lines & Arrows Painter
class _CanvasEdgesPainter extends CustomPainter {
  final List<CanvasNode> nodes;
  final List<CanvasEdge> edges;
  final String? selectedEdgeId;
  final bool isDark;

  _CanvasEdgesPainter({
    required this.nodes,
    required this.edges,
    this.selectedEdgeId,
    required this.isDark,
  });

  static List<Offset> computeWaypoints(Offset start, String fromPort, Offset end, String toPort) {
    if ((start.dx - end.dx).abs() < 2.0 &&
        ((fromPort == 'bottom' && toPort == 'top') || (fromPort == 'top' && toPort == 'bottom'))) {
      return [start, end];
    }
    if ((start.dy - end.dy).abs() < 2.0 &&
        ((fromPort == 'right' && toPort == 'left') || (fromPort == 'left' && toPort == 'right'))) {
      return [start, end];
    }

    if ((fromPort == 'bottom' && toPort == 'top') || (fromPort == 'top' && toPort == 'bottom')) {
      final midY = (start.dy + end.dy) / 2;
      return [
        start,
        Offset(start.dx, midY),
        Offset(end.dx, midY),
        end,
      ];
    } else if ((fromPort == 'right' && toPort == 'left') || (fromPort == 'left' && toPort == 'right')) {
      final midX = (start.dx + end.dx) / 2;
      return [
        start,
        Offset(midX, start.dy),
        Offset(midX, end.dy),
        end,
      ];
    } else if ((fromPort == 'right' || fromPort == 'left') && (toPort == 'top' || toPort == 'bottom')) {
      return [
        start,
        Offset(end.dx, start.dy),
        end,
      ];
    } else if ((fromPort == 'top' || fromPort == 'bottom') && (toPort == 'left' || toPort == 'right')) {
      return [
        start,
        Offset(start.dx, end.dy),
        end,
      ];
    } else {
      final midY = (start.dy + end.dy) / 2;
      return [
        start,
        Offset(start.dx, midY),
        Offset(end.dx, midY),
        end,
      ];
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      final isSelected = edge.id == selectedEdgeId;

      final lineColor = isSelected
          ? AppColors.accentOrange
          : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155));

      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = isSelected ? 3.0 : 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final arrowPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;

      final from = nodes.cast<CanvasNode?>().firstWhere(
            (n) => n?.id == edge.fromNodeId,
            orElse: () => null,
          );
      final to = nodes.cast<CanvasNode?>().firstWhere(
            (n) => n?.id == edge.toNodeId,
            orElse: () => null,
          );

      if (from == null || to == null) continue;

      Offset start = from.bottomPort;
      Offset end = to.topPort;

      final fromPort = edge.fromPort ?? 'bottom';
      final toPort = edge.toPort ?? 'top';

      if (fromPort == 'top') start = from.topPort;
      if (fromPort == 'bottom') start = from.bottomPort;
      if (fromPort == 'left') start = from.leftPort;
      if (fromPort == 'right') start = from.rightPort;

      if (toPort == 'top') end = to.topPort;
      if (toPort == 'bottom') end = to.bottomPort;
      if (toPort == 'left') end = to.leftPort;
      if (toPort == 'right') end = to.rightPort;

      final waypoints = computeWaypoints(start, fromPort, end, toPort);

      // 1. Draw origin connection dot
      canvas.drawCircle(start, 3.2, arrowPaint);

      // 2. Draw connector polyline
      final path = Path()..moveTo(waypoints.first.dx, waypoints.first.dy);
      for (int i = 1; i < waypoints.length; i++) {
        path.lineTo(waypoints[i].dx, waypoints[i].dy);
      }
      canvas.drawPath(path, linePaint);

      // 3. Draw arrow head with precise rotation matching arrival segment
      final lastSegmentStart = waypoints[waypoints.length - 2];
      final arrivalDx = end.dx - lastSegmentStart.dx;
      final arrivalDy = end.dy - lastSegmentStart.dy;
      final angle = math.atan2(arrivalDy, arrivalDx);

      canvas.save();
      canvas.translate(end.dx, end.dy);
      canvas.rotate(angle);

      final arrowPath = Path()
        ..moveTo(0, 0)
        ..lineTo(-10, -5.5)
        ..lineTo(-8, 0)
        ..lineTo(-10, 5.5)
        ..close();
      canvas.drawPath(arrowPath, arrowPaint);
      canvas.restore();

      // 4. Draw label badge (e.g. "Yes", "No") if present
      if (edge.label != null && edge.label!.trim().isNotEmpty) {
        final textSpan = TextSpan(
          text: edge.label!.trim(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        final midIdx = waypoints.length ~/ 2;
        final pA = waypoints[midIdx - 1];
        final pB = waypoints[midIdx];
        final center = Offset((pA.dx + pB.dx) / 2, (pA.dy + pB.dy) / 2);

        final labelRect = Rect.fromCenter(
          center: center,
          width: textPainter.width + 14,
          height: textPainter.height + 6,
        );

        final badgeFill = Paint()
          ..color = isDark ? const Color(0xFF1E222D) : Colors.white
          ..style = PaintingStyle.fill;
        final badgeStroke = Paint()
          ..color = isSelected
              ? AppColors.accentOrange
              : (isDark ? const Color(0xFF3B4252) : const Color(0xFFCBD5E1))
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;

        final badgeRRect = RRect.fromRectAndRadius(labelRect, const Radius.circular(6));
        canvas.drawRRect(badgeRRect, badgeFill);
        canvas.drawRRect(badgeRRect, badgeStroke);
        textPainter.paint(canvas, Offset(labelRect.left + 7, labelRect.top + 3));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasEdgesPainter oldDelegate) => true;
}
