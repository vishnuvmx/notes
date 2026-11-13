import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../domain/models/base_item.dart';
import '../../../domain/models/sticky_note.dart';
import '../../../domain/models/text_note.dart';
import '../../../domain/models/whiteboard_item.dart';
import '../../../state/workspace_provider.dart';
import '../../components/dialogs_sheets/app_bottom_sheet.dart';
import '../../components/dialogs_sheets/app_floating_dialog.dart';
import '../../components/inputs/tack_dropdown.dart';
import '../editor/note_editor_screen.dart';

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
  final String? initialFocusNodeId;

  const WhiteboardCanvasScreen({
    super.key,
    required this.item,
    this.initialFocusNodeId,
  });

  @override
  State<WhiteboardCanvasScreen> createState() => _WhiteboardCanvasScreenState();
}

class _WhiteboardCanvasScreenState extends State<WhiteboardCanvasScreen> with SingleTickerProviderStateMixin {
  static const double _canvasSize = 6000.0;
  late List<CanvasNode> _nodes;
  late List<CanvasEdge> _edges;
  final TransformationController _transformationController = TransformationController();
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final FocusNode _canvasFocusNode = FocusNode();

  final CanvasHistoryManager _history = CanvasHistoryManager();

  late AnimationController _cameraAnimController;
  Animation<Matrix4>? _cameraAnimation;

  String _activeTool = 'select'; // 'select', 'pan', 'connect', 'text', 'sticky', 'image', 'shapes'
  String? _selectedNodeId;
  String? _selectedEdgeId;
  String? _connectingFromNodeId;
  bool _isDraggingNode = false;
  bool _showGrid = true;
  bool _snapToGrid = false;
  bool _showMinimap = false;
  bool _isZenMode = false;
  bool _showShapesMenu = false;
  double _gridOpacity = 0.18;
  bool _showGridOpacitySlider = false;
  final ValueNotifier<double> _scaleNotifier = ValueNotifier<double>(1.0);
  final ScrollController _bottomDockScrollController = ScrollController();
  bool _isExporting = false;
  int _activePointers = 0;
  bool _isEdgeTouch = false;
  WorkspaceProvider? _workspaceProvider;

  @visibleForTesting
  List<CanvasNode> get nodes => _nodes;
  @visibleForTesting
  List<CanvasEdge> get edges => _edges;
  @visibleForTesting
  bool get snapToGrid => _snapToGrid;
  @visibleForTesting
  bool get showMinimap => _showMinimap;
  @visibleForTesting
  bool get isZenMode => _isZenMode;
  @visibleForTesting
  void selectEdgeForTesting(String? id) => setState(() => _selectedEdgeId = id);
  @visibleForTesting
  void selectNodeForTesting(String? id) => setState(() => _selectedNodeId = id);
  @visibleForTesting
  void branchFromNodeForTesting(CanvasNode parent, String direction) => _branchFromNode(parent, direction);
  @visibleForTesting
  void deleteEdgeForTesting(String edgeId) {
    setState(() {
      _edges.removeWhere((e) => e.id == edgeId);
      _selectedEdgeId = null;
    });
    _saveCanvasState();
  }
  @visibleForTesting
  void toggleSnapToGridForTesting() => setState(() => _snapToGrid = !_snapToGrid);
  @visibleForTesting
  void toggleMinimapForTesting() => setState(() => _showMinimap = !_showMinimap);
  @visibleForTesting
  void toggleZenModeForTesting() => setState(() => _isZenMode = !_isZenMode);

  int _uniqueIdCounter = 0;
  String _generateUniqueId(String prefix) {
    _uniqueIdCounter++;
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_uniqueIdCounter';
  }

  void _loadGridOpacity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getDouble('whiteboard_grid_opacity');
      if (saved != null && mounted) {
        setState(() => _gridOpacity = saved.clamp(0.04, 0.50));
      }
    } catch (_) {}
  }

  void _saveGridOpacity(double val) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('whiteboard_grid_opacity', val);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _loadGridOpacity();
    _nodes = List.from(widget.item.nodes);
    _edges = List.from(widget.item.edges);

    // Auto-migrate legacy whiteboards whose starter nodes were placed at (120, 50)
    // so they are centered at (3000, 3000) with 3000px of space in every direction
    if (_nodes.isNotEmpty) {
      double minX = _nodes.first.x;
      double maxX = _nodes.first.x + _nodes.first.width;
      double minY = _nodes.first.y;
      double maxY = _nodes.first.y + _nodes.first.height;
      for (final n in _nodes) {
        minX = math.min(minX, n.x);
        maxX = math.max(maxX, n.x + n.width);
        minY = math.min(minY, n.y);
        maxY = math.max(maxY, n.y + n.height);
      }
      final contentCenterX = (minX + maxX) / 2;
      final contentCenterY = (minY + maxY) / 2;
      if (contentCenterX < 600 || contentCenterY < 600) {
        final shiftX = (_canvasSize / 2) - contentCenterX;
        final shiftY = (_canvasSize / 2) - contentCenterY;
        _nodes = _nodes.map((n) => n.copyWith(
          x: (n.x + shiftX).clamp(0.0, _canvasSize - n.width),
          y: (n.y + shiftY).clamp(0.0, _canvasSize - n.height),
        )).toList();
      }
    }

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
      if (mounted) {
        if (widget.initialFocusNodeId != null &&
            widget.initialFocusNodeId!.trim().isNotEmpty) {
          _focusNodeByIdOrLabel(widget.initialFocusNodeId!.trim());
        } else if (widget.item.panOffset != Offset.zero) {
          final savedZoom = widget.item.zoomScale.clamp(0.15, 3.0);
          final matrix = Matrix4.identity()
            ..translateByVector3(
              vmath.Vector3(
                widget.item.panOffset.dx,
                widget.item.panOffset.dy,
                0.0,
              ),
            )
            ..scaleByVector3(vmath.Vector3(savedZoom, savedZoom, 1.0));
          _transformationController.value = matrix;
        } else {
          _fitCanvasToContent();
        }
        _saveCanvasState();
      }
    });
  }

  void _focusNodeByIdOrLabel(String query) {
    final lower = query.toLowerCase();
    final target = _nodes.cast<CanvasNode?>().firstWhere(
          (n) =>
              n != null &&
              (n.id == query ||
                  n.id.toLowerCase() == lower ||
                  n.text.trim().toLowerCase() == lower ||
                  n.text.toLowerCase().contains(lower)),
          orElse: () => null,
        );
    if (target == null) {
      _fitCanvasToContent();
      return;
    }
    setState(() {
      _selectedNodeId = target.id;
      _selectedEdgeId = null;
    });
    final size = MediaQuery.sizeOf(context);
    const focusScale = 1.05;
    final centerScreenX = size.width / 2;
    final centerScreenY = (size.height - 80) / 2;
    final transX = centerScreenX - (target.center.dx * focusScale);
    final transY = centerScreenY - (target.center.dy * focusScale);
    final matrix = Matrix4.identity()
      ..translateByVector3(vmath.Vector3(transX, transY, 0.0))
      ..scaleByVector3(vmath.Vector3(focusScale, focusScale, 1.0));
    _animateCanvasToMatrix(matrix);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _workspaceProvider = context.read<WorkspaceProvider>();
  }

  @override
  void dispose() {
    _saveCanvasState();
    _cameraAnimController.dispose();
    _transformationController.dispose();
    _canvasFocusNode.dispose();
    _scaleNotifier.dispose();
    _bottomDockScrollController.dispose();
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
    final matrix = _transformationController.value;
    final zoom = matrix.getMaxScaleOnAxis().clamp(0.15, 3.0);
    final translation = matrix.getTranslation();
    final updated = widget.item.copyWith(
      nodes: _nodes,
      edges: _edges,
      zoomScale: zoom,
      panOffset: Offset(translation.x, translation.y),
      updatedAt: DateTime.now(),
    );
    try {
      final provider = _workspaceProvider ?? (mounted ? context.read<WorkspaceProvider>() : null);
      provider?.saveItem(updated);
    } catch (_) {}
  }

  bool _canPopWhiteboard() {
    return !_showShapesMenu &&
        !_showMinimap &&
        !_showGridOpacitySlider &&
        _connectingFromNodeId == null &&
        _selectedNodeId == null &&
        _selectedEdgeId == null;
  }

  void _handleWhiteboardBack() {
    if (_showShapesMenu || _showMinimap || _showGridOpacitySlider) {
      setState(() {
        _showShapesMenu = false;
        _showMinimap = false;
        _showGridOpacitySlider = false;
      });
      return;
    }
    if (_connectingFromNodeId != null) {
      setState(() {
        _connectingFromNodeId = null;
      });
      return;
    }
    if (_selectedNodeId != null || _selectedEdgeId != null) {
      setState(() {
        _selectedNodeId = null;
        _selectedEdgeId = null;
      });
      return;
    }
    _saveCanvasState();
    Navigator.of(context).pop();
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

  /// Converts the center of the current screen/viewport into exact canvas scene coordinates.
  Offset _getCurrentViewportCenterScene() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? MediaQuery.sizeOf(context);
    final viewportCenter = Offset(size.width / 2, (size.height - 80) / 2);
    try {
      return _transformationController.toScene(viewportCenter);
    } catch (_) {
      final matrix = _transformationController.value;
      final scale = matrix.getMaxScaleOnAxis();
      final trans = matrix.getTranslation();
      if (scale > 0) {
        return Offset(
          (viewportCenter.dx - trans.x) / scale,
          (viewportCenter.dy - trans.y) / scale,
        );
      }
      return const Offset(_canvasSize / 2, _canvasSize / 2);
    }
  }

  // ================= 2. Node Operations & Context Actions =================
  void _addNode(
    CanvasNodeType shapeType, {
    Offset? position,
    String? imagePath,
    double? customWidth,
    double? customHeight,
    String? linkedNoteId,
    String? customText,
    String? customPaletteId,
    bool autoEdit = true,
  }) {
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
      case CanvasNodeType.specCard:
        paletteId = 'cyan';
        break;
      case CanvasNodeType.process:
      default:
        paletteId = 'lime';
        break;
    }
    if (customPaletteId != null && customPaletteId.isNotEmpty) {
      paletteId = customPaletteId;
    }

    final double width = customWidth ??
        (shapeType == CanvasNodeType.decision
            ? 140
            : shapeType == CanvasNodeType.sticky
                ? 130
                : shapeType == CanvasNodeType.specCard
                    ? 220
                    : shapeType == CanvasNodeType.image
                        ? 160
                        : 130);
    final double height = customHeight ??
        (shapeType == CanvasNodeType.decision
            ? 64
            : shapeType == CanvasNodeType.sticky
                ? 120
                : shapeType == CanvasNodeType.specCard
                    ? 148
                    : shapeType == CanvasNodeType.image
                        ? 160
                        : shapeType == CanvasNodeType.textOnly
                            ? 42
                            : 52);

    double x;
    double y;
    if (position != null) {
      x = position.dx;
      y = position.dy;
    } else {
      final centerScene = _getCurrentViewportCenterScene();
      x = centerScene.dx - (width / 2);
      y = centerScene.dy - (height / 2);
    }

    final newNode = CanvasNode(
      id: _generateUniqueId('node'),
      text: customText ??
          (shapeType == CanvasNodeType.image
              ? ''
              : shapeType == CanvasNodeType.specCard
                  ? 'Spec Overview\n- Goal: \n- Edge cases: '
                  : shapeType.label),
      shapeType: shapeType,
      x: x.clamp(0.0, _canvasSize - width),
      y: y.clamp(0.0, _canvasSize - height),
      width: width,
      height: height,
      paletteId: paletteId,
      imagePath: imagePath,
      linkedNoteId: linkedNoteId,
    );

    setState(() {
      _nodes.add(newNode);
      _selectedNodeId = newNode.id;
      _selectedEdgeId = null;
    });
    _saveCanvasState();

    if (autoEdit &&
        linkedNoteId == null &&
        (shapeType == CanvasNodeType.textOnly ||
            shapeType == CanvasNodeType.sticky ||
            shapeType == CanvasNodeType.specCard)) {
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
    final original = _nodes.cast<CanvasNode?>().firstWhere(
          (n) => n?.id == _selectedNodeId,
          orElse: () => null,
        );
    if (original == null) return;
    _history.recordSnapshot(_nodes, _edges);
    HapticFeedback.lightImpact();

    final cloned = original.copyWith(
      text: original.text,
      x: (original.x + 20).clamp(0.0, _canvasSize - original.width),
      y: (original.y + 20).clamp(0.0, _canvasSize - original.height),
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
      linkedNoteId: cloned.linkedNoteId,
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
        newX = (parent.x + parent.width + 75.0).clamp(0.0, _canvasSize - parent.width);
        newY = parent.y;
        oppositePort = 'left';
        break;
      case 'bottom':
        newX = parent.x;
        newY = (parent.y + parent.height + 75.0).clamp(0.0, _canvasSize - parent.height);
        oppositePort = 'top';
        break;
      case 'left':
        newX = (parent.x - parent.width - 75.0).clamp(0.0, _canvasSize - parent.width);
        newY = parent.y;
        oppositePort = 'right';
        break;
      case 'top':
        newX = parent.x;
        newY = (parent.y - parent.height - 75.0).clamp(0.0, _canvasSize - parent.height);
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

    // 1. Build adjacency maps
    final nodeMap = {for (var n in _nodes) n.id: n};
    final outEdges = <String, List<String>>{for (var n in _nodes) n.id: []};
    final inEdges = <String, List<String>>{for (var n in _nodes) n.id: []};

    for (final e in _edges) {
      if (nodeMap.containsKey(e.fromNodeId) && nodeMap.containsKey(e.toNodeId)) {
        outEdges[e.fromNodeId]!.add(e.toNodeId);
        inEdges[e.toNodeId]!.add(e.fromNodeId);
      }
    }

    // 2. Cycle-safe DAG detection: identify back-edges using DFS
    // Flowcharts often contain feedback/retry loops. Cycle back-edges must not cause infinite loops.
    final visited = <String>{};
    final inStack = <String>{};
    final backEdges = <(String, String)>{};

    void dfs(String u) {
      visited.add(u);
      inStack.add(u);
      for (final v in outEdges[u] ?? []) {
        if (inStack.contains(v)) {
          backEdges.add((u, v));
        } else if (!visited.contains(v)) {
          dfs(v);
        }
      }
      inStack.remove(u);
    }

    final allRoots = _nodes.where((n) => inEdges[n.id]!.isEmpty).map((n) => n.id).toList();
    for (final r in allRoots) {
      if (!visited.contains(r)) dfs(r);
    }
    for (final n in _nodes) {
      if (!visited.contains(n.id)) dfs(n.id);
    }

    // 3. Build pure DAG adjacency excluding back-edges
    final dagOut = <String, List<String>>{for (var n in _nodes) n.id: []};
    final dagInDegree = <String, int>{for (var n in _nodes) n.id: 0};

    for (final e in _edges) {
      if (nodeMap.containsKey(e.fromNodeId) && nodeMap.containsKey(e.toNodeId)) {
        if (!backEdges.contains((e.fromNodeId, e.toNodeId))) {
          dagOut[e.fromNodeId]!.add(e.toNodeId);
          dagInDegree[e.toNodeId] = (dagInDegree[e.toNodeId] ?? 0) + 1;
        }
      }
    }

    // 4. Topological longest-path layering via Kahn's algorithm
    final levels = <String, int>{};
    final queue = <String>[];
    for (final n in _nodes) {
      if (dagInDegree[n.id] == 0) {
        queue.add(n.id);
        levels[n.id] = 0;
      }
    }

    if (queue.isEmpty && _nodes.isNotEmpty) {
      queue.add(_nodes.first.id);
      levels[_nodes.first.id] = 0;
    }

    final remainingInDegree = Map<String, int>.from(dagInDegree);
    int safetyCounter = 0;
    final maxSteps = _nodes.length * 3;

    while (queue.isNotEmpty && safetyCounter < maxSteps) {
      safetyCounter++;
      final curr = queue.removeAt(0);
      final currLvl = levels[curr] ?? 0;

      for (final next in dagOut[curr] ?? []) {
        final newLvl = math.max(levels[next] ?? 0, currLvl + 1);
        levels[next] = newLvl;

        remainingInDegree[next] = (remainingInDegree[next] ?? 1) - 1;
        if (remainingInDegree[next]! <= 0 && !queue.contains(next)) {
          queue.add(next);
        }
      }
    }

    for (final n in _nodes) {
      levels.putIfAbsent(n.id, () => 0);
    }

    // 5. Group nodes by level
    final levelGroups = <int, List<String>>{};
    levels.forEach((nodeId, lvl) {
      levelGroups.putIfAbsent(lvl, () => []).add(nodeId);
    });

    final sortedLevels = levelGroups.keys.toList()..sort();

    // 6. Barycenter heuristic: sort nodes within each column by average parent position to minimize crossings
    final nodeIndexInLevel = <String, double>{};
    for (final lvl in sortedLevels) {
      final group = levelGroups[lvl]!;
      if (lvl > 0) {
        group.sort((a, b) {
          final parentsA = inEdges[a] ?? [];
          final parentsB = inEdges[b] ?? [];

          double scoreA = 0;
          if (parentsA.isNotEmpty) {
            final valid = parentsA.where((p) => nodeIndexInLevel.containsKey(p)).toList();
            if (valid.isNotEmpty) {
              scoreA = valid.map((p) => nodeIndexInLevel[p]!).reduce((v, e) => v + e) / valid.length;
            }
          }
          double scoreB = 0;
          if (parentsB.isNotEmpty) {
            final valid = parentsB.where((p) => nodeIndexInLevel.containsKey(p)).toList();
            if (valid.isNotEmpty) {
              scoreB = valid.map((p) => nodeIndexInLevel[p]!).reduce((v, e) => v + e) / valid.length;
            }
          }
          return scoreA.compareTo(scoreB);
        });
      }
      for (int i = 0; i < group.length; i++) {
        nodeIndexInLevel[group[i]] = i.toDouble();
      }
    }

    // 7. Dynamic dimensions and spacing (no node overlaps)
    const double colGap = 84.0;
    const double rowGap = 44.0;

    final colWidths = <int, double>{};
    final colHeights = <int, double>{};

    for (final lvl in sortedLevels) {
      final group = levelGroups[lvl]!;
      double maxW = 0;
      double totalH = 0;
      for (int i = 0; i < group.length; i++) {
        final node = nodeMap[group[i]]!;
        maxW = math.max(maxW, node.width);
        totalH += node.height;
        if (i < group.length - 1) totalH += rowGap;
      }
      colWidths[lvl] = math.max(maxW, 140.0);
      colHeights[lvl] = totalH;
    }

    double totalGraphWidth = 0;
    for (int i = 0; i < sortedLevels.length; i++) {
      totalGraphWidth += colWidths[sortedLevels[i]]!;
      if (i < sortedLevels.length - 1) totalGraphWidth += colGap;
    }

    // 8. Place nodes symmetrically centered in the EXACT location where the user's design is right now
    double currentMinX = _nodes.first.x;
    double currentMaxX = _nodes.first.x + _nodes.first.width;
    double currentMinY = _nodes.first.y;
    double currentMaxY = _nodes.first.y + _nodes.first.height;
    for (final n in _nodes) {
      currentMinX = math.min(currentMinX, n.x);
      currentMaxX = math.max(currentMaxX, n.x + n.width);
      currentMinY = math.min(currentMinY, n.y);
      currentMaxY = math.max(currentMaxY, n.y + n.height);
    }
    final currentCenterX = (currentMinX + currentMaxX) / 2;
    final currentCenterY = (currentMinY + currentMaxY) / 2;

    double maxTotalHeight = 0;
    for (final h in colHeights.values) {
      maxTotalHeight = math.max(maxTotalHeight, h);
    }

    final targetCenterX = currentCenterX.clamp(totalGraphWidth / 2 + 50.0, _canvasSize - totalGraphWidth / 2 - 50.0);
    final targetCenterY = currentCenterY.clamp(maxTotalHeight / 2 + 50.0, _canvasSize - maxTotalHeight / 2 - 50.0);

    final startX = targetCenterX - (totalGraphWidth / 2);
    final centerY = targetCenterY;

    final updatedNodes = <CanvasNode>[];
    double currentX = startX;

    for (final lvl in sortedLevels) {
      final group = levelGroups[lvl]!;
      final colH = colHeights[lvl] ?? 0;
      final colW = colWidths[lvl] ?? 140;
      double currentY = centerY - (colH / 2);

      for (final nodeId in group) {
        final node = nodeMap[nodeId]!;
        final nodeX = currentX + ((colW - node.width) / 2);
        final nodeY = currentY;

        updatedNodes.add(node.copyWith(
          x: nodeX.clamp(0.0, _canvasSize - node.width),
          y: nodeY.clamp(0.0, _canvasSize - node.height),
        ));

        currentY += node.height + rowGap;
      }

      currentX += colW + colGap;
    }

    final updatedNodeMap = {for (var n in updatedNodes) n.id: n};

    // 9. Intelligent geometric edge port assignment
    final updatedEdges = _edges.map((e) {
      final from = updatedNodeMap[e.fromNodeId];
      final to = updatedNodeMap[e.toNodeId];
      if (from == null || to == null) return e;

      final fromLvl = levels[from.id] ?? 0;
      final toLvl = levels[to.id] ?? 0;

      if (toLvl > fromLvl) {
        // Forward flow
        return e.copyWith(fromPort: 'right', toPort: 'left');
      } else if (toLvl == fromLvl) {
        // Same column
        if (from.y < to.y) {
          return e.copyWith(fromPort: 'bottom', toPort: 'top');
        } else {
          return e.copyWith(fromPort: 'top', toPort: 'bottom');
        }
      } else {
        // Backward / loopback: route cleanly around bottom or top
        final avgY = (from.y + to.y) / 2;
        if (avgY > centerY) {
          return e.copyWith(fromPort: 'bottom', toPort: 'bottom');
        } else {
          return e.copyWith(fromPort: 'top', toPort: 'top');
        }
      }
    }).toList();

    setState(() {
      _nodes = updatedNodes;
      _edges = updatedEdges;
    });
    _saveCanvasState();

    _fitCanvasToContent();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Flowchart auto-arranged neatly in place'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Automatically fits and centers all flowchart nodes in the viewport
  void _fitCanvasToContent() {
    final size = MediaQuery.sizeOf(context);
    if (_nodes.isEmpty) {
      final transX = (size.width / 2) - (_canvasSize / 2);
      final transY = (size.height / 2) - (_canvasSize / 2);
      _animateCanvasToMatrix(Matrix4.translationValues(transX, transY, 0.0));
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

    const padding = 120.0;
    final contentW = math.max((maxX - minX) + (padding * 2), 220.0);
    final contentH = math.max((maxY - minY) + (padding * 2), 220.0);

    final scaleX = size.width / contentW;
    final scaleY = (size.height - 220) / contentH;
    final fitScale = math.min(scaleX, scaleY).clamp(0.4, 1.15);

    final centerScreenX = size.width / 2;
    final centerScreenY = (size.height - 80) / 2;
    final centerContentX = (minX + maxX) / 2;
    final centerContentY = (minY + maxY) / 2;

    final transX = centerScreenX - (centerContentX * fitScale);
    final transY = centerScreenY - (centerContentY * fitScale);

    final matrix = Matrix4.identity()
      ..translateByVector3(vmath.Vector3(transX, transY, 0.0))
      ..scaleByVector3(vmath.Vector3(fitScale, fitScale, 1.0));

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

  void _changeNodeShape(CanvasNode node, CanvasNodeType newShapeType) {
    if (node.shapeType == newShapeType) return;
    _history.recordSnapshot(_nodes, _edges);
    HapticFeedback.selectionClick();

    final double newWidth = newShapeType == CanvasNodeType.decision
        ? 140
        : newShapeType == CanvasNodeType.sticky
            ? 130
            : newShapeType == CanvasNodeType.specCard
                ? 220
                : newShapeType == CanvasNodeType.connector
                    ? 60
                    : newShapeType == CanvasNodeType.image
                        ? 160
                        : 130;
    final double newHeight = newShapeType == CanvasNodeType.decision
        ? 64
        : newShapeType == CanvasNodeType.sticky
            ? 120
            : newShapeType == CanvasNodeType.specCard
                ? 148
                : newShapeType == CanvasNodeType.connector
                    ? 60
                    : newShapeType == CanvasNodeType.image
                        ? 120
                        : newShapeType == CanvasNodeType.textOnly
                            ? 42
                            : 52;

    setState(() {
      final index = _nodes.indexWhere((n) => n.id == node.id);
      if (index >= 0) {
        final centerX = node.x + (node.width / 2);
        final centerY = node.y + (node.height / 2);
        final newX = (centerX - (newWidth / 2)).clamp(0.0, _canvasSize - newWidth);
        final newY = (centerY - (newHeight / 2)).clamp(0.0, _canvasSize - newHeight);

        _nodes[index] = node.copyWith(
          shapeType: newShapeType,
          width: newWidth,
          height: newHeight,
          x: newX,
          y: newY,
        );
      }
    });
    _saveCanvasState();
  }

  void _insertNodeOnEdge(CanvasEdge edge, CanvasNodeType shapeType) {
    final from = _nodes.cast<CanvasNode?>().firstWhere((n) => n?.id == edge.fromNodeId, orElse: () => null);
    final to = _nodes.cast<CanvasNode?>().firstWhere((n) => n?.id == edge.toNodeId, orElse: () => null);
    if (from == null || to == null) return;

    _history.recordSnapshot(_nodes, _edges);
    HapticFeedback.lightImpact();

    final ports = _resolveEdgePorts(edge, from, to);
    final midX = (ports.start.dx + ports.end.dx) / 2;
    final midY = (ports.start.dy + ports.end.dy) / 2;

    final double width = shapeType == CanvasNodeType.decision
        ? 140
        : shapeType == CanvasNodeType.sticky
            ? 130
            : shapeType == CanvasNodeType.connector
                ? 60
                : 130;
    final double height = shapeType == CanvasNodeType.decision
        ? 64
        : shapeType == CanvasNodeType.sticky
            ? 120
            : shapeType == CanvasNodeType.connector
                ? 60
                : 52;

    String paletteId = 'lime';
    switch (shapeType) {
      case CanvasNodeType.decision:
        paletteId = 'lavender';
        break;
      case CanvasNodeType.startEnd:
        paletteId = 'coral';
        break;
      case CanvasNodeType.inputOutput:
        paletteId = 'amber';
        break;
      case CanvasNodeType.connector:
        paletteId = 'cyan';
        break;
      default:
        paletteId = 'lime';
        break;
    }

    final newNode = CanvasNode(
      id: _generateUniqueId('node'),
      text: shapeType.label,
      shapeType: shapeType,
      x: (midX - width / 2).clamp(0.0, _canvasSize - width),
      y: (midY - height / 2).clamp(0.0, _canvasSize - height),
      width: width,
      height: height,
      paletteId: paletteId,
    );

    final edge1 = CanvasEdge(
      id: _generateUniqueId('edge'),
      fromNodeId: edge.fromNodeId,
      toNodeId: newNode.id,
      fromPort: edge.fromPort,
      toPort: 'top',
    );

    final edge2 = CanvasEdge(
      id: _generateUniqueId('edge'),
      fromNodeId: newNode.id,
      toNodeId: edge.toNodeId,
      fromPort: 'bottom',
      toPort: edge.toPort,
      label: edge.label,
    );

    setState(() {
      _edges.removeWhere((e) => e.id == edge.id);
      _nodes.add(newNode);
      _edges.add(edge1);
      _edges.add(edge2);
      _selectedNodeId = newNode.id;
      _selectedEdgeId = null;
    });
    _saveCanvasState();
  }

  void _editNodeText(CanvasNode node) {
    final controller = TextEditingController(text: node.text);
    final isSpec = node.shapeType == CanvasNodeType.specCard;
    AppFloatingDialog.showCustom(
      context: context,
      builder: (dialogCtx) {
        final tokens = dialogCtx.tokens;
        final isDark = tokens.isDark;
        final viewInsets = MediaQuery.viewInsetsOf(dialogCtx);

        return AnimatedPadding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          duration: AppSpacing.durationFast,
          curve: AppSpacing.curveStandard,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
                decoration: BoxDecoration(
                  color: tokens.surfacePrimary,
                  borderRadius: AppSpacing.roundedModal,
                  boxShadow: AppSpacing.elevModal(isDark),
                  border: Border.all(
                    color: tokens.borderSubtle.withValues(alpha: isDark ? 0.35 : 0.6),
                    width: 0.8,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Material(
                  color: tokens.surfacePrimary,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          isSpec ? 'Edit Spec Card' : 'Edit Node Text',
                          style: AppTypography.titleSm(
                            color: tokens.textPrimary,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        TextField(
                          controller: controller,
                          autofocus: true,
                          maxLines: isSpec
                              ? 6
                              : node.shapeType == CanvasNodeType.sticky
                                  ? 4
                                  : 1,
                          style: AppTypography.body(color: tokens.textPrimary),
                          decoration: InputDecoration(
                            hintText: isSpec
                                ? 'Spec summary, acceptance criteria, edge cases...'
                                : 'Enter node label...',
                            hintStyle: AppTypography.body(color: tokens.textTertiary),
                            filled: true,
                            fillColor: tokens.canvasSunken,
                            border: OutlineInputBorder(
                              borderRadius: AppSpacing.roundedSm,
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: isSpec
                              ? null
                              : (val) {
                                  _saveNodeText(node, val);
                                  Navigator.of(dialogCtx).pop();
                                },
                        ),
                        const SizedBox(height: AppSpacing.s5),
                        if (isSpec || node.shapeType == CanvasNodeType.sticky) ...[
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: tokens.borderSubtle),
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppSpacing.roundedPill,
                              ),
                            ),
                            onPressed: () {
                              _saveNodeText(node, controller.text);
                              Navigator.of(dialogCtx).pop();
                              final updatedNode = _nodes.firstWhere(
                                (n) => n.id == node.id,
                                orElse: () => node.copyWith(text: controller.text.trim()),
                              );
                              _openOrPromoteSpecNode(updatedNode);
                            },
                            icon: const TackIcon(TackIcons.notes, size: 15),
                            label: Text(
                              node.linkedNoteId != null ? 'Open Note' : 'Open as Note',
                              style: AppTypography.label(color: tokens.textPrimary),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s3),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(46),
                                  side: BorderSide(color: tokens.borderSubtle),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: AppSpacing.roundedPill,
                                  ),
                                ),
                                onPressed: () => Navigator.of(dialogCtx).pop(),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s3),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(46),
                                  backgroundColor: tokens.actionPrimary,
                                  foregroundColor: tokens.actionPrimaryFg,
                                  elevation: 0,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: AppSpacing.roundedPill,
                                  ),
                                ),
                                onPressed: () {
                                  _saveNodeText(node, controller.text);
                                  Navigator.of(dialogCtx).pop();
                                },
                                child: const Text('Save'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Opens a Spec Card's linked note in [NoteEditorScreen], or promotes an unlinked
  /// Spec Card / Sticky node into a full bi-directionally linked [TextNote].
  Future<void> _openOrPromoteSpecNode(CanvasNode node) async {
    final workspace = context.read<WorkspaceProvider>();
    if (node.linkedNoteId != null) {
      final existing = workspace.getItemById(node.linkedNoteId!);
      if (existing != null && (existing is TextNote || existing is StickyNote)) {
        _saveCanvasState();
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => NoteEditorScreen(item: existing)),
        );
        if (mounted) setState(() {});
        return;
      }
    }

    // Promote unlinked Spec Card / Sticky node to a full Markdown note linked to this board!
    final lines = node.text.trim().split('\n');
    final derivedTitle = lines.isNotEmpty && lines.first.trim().isNotEmpty
        ? lines.first.replaceFirst(RegExp(r'^#+\s*'), '').trim()
        : '${widget.item.title} Spec';
    final bodyLines = lines.length > 1 ? lines.sublist(1).join('\n').trim() : '';
    final embedRef = '![[${widget.item.title}#${node.id}]]';
    final initialBody = bodyLines.isNotEmpty
        ? '$bodyLines\n\n$embedRef\n'
        : '## Spec Details\n- [ ] Define requirements\n\n$embedRef\n';

    final created = await workspace.createQuickItem(
      title: derivedTitle,
      type: ItemType.note,
      paletteId: node.paletteId,
      content: initialBody,
    );

    _history.recordSnapshot(_nodes, _edges);
    setState(() {
      final idx = _nodes.indexWhere((n) => n.id == node.id);
      if (idx >= 0) {
        _nodes[idx] = _nodes[idx].copyWith(
          shapeType: CanvasNodeType.specCard,
          linkedNoteId: created.id,
          text: derivedTitle,
          width: math.max(_nodes[idx].width, 220),
          height: math.max(_nodes[idx].height, 148),
        );
      }
    });
    _saveCanvasState();

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NoteEditorScreen(item: created)),
    );
    if (mounted) setState(() {});
  }

  /// Bottom sheet to create a new Spec Card on the board or pin an existing Note/Sticky.
  void _showAddSpecCardSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workspace = context.read<WorkspaceProvider>();
    final pinnableNotes = workspace.rawItems
        .where((i) => !i.isTrash && (i is TextNote || i is StickyNote))
        .toList();

    AppBottomSheet.show<void>(
      context: context,
      builder: (sheetCtx) {
        String search = '';
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered = search.trim().isEmpty
                ? pinnableNotes
                : pinnableNotes
                    .where((n) =>
                        n.title.toLowerCase().contains(search.toLowerCase()) ||
                        n.getSummary().toLowerCase().contains(search.toLowerCase()))
                    .toList();
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.s5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.pastelCyanLight.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const TackIcon(
                          TackIcons.notes,
                          size: 18,
                          color: AppColors.pastelCyanLight,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Canvas Spec Card',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              'Write a structured spec on the board or pin a live note',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 12,
                                letterSpacing: -0.2,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () {
                        Navigator.of(sheetCtx).pop();
                        _addNode(CanvasNodeType.specCard);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.pastelCyanDark.withValues(alpha: 0.35)
                              : AppColors.pastelCyanLight.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.pastelCyanLight.withValues(alpha: 0.55),
                          ),
                        ),
                        child: Row(
                          children: [
                            const TackIcon(
                              TackIcons.plus,
                              size: 18,
                              color: AppColors.pastelCyanLight,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'New Blank Spec Card on Board',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (pinnableNotes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'OR PIN AN EXISTING NOTE',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        onChanged: (v) => setModalState(() => search = v),
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13.5,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Filter notes...',
                          isDense: true,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.all(10),
                            child: TackIcon(TackIcons.search, size: 16),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.darkSurfaceAlt
                              : const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 230),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (_, idx) {
                            final note = filtered[idx];
                            final pal = AppColors.getPaletteById(note.paletteId);
                            return InkWell(
                              onTap: () {
                                Navigator.of(sheetCtx).pop();
                                _addNode(
                                  CanvasNodeType.specCard,
                                  linkedNoteId: note.id,
                                  customText: note.title,
                                  customPaletteId: note.paletteId,
                                  autoEdit: false,
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurfaceAlt
                                      : const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: pal.lightColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            note.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: AppTypography.fontFamily,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.3,
                                              color: isDark
                                                  ? AppColors.darkTextPrimary
                                                  : AppColors.lightTextPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            note.getSummary(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: AppTypography.fontFamily,
                                              fontSize: 11.5,
                                              color: isDark
                                                  ? AppColors.darkTextMuted
                                                  : AppColors.lightTextMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const TackIcon(TackIcons.pin, size: 15),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
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
      final waypoints = _CanvasEdgesPainter.computeWaypoints(
        ports.start,
        edge.fromPort,
        ports.end,
        edge.toPort,
      );

      bool hit = false;
      for (int i = 0; i < waypoints.length - 1; i++) {
        if (_distToSegment(localPos, waypoints[i], waypoints[i + 1]) <= 22.0) {
          hit = true;
          break;
        }
      }

      if (hit) {
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
    AppFloatingDialog.showCustom(
      context: context,
      builder: (dialogCtx) {
        final tokens = dialogCtx.tokens;
        final isDark = tokens.isDark;
        final viewInsets = MediaQuery.viewInsetsOf(dialogCtx);

        return AnimatedPadding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          duration: AppSpacing.durationFast,
          curve: AppSpacing.curveStandard,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
                decoration: BoxDecoration(
                  color: tokens.surfacePrimary,
                  borderRadius: AppSpacing.roundedModal,
                  boxShadow: AppSpacing.elevModal(isDark),
                  border: Border.all(
                    color: tokens.borderSubtle.withValues(alpha: isDark ? 0.35 : 0.6),
                    width: 0.8,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Material(
                  color: tokens.surfacePrimary,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Connector Line',
                          style: AppTypography.titleSm(
                            color: tokens.textPrimary,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        TextField(
                          controller: controller,
                          autofocus: true,
                          style: AppTypography.body(color: tokens.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'e.g. Yes, No, Approved',
                            hintStyle: AppTypography.body(color: tokens.textTertiary),
                            filled: true,
                            fillColor: tokens.canvasSunken,
                            border: OutlineInputBorder(
                              borderRadius: AppSpacing.roundedSm,
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        Wrap(
                          spacing: AppSpacing.s2,
                          children: [
                            ActionChip(
                              label: const Text('Yes'),
                              onPressed: () => controller.text = 'Yes',
                            ),
                            ActionChip(
                              label: const Text('No'),
                              onPressed: () => controller.text = 'No',
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s6),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: tokens.danger,
                                side: BorderSide(color: tokens.danger.withValues(alpha: 0.4)),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppSpacing.roundedPill,
                                ),
                              ),
                              icon: TackIcon(TackIcons.trash, size: 16, color: tokens.danger),
                              label: const Text('Delete'),
                              onPressed: () {
                                _history.recordSnapshot(_nodes, _edges);
                                setState(() {
                                  _edges.removeWhere((e) => e.id == edge.id);
                                  _selectedEdgeId = null;
                                });
                                _saveCanvasState();
                                Navigator.of(dialogCtx).pop();
                              },
                            ),
                            const Spacer(),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tokens.actionPrimary,
                                foregroundColor: tokens.actionPrimaryFg,
                                elevation: 0,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppSpacing.roundedPill,
                                ),
                              ),
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
                                Navigator.of(dialogCtx).pop();
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ================= 4. Image Tool Picker =================
  Future<void> _pickAndInsertImage() async {
    try {
      // Pre-capture the exact center of what the user is currently seeing on screen
      final targetCenter = _getCurrentViewportCenterScene();

      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        String savedPath = file.path;
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final targetFileName = 'wb_img_${DateTime.now().millisecondsSinceEpoch}_${file.name}';
          final savedImage = await File(file.path).copy('${appDir.path}/$targetFileName');
          savedPath = savedImage.path;
        } catch (_) {}

        double imgWidth = 240;
        double imgHeight = 160;
        try {
          final bytes = await File(savedPath).readAsBytes();
          final decoded = await decodeImageFromList(bytes);
          if (decoded.width > 0 && decoded.height > 0) {
            final aspect = decoded.width / decoded.height;
            if (aspect >= 1.0) {
              imgWidth = 240;
              imgHeight = (240 / aspect).clamp(80.0, 360.0);
            } else {
              imgHeight = 240;
              imgWidth = (240 * aspect).clamp(80.0, 360.0);
            }
          }
        } catch (_) {}

        final posX = (targetCenter.dx - (imgWidth / 2)).clamp(0.0, _canvasSize - imgWidth);
        final posY = (targetCenter.dy - (imgHeight / 2)).clamp(0.0, _canvasSize - imgHeight);

        _addNode(
          CanvasNodeType.image,
          position: Offset(posX, posY),
          imagePath: savedPath,
          customWidth: imgWidth,
          customHeight: imgHeight,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load image: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ================= 5. Share & Multi-Format Export Pipeline (PNG, JPG, PDF) =================

  Future<Uint8List> _renderCanvasToPngBytes({
    double pixelRatio = 2.0,
    bool transparentBg = false,
    String bgOption = 'dots',
  }) async {
    // 1. Calculate content bounding box across all nodes
    double minX = 0;
    double minY = 0;
    double maxX = 800;
    double maxY = 600;

    if (_nodes.isNotEmpty) {
      minX = _nodes.first.x;
      maxX = _nodes.first.x + _nodes.first.width;
      minY = _nodes.first.y;
      maxY = _nodes.first.y + _nodes.first.height;

      for (final node in _nodes) {
        minX = math.min(minX, node.x);
        maxX = math.max(maxX, node.x + node.width);
        minY = math.min(minY, node.y);
        maxY = math.max(maxY, node.y + node.height);
      }
    }

    const double padding = 60.0;
    final double contentW = (maxX - minX) + (padding * 2);
    final double contentH = (maxY - minY) + (padding * 2);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, contentW * pixelRatio, contentH * pixelRatio));
    canvas.scale(pixelRatio, pixelRatio);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Draw background only if not transparent
    if (!transparentBg) {
      Color solidBg;
      switch (bgOption) {
        case 'white':
          solidBg = Colors.white;
          break;
        case 'dark':
          solidBg = const Color(0xFF0F1015);
          break;
        case 'theme':
        case 'dots':
        case 'grid':
        default:
          solidBg = isDark ? const Color(0xFF121316) : Colors.white;
          break;
      }

      final bgPaint = Paint()..color = solidBg;
      canvas.drawRect(Rect.fromLTWH(0, 0, contentW, contentH), bgPaint);

      if (bgOption == 'dots') {
        final isWhiteOrLight = solidBg == Colors.white || (!isDark && bgOption != 'dark');
        final dotPaint = Paint()
          ..color = isWhiteOrLight
              ? Colors.black.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.10)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round;
        const step = 28.0;
        final points = <Offset>[];
        for (double x = 0; x <= contentW; x += step) {
          for (double y = 0; y <= contentH; y += step) {
            points.add(Offset(x, y));
          }
        }
        canvas.drawPoints(ui.PointMode.points, points, dotPaint);
      } else if (bgOption == 'grid') {
        final isWhiteOrLight = solidBg == Colors.white || (!isDark && bgOption != 'dark');
        final gridPaint = Paint()
          ..color = isWhiteOrLight ? const Color(0xFFE2E8F0) : const Color(0xFF252730)
          ..strokeWidth = 1.0;
        const step = 28.0;
        for (double x = 0; x <= contentW; x += step) {
          canvas.drawLine(Offset(x, 0), Offset(x, contentH), gridPaint);
        }
        for (double y = 0; y <= contentH; y += step) {
          canvas.drawLine(Offset(0, y), Offset(contentW, y), gridPaint);
        }
      }
    }

    // Offset canvas so all nodes align with margin
    canvas.save();
    canvas.translate(padding - minX, padding - minY);

    // Draw connector edges & arrows
    final edgesPainter = _CanvasEdgesPainter(
      nodes: _nodes,
      edges: _edges,
      selectedEdgeId: null,
      isDark: isDark,
    );
    edgesPainter.paint(canvas, Size(_canvasSize, _canvasSize));

    // Preload image assets for any image nodes
    final loadedImages = <String, ui.Image>{};
    for (final node in _nodes) {
      if (node.shapeType == CanvasNodeType.image && node.imagePath != null && node.imagePath!.isNotEmpty) {
        final file = File(node.imagePath!);
        if (await file.exists()) {
          try {
            final bytes = await file.readAsBytes();
            final codec = await ui.instantiateImageCodec(bytes);
            final frame = await codec.getNextFrame();
            loadedImages[node.id] = frame.image;
          } catch (_) {}
        }
      }
    }

    // Draw each flowchart node
    for (final node in _nodes) {
      _drawNodeOnCanvas(canvas, node, isDark, loadedImages[node.id]);
    }

    canvas.restore();

    final picture = recorder.endRecording();
    final image = await picture.toImage((contentW * pixelRatio).toInt(), (contentH * pixelRatio).toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to generate canvas image bytes');
    }
    return byteData.buffer.asUint8List();
  }

  void _drawNodeOnCanvas(Canvas canvas, CanvasNode node, bool isDark, [ui.Image? nodeImage]) {
    final palette = AppColors.getPaletteById(node.paletteId);
    final Color fillColor = isDark ? palette.darkColor.withValues(alpha: 0.6) : palette.softBackground;
    final Color strokeColor = palette.lightColor;

    final fillPaint = Paint()..color = fillColor..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(node.x, node.y, node.width, node.height);

    switch (node.shapeType) {
      case CanvasNodeType.startEnd:
        final rrect = RRect.fromRectAndRadius(rect, Radius.circular(node.height / 2));
        canvas.drawRRect(rrect, fillPaint);
        canvas.drawRRect(rrect, strokePaint);
        break;

      case CanvasNodeType.decision:
        final path = Path()
          ..moveTo(node.x + node.width / 2, node.y)
          ..lineTo(node.x + node.width, node.y + node.height / 2)
          ..lineTo(node.x + node.width / 2, node.y + node.height)
          ..lineTo(node.x, node.y + node.height / 2)
          ..close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        break;

      case CanvasNodeType.inputOutput:
        const slant = 14.0;
        final path = Path()
          ..moveTo(node.x + slant, node.y)
          ..lineTo(node.x + node.width, node.y)
          ..lineTo(node.x + node.width - slant, node.y + node.height)
          ..lineTo(node.x, node.y + node.height)
          ..close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        break;

      case CanvasNodeType.sticky:
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
        canvas.drawRRect(rrect, fillPaint);
        canvas.drawRRect(rrect, strokePaint);
        // Draw top tape accent for sticky note node
        final tapePaint = Paint()
          ..color = strokeColor.withValues(alpha: 0.45)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(node.x + node.width / 2, node.y + 4), width: 32, height: 6),
            const Radius.circular(3),
          ),
          tapePaint,
        );
        break;

      case CanvasNodeType.connector:
        canvas.drawCircle(Offset(node.x + node.width / 2, node.y + node.height / 2), node.width / 2, fillPaint);
        canvas.drawCircle(Offset(node.x + node.width / 2, node.y + node.height / 2), node.width / 2, strokePaint);
        break;

      case CanvasNodeType.textOnly:
        break;

      case CanvasNodeType.image:
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
        if (nodeImage != null) {
          canvas.save();
          canvas.clipRRect(rrect);
          final src = Rect.fromLTWH(0, 0, nodeImage.width.toDouble(), nodeImage.height.toDouble());
          canvas.drawImageRect(nodeImage, src, rect, Paint());
          canvas.restore();
          canvas.drawRRect(rrect, strokePaint);
        } else {
          canvas.drawRRect(rrect, fillPaint);
          canvas.drawRRect(rrect, strokePaint);
        }
        break;

      case CanvasNodeType.specCard:
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
        canvas.drawRRect(rrect, fillPaint);
        canvas.save();
        canvas.clipRRect(rrect);
        final headerPaint = Paint()
          ..color = strokeColor.withValues(alpha: 0.28)
          ..style = PaintingStyle.fill;
        canvas.drawRect(
          Rect.fromLTWH(node.x, node.y, node.width, 24),
          headerPaint,
        );
        canvas.restore();
        canvas.drawRRect(rrect, strokePaint);
        break;

      case CanvasNodeType.process:
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
        canvas.drawRRect(rrect, fillPaint);
        canvas.drawRRect(rrect, strokePaint);
        break;
    }

    if (node.text.isNotEmpty && node.shapeType != CanvasNodeType.image) {
      final isSpec = node.shapeType == CanvasNodeType.specCard;
      final textSpan = TextSpan(
        text: node.text,
        style: TextStyle(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          fontSize: node.shapeType == CanvasNodeType.decision ? 12 : (isSpec ? 12 : 13),
          fontWeight: FontWeight.w600,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: isSpec ? TextAlign.left : TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: isSpec
            ? 5
            : node.shapeType == CanvasNodeType.sticky
                ? 4
                : 2,
        ellipsis: '...',
      );
      textPainter.layout(maxWidth: math.max(node.width - 20, 20));
      final textOffset = isSpec
          ? Offset(node.x + 10, node.y + 30)
          : Offset(
              node.x + (node.width - textPainter.width) / 2,
              node.y + (node.height - textPainter.height) / 2,
            );
      textPainter.paint(canvas, textOffset);
    }
  }

  Future<void> _exportCanvas({
    required String format,
    required double qualityScale,
    required bool transparentBg,
    required String bgOption,
    bool isPrint = false,
  }) async {
    if (_isExporting) return;

    if (_selectedNodeId != null || _selectedEdgeId != null) {
      setState(() {
        _selectedNodeId = null;
        _selectedEdgeId = null;
      });
      await WidgetsBinding.instance.endOfFrame;
    }

    setState(() => _isExporting = true);

    try {
      // Transparency is strictly allowed for PNG
      final isActuallyTransparent = (format == 'png') && transparentBg;

      final pngBytes = await _renderCanvasToPngBytes(
        pixelRatio: qualityScale,
        transparentBg: isActuallyTransparent,
        bgOption: bgOption,
      );
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      if (format == 'pdf') {
        final doc = pw.Document();
        final pdfImage = pw.MemoryImage(pngBytes);
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            build: (pw.Context context) {
              return pw.FullPage(
                ignoreMargins: false,
                child: pw.Center(
                  child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
                ),
              );
            },
          ),
        );

        final pdfBytes = await doc.save();

        if (isPrint) {
          await Printing.layoutPdf(
            onLayout: (format) async => pdfBytes,
            name: '${widget.item.title}.pdf',
          );
        } else {
          final filePath = '${tempDir.path}/whiteboard_${widget.item.id}_$timestamp.pdf';
          final file = await File(filePath).create();
          await file.writeAsBytes(pdfBytes);

          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path)],
              text: '${widget.item.title} PDF Document',
            ),
          );
        }
      } else if (format == 'jpg') {
        final decoded = img.decodeImage(pngBytes);
        if (decoded == null) throw Exception('Failed to decode image');
        final int jpgQuality = qualityScale == 1.0 ? 85 : (qualityScale == 2.0 ? 95 : 100);
        final jpgBytes = img.encodeJpg(decoded, quality: jpgQuality);

        final filePath = '${tempDir.path}/whiteboard_${widget.item.id}_$timestamp.jpg';
        final file = await File(filePath).create();
        await file.writeAsBytes(jpgBytes);

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: '${widget.item.title} JPG Image',
          ),
        );
      } else {
        // PNG export
        final filePath = '${tempDir.path}/whiteboard_${widget.item.id}_$timestamp.png';
        final file = await File(filePath).create();
        await file.writeAsBytes(pngBytes);

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: '${widget.item.title} PNG Diagram',
          ),
        );
      }
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

  void _showExportBottomSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String selectedFormat = 'png'; // 'png', 'jpg', 'pdf'
    double selectedQuality = 2.0; // 1.0, 2.0, 3.0
    bool isTransparent = false;
    String selectedBgOption = 'dots'; // 'dots', 'grid', 'theme', 'white', 'dark'

    AppBottomSheet.show(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeColor = const Color(0xFF1B8A72);
            final activeBg = isDark ? const Color(0xFF14332B) : const Color(0xFFE8F5F1);
            final inactiveBg = isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF8F9FA);
            final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0);
            final mutedText = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
            final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.s5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Title and Close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Export settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: primaryText,
                        ),
                      ),
                      IconButton(
                        icon: TackIcon(
                          TackIcons.close,
                          size: 18,
                          color: mutedText,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                    // Section 1: Format pills (PNG, JPG, PDF)
                    Text(
                      'Format',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: mutedText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildExportPill(
                          label: 'PNG',
                          isSelected: selectedFormat == 'png',
                          activeColor: activeColor,
                          activeBg: activeBg,
                          inactiveBg: inactiveBg,
                          borderColor: borderColor,
                          textColor: primaryText,
                          onTap: () {
                            setModalState(() {
                              selectedFormat = 'png';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildExportPill(
                          label: 'JPG',
                          isSelected: selectedFormat == 'jpg',
                          activeColor: activeColor,
                          activeBg: activeBg,
                          inactiveBg: inactiveBg,
                          borderColor: borderColor,
                          textColor: primaryText,
                          onTap: () {
                            setModalState(() {
                              selectedFormat = 'jpg';
                              isTransparent = false; // JPEG cannot have transparency
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildExportPill(
                          label: 'PDF',
                          isSelected: selectedFormat == 'pdf',
                          activeColor: activeColor,
                          activeBg: activeBg,
                          inactiveBg: inactiveBg,
                          borderColor: borderColor,
                          textColor: primaryText,
                          onTap: () {
                            setModalState(() {
                              selectedFormat = 'pdf';
                              isTransparent = false; // PDF background uses document styling
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Section 2: Quality measures (1x, 2x, 3x)
                    Text(
                      'Quality',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: mutedText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildExportPill(
                          label: '1x Standard',
                          isSelected: selectedQuality == 1.0,
                          activeColor: activeColor,
                          activeBg: activeBg,
                          inactiveBg: inactiveBg,
                          borderColor: borderColor,
                          textColor: primaryText,
                          onTap: () => setModalState(() => selectedQuality = 1.0),
                        ),
                        const SizedBox(width: 8),
                        _buildExportPill(
                          label: '2x High',
                          isSelected: selectedQuality == 2.0,
                          activeColor: activeColor,
                          activeBg: activeBg,
                          inactiveBg: inactiveBg,
                          borderColor: borderColor,
                          textColor: primaryText,
                          onTap: () => setModalState(() => selectedQuality = 2.0),
                        ),
                        const SizedBox(width: 8),
                        _buildExportPill(
                          label: '3x Ultra',
                          isSelected: selectedQuality == 3.0,
                          activeColor: activeColor,
                          activeBg: activeBg,
                          inactiveBg: inactiveBg,
                          borderColor: borderColor,
                          textColor: primaryText,
                          onTap: () => setModalState(() => selectedQuality = 3.0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section 3: Transparent Background Option (Allowed only in PNG)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceAlt : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Transparent Background',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: selectedFormat == 'png'
                                              ? primaryText
                                              : mutedText.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ),
                                    if (selectedFormat != 'png') ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'PNG only',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: mutedText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  selectedFormat == 'png'
                                      ? 'Export canvas elements without background fill'
                                      : 'Transparency is not supported in ${selectedFormat.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: selectedFormat == 'png' && isTransparent,
                            onChanged: selectedFormat == 'png'
                                ? (val) => setModalState(() => isTransparent = val)
                                : null,
                            activeThumbColor: activeColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Section 4: Canvas Background Dropdown
                    Text(
                      'Canvas Background',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: mutedText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TackDropdown<String>(
                      isExpanded: true,
                      value: (isTransparent && selectedFormat == 'png') ? null : selectedBgOption,
                      hint: (isTransparent && selectedFormat == 'png')
                          ? 'Transparent (Background disabled)'
                          : 'Select canvas background',
                      backgroundColor: (isTransparent && selectedFormat == 'png')
                          ? (isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9))
                          : (isDark ? AppColors.darkSurfaceAlt : Colors.white),
                      borderColor: (isTransparent && selectedFormat == 'png')
                          ? borderColor.withValues(alpha: 0.5)
                          : borderColor,
                      onSelected: (isTransparent && selectedFormat == 'png')
                          ? (_) {}
                          : (newVal) => setModalState(() => selectedBgOption = newVal),
                      items: const [
                        TackDropdownItem(
                          value: 'dots',
                          label: 'Checkered dots (Current canvas)',
                          icon: TackIcons.gridView,
                        ),
                        TackDropdownItem(
                          value: 'grid',
                          label: 'Line grid',
                          icon: TackIcons.gridView,
                        ),
                        TackDropdownItem(
                          value: 'theme',
                          label: 'Theme solid',
                          icon: TackIcons.palette,
                        ),
                        TackDropdownItem(
                          value: 'white',
                          label: 'Pure white',
                          icon: TackIcons.sun,
                        ),
                        TackDropdownItem(
                          value: 'dark',
                          label: 'Pitch black',
                          icon: TackIcons.moon,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section 5: Direct Export CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _exportCanvas(
                            format: selectedFormat,
                            qualityScale: selectedQuality,
                            transparentBg: isTransparent,
                            bgOption: selectedBgOption,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppColors.lightSurface : const Color(0xFF191A23),
                          foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
                          elevation: 0,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppSpacing.roundedPill,
                          ),
                        ),
                        child: const Text(
                          'Export file',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }

  Widget _buildExportPill({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required Color activeBg,
    required Color inactiveBg,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? activeColor : borderColor,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? activeColor : textColor,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: _canPopWhiteboard(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleWhiteboardBack();
      },
      child: KeyboardListener(
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
              onPressed: _handleWhiteboardBack,
            ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item.title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Whiteboard',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const TackIcon(TackIcons.chevronDown, size: 14),
                ],
              ),
            ],
          ),
          actions: [
            // Undo Button (Disabled when stack is empty)
            IconButton(
              icon: TackIcon(
                TackIcons.undoSvg,
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
                TackIcons.redoSvg,
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
                onPressed: _isExporting ? null : _showExportBottomSheet,
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
                    : const Text('Export'),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Infinite/Bounded Interactive Canvas with Multi-Touch Arbiter
            Listener(
              onPointerDown: (event) {
                final screenWidth = MediaQuery.sizeOf(context).width;
                final isEdge = event.position.dx < 28.0 || event.position.dx > screenWidth - 28.0;
                if (isEdge != _isEdgeTouch) {
                  setState(() => _isEdgeTouch = isEdge);
                }
                _activePointers++;
                if (_activePointers >= 2 && _isDraggingNode) {
                  // If 2 or more fingers are down, immediately cancel node dragging to let 2-finger pan/zoom take priority
                  setState(() => _isDraggingNode = false);
                }
              },
              onPointerUp: (_) {
                _activePointers = math.max(0, _activePointers - 1);
                if (_activePointers == 0 && _isEdgeTouch) {
                  setState(() => _isEdgeTouch = false);
                }
              },
              onPointerCancel: (_) {
                _activePointers = math.max(0, _activePointers - 1);
                if (_activePointers == 0 && _isEdgeTouch) {
                  setState(() => _isEdgeTouch = false);
                }
              },
              child: InteractiveViewer(
                transformationController: _transformationController,
                boundaryMargin: const EdgeInsets.all(3000),
                minScale: 0.15,
                maxScale: 3.5,
                constrained: false,
                // When dragging a node or touching near screen edges (system back gesture zone), disable pan
                panEnabled: (_activeTool == 'pan' || _activeTool == 'select') && !_isDraggingNode && !_isEdgeTouch,
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
                        edge.fromPort,
                        ports.end,
                        edge.toPort,
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
                      width: _canvasSize,
                      height: _canvasSize,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _CanvasGridPainter(showGrid: _showGrid, isDark: isDark, opacity: _gridOpacity),
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
                          ..._nodes.map((node) => _buildNodeWidget(node, isDark)),
                          if (_selectedNodeId != null && _nodes.any((n) => n.id == _selectedNodeId)) ...[
                            _buildNodeResizeBoundingBox(_nodes.firstWhere((n) => n.id == _selectedNodeId), isDark),
                            _buildSelectedNodeCapsule(isDark),
                            ..._buildNodeBranchHandles(isDark),
                          ],
                          if (_selectedEdgeId != null && _edges.any((e) => e.id == _selectedEdgeId)) ...[
                            _buildSelectedEdgeCapsule(isDark),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Top Connecting Mode Banner Indicator
            if (_connectingFromNodeId != null)
              Positioned(
                top: 20,
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
                        const TackIcon(TackIcons.link, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Tap target node to connect',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => setState(() => _connectingFromNodeId = null),
                          child: const TackIcon(TackIcons.close, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Floating Shape Picker Popup (when Add Shape is active)
            if (!_isZenMode && _showShapesMenu)
              Positioned(
                key: const ValueKey('shapes_menu_popup'),
                bottom: AppSpacing.md + 56,
                left: 0,
                right: 0,
                child: Center(
                  child: _buildShapesMenu(isDark),
                ),
              ),

            // Minimap Radar (when toggled on)
            if (!_isZenMode && _showMinimap)
              Positioned(
                key: const ValueKey('minimap_radar_popup'),
                bottom: AppSpacing.md + 56,
                right: AppSpacing.md,
                child: _buildMinimap(isDark),
              ),

            // Floating Grid Opacity Slider Popup (Opens on holding 4-dots grid button)
            if (!_isZenMode && _showGridOpacitySlider)
              Positioned(
                key: const ValueKey('grid_opacity_popup'),
                bottom: AppSpacing.md + 56,
                left: 0,
                right: 0,
                child: Center(
                  child: _buildGridOpacitySliderPopup(isDark),
                ),
              ),

            // Bottom Consolidated Controls Dock (Tools + Canvas Controls)
            if (!_isZenMode)
              Positioned(
                key: const ValueKey('bottom_controls_bar'),
                bottom: AppSpacing.md,
                left: AppSpacing.sm,
                right: AppSpacing.sm,
                child: Center(
                  child: _buildBottomControlsBar(isDark),
                ),
              ),

            // Zen Mode Restore Button
            if (_isZenMode)
              Positioned(
                bottom: 20,
                right: 20,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isZenMode = false);
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        boxShadow: AppSpacing.floatingControlShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            TackIcons.eye,
                            size: 16,
                            color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Show Tools',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

  // ================= UI Builder Methods =================

  // Selected Edge Floating Action Capsule (Edit Label, Reverse, Delete)
  Widget _buildSelectedEdgeCapsule(bool isDark) {
    if (_selectedEdgeId == null) return const SizedBox.shrink();
    final edge = _edges.cast<CanvasEdge?>().firstWhere(
          (e) => e?.id == _selectedEdgeId,
          orElse: () => null,
        );
    if (edge == null) return const SizedBox.shrink();

    final from = _nodes.cast<CanvasNode?>().firstWhere((n) => n?.id == edge.fromNodeId, orElse: () => null);
    final to = _nodes.cast<CanvasNode?>().firstWhere((n) => n?.id == edge.toNodeId, orElse: () => null);
    if (from == null || to == null) return const SizedBox.shrink();

    final ports = _resolveEdgePorts(edge, from, to);
    final waypoints = _CanvasEdgesPainter.computeWaypoints(
      ports.start,
      edge.fromPort,
      ports.end,
      edge.toPort,
    );

    Offset connectorCenter;
    if (waypoints.length >= 4) {
      final p1 = waypoints[1];
      final p2 = waypoints[2];
      connectorCenter = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    } else if (waypoints.length == 3) {
      final seg1 = (waypoints[1] - waypoints[0]).distance;
      final seg2 = (waypoints[2] - waypoints[1]).distance;
      final half = (seg1 + seg2) / 2;
      if (half <= seg1 && seg1 > 0) {
        final t = half / seg1;
        connectorCenter = Offset.lerp(waypoints[0], waypoints[1], t)!;
      } else if (seg2 > 0) {
        final t = (half - seg1) / seg2;
        connectorCenter = Offset.lerp(waypoints[1], waypoints[2], t)!;
      } else {
        connectorCenter = waypoints[1];
      }
    } else if (waypoints.length == 2) {
      connectorCenter = Offset(
        (waypoints[0].dx + waypoints[1].dx) / 2,
        (waypoints[0].dy + waypoints[1].dy) / 2,
      );
    } else {
      connectorCenter = Offset(
        (ports.start.dx + ports.end.dx) / 2,
        (ports.start.dy + ports.end.dy) / 2,
      );
    }

    return Positioned(
      left: connectorCenter.dx.clamp(80.0, _canvasSize - 80.0),
      top: (connectorCenter.dy - 32).clamp(8.0, _canvasSize - 40.0),
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 200),
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
                // Edit Label
                IconButton(
                  icon: const TackIcon(TackIcons.pencil, size: 16),
                  tooltip: 'Edit Connection Label',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _showEdgeEditDialog(edge),
                ),
                const SizedBox(width: 4),

                // Insert Node on Connection (+ icon from toolbar)
                PopupMenuButton<CanvasNodeType>(
                  tooltip: 'Insert Shape on Connection',
                  offset: const Offset(0, -50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  itemBuilder: (context) {
                    final items = [
                      (type: CanvasNodeType.process, label: 'Process', color: AppColors.pastelLimeLight),
                      (type: CanvasNodeType.decision, label: 'Decision (Rhombus)', color: AppColors.pastelLavenderLight),
                      (type: CanvasNodeType.startEnd, label: 'Start / End', color: AppColors.pastelCoralLight),
                      (type: CanvasNodeType.inputOutput, label: 'Input / Output', color: AppColors.pastelAmberLight),
                      (type: CanvasNodeType.connector, label: 'Connector', color: AppColors.pastelCyanLight),
                    ];
                    return items.map((item) {
                      return PopupMenuItem<CanvasNodeType>(
                        value: item.type,
                        child: Row(
                          children: [
                            _buildShapePreview(item.type, item.color, isDark),
                            const SizedBox(width: 12),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  onSelected: (newType) => _insertNodeOnEdge(edge, newType),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        TackIcons.square,
                        size: 18,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Reverse Direction
                IconButton(
                  icon: const Icon(TackIcons.arrowLeftRight, size: 18),
                  tooltip: 'Reverse Direction',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _history.recordSnapshot(_nodes, _edges);
                    setState(() {
                      final idx = _edges.indexWhere((e) => e.id == edge.id);
                      if (idx >= 0) {
                        _edges[idx] = CanvasEdge(
                          id: edge.id,
                          fromNodeId: edge.toNodeId,
                          toNodeId: edge.fromNodeId,
                          label: edge.label,
                          fromPort: edge.toPort,
                          toPort: edge.fromPort,
                        );
                      }
                    });
                    _saveCanvasState();
                  },
                ),
                const SizedBox(width: 4),

                // Delete Edge
                IconButton(
                  icon: const TackIcon(TackIcons.trash, size: 16, color: AppColors.error),
                  tooltip: 'Delete Connection',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _history.recordSnapshot(_nodes, _edges);
                    setState(() {
                      _edges.removeWhere((e) => e.id == edge.id);
                      _selectedEdgeId = null;
                    });
                    _saveCanvasState();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  // Interactive Live Minimap Navigator
  Widget _buildMinimap(bool isDark) {
    const mapSize = 120.0;
    final scale = mapSize / _canvasSize;

    final matrix = _transformationController.value;
    final inv = Matrix4.tryInvert(matrix);
    Rect viewport = Rect.zero;
    if (inv != null) {
      final screenSize = MediaQuery.sizeOf(context);
      final topLeft = MatrixUtils.transformPoint(inv, Offset.zero);
      final bottomRight = MatrixUtils.transformPoint(inv, Offset(screenSize.width, screenSize.height));
      viewport = Rect.fromPoints(
        Offset(topLeft.dx * scale, topLeft.dy * scale),
        Offset(bottomRight.dx * scale, bottomRight.dy * scale),
      );
    }

    return Container(
      width: mapSize,
      height: mapSize,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16181F).withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.2,
        ),
        boxShadow: AppSpacing.floatingControlShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTapDown: (details) {
          final tap = details.localPosition;
          final canvasX = tap.dx / scale;
          final canvasY = tap.dy / scale;
          final screenSize = MediaQuery.sizeOf(context);
          final currentScale = _transformationController.value.getMaxScaleOnAxis();
          final transX = (screenSize.width / 2) - (canvasX * currentScale);
          final transY = (screenSize.height / 2) - (canvasY * currentScale);
          final targetMatrix = Matrix4.identity()
            ..translateByVector3(vmath.Vector3(transX, transY, 0.0))
            ..scaleByVector3(vmath.Vector3(currentScale, currentScale, 1.0));
          _animateCanvasToMatrix(targetMatrix);
        },
        child: Stack(
          children: [
            // Canvas boundary outline
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                  width: 0.5,
                ),
              ),
            ),
            // Nodes as mini rectangles
            for (final n in _nodes)
              Positioned(
                left: n.x * scale,
                top: n.y * scale,
                width: math.max(3.0, n.width * scale),
                height: math.max(2.0, n.height * scale),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.getPaletteById(n.paletteId).lightColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            // Viewport rect
            Positioned(
              left: viewport.left.clamp(0.0, mapSize),
              top: viewport.top.clamp(0.0, mapSize),
              width: viewport.width.clamp(4.0, mapSize),
              height: viewport.height.clamp(4.0, mapSize),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.accentCyan,
                    width: 1.5,
                  ),
                  color: AppColors.accentCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Floating Shapes Selector Popup (Start/End, Process, Decision, I/O, Connector, Spec Card)
  Widget _buildShapesMenu(bool isDark) {
    final items = [
      (type: CanvasNodeType.startEnd, label: 'Start / End', color: AppColors.pastelCoralLight),
      (type: CanvasNodeType.process, label: 'Process', color: AppColors.pastelLimeLight),
      (type: CanvasNodeType.decision, label: 'Decision', color: AppColors.pastelLavenderLight),
      (type: CanvasNodeType.inputOutput, label: 'Input / Output', color: AppColors.pastelAmberLight),
      (type: CanvasNodeType.connector, label: 'Connector', color: AppColors.pastelCyanLight),
      (type: CanvasNodeType.specCard, label: 'Spec Card', color: AppColors.pastelCyanLight),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppSpacing.floatingControlShadow,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: items.map((item) {
            return Tooltip(
              message: 'Add ${item.label}',
              child: InkWell(
                onTap: () {
                  _addNode(item.type);
                  setState(() => _showShapesMenu = false);
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildShapePreview(item.type, item.color, isDark),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
      case CanvasNodeType.specCard:
        return Container(
          width: 24,
          height: 16,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(3.5),
            border: Border.all(color: color, width: 1.5),
          ),
          alignment: Alignment.topCenter,
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.75),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
            ),
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

  Widget _buildDockToolButton({
    required String id,
    required dynamic icon,
    required String tooltip,
    required bool isDark,
    VoidCallback? onTapOverride,
  }) {
    final isSelected = _activeTool == id;
    final iconColor = isSelected
        ? (isDark ? AppColors.primaryLight : AppColors.primaryDark)
        : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          if (onTapOverride != null) {
            onTapOverride();
          } else {
            setState(() {
              _activeTool = id;
              _showShapesMenu = false;
            });
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
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
            child: TackIcon(
              icon,
              size: 20,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }

  // Four-dots in 2x2 matrix pattern icon
  Widget _buildFourDotsIcon({required Color color, double size = 18}) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 3.5,
                  height: 3.5,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 3.5),
                Container(
                  width: 3.5,
                  height: 3.5,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ],
            ),
            const SizedBox(height: 3.5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 3.5,
                  height: 3.5,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 3.5),
                Container(
                  width: 3.5,
                  height: 3.5,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Floating Grid Opacity Slider Popup (Opens above dock on holding 4-dots grid button)
  Widget _buildGridOpacitySliderPopup(bool isDark) {
    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: AppSpacing.floatingControlShadow,
      ),
      child: Row(
        children: [
          _buildFourDotsIcon(color: isDark ? Colors.white70 : Colors.black87, size: 14),
          const SizedBox(width: 6),
          Text(
            '${(_gridOpacity * 100).toInt()}%',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: _gridOpacity,
                min: 0.04,
                max: 0.50,
                activeColor: AppColors.accentAmber,
                inactiveColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                onChanged: (val) {
                  setState(() => _gridOpacity = val);
                },
                onChangeEnd: (val) => _saveGridOpacity(val),
              ),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _showGridOpacitySlider = false),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: TackIcon(
                TackIcons.close,
                size: 14,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Consolidated Bottom Controls Dock (Unified Tools + Canvas Controls)
  Widget _buildBottomControlsBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppSpacing.roundedPill,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: AppSpacing.floatingControlShadow,
      ),
      child: SingleChildScrollView(
        key: const PageStorageKey('whiteboard_bottom_dock_scroll'),
        controller: _bottomDockScrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tool 1: Select
            _buildDockToolButton(
              id: 'select',
              icon: TackIcons.selectSvg,
              tooltip: 'Select & Move (V)',
              isDark: isDark,
            ),
            // Tool 2: Pan
            _buildDockToolButton(
              id: 'pan',
              icon: TackIcons.handSvg,
              tooltip: 'Pan Canvas (H)',
              isDark: isDark,
            ),
            // Tool 3: Connect
            _buildDockToolButton(
              id: 'connect',
              icon: TackIcons.connectorSvg,
              tooltip: 'Connect Nodes (L)',
              isDark: isDark,
            ),

            // Tool 4: Add Shape (+)
            Tooltip(
              message: 'Add Flowchart Shape',
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showShapesMenu = !_showShapesMenu);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: _showShapesMenu
                        ? (isDark ? AppColors.darkSurfaceAlt : const Color(0xFFEFF6FF))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: _showShapesMenu
                        ? Border.all(
                            color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                            width: 1.2,
                          )
                        : null,
                  ),
                  child: Center(
                    child: TackIcon(
                      TackIcons.plusSvg,
                      size: 20,
                      color: _showShapesMenu
                          ? (isDark ? AppColors.primaryLight : AppColors.primaryDark)
                          : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    ),
                  ),
                ),
              ),
            ),

            // Tool 5: Sticky Note
            _buildDockToolButton(
              id: 'sticky',
              icon: TackIcons.stickyNote,
              tooltip: 'Sticky Note (S)',
              isDark: isDark,
            ),
            // Tool 5b: Spec Card / Pin Note
            _buildDockToolButton(
              id: 'spec',
              icon: TackIcons.notesSvg,
              tooltip: 'Spec Card / Pin Note',
              isDark: isDark,
              onTapOverride: _showAddSpecCardSheet,
            ),
            // Tool 6: Text Tool
            _buildDockToolButton(
              id: 'text',
              icon: TackIcons.textSvg,
              tooltip: 'Text Tool (T)',
              isDark: isDark,
            ),
            // Tool 7: Image
            _buildDockToolButton(
              id: 'image',
              icon: TackIcons.imageSvg,
              tooltip: 'Insert Image',
              isDark: isDark,
              onTapOverride: _pickAndInsertImage,
            ),

            // Separator
            Container(
              height: 20,
              width: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),

            // 4-Dots Matrix Pattern Button (Tap to toggle grid, Hold for opacity slider)
            Tooltip(
              message: 'Tap to toggle grid • Hold to adjust opacity',
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _showGrid = !_showGrid;
                    if (!_showGrid) _showGridOpacitySlider = false;
                  });
                },
                onLongPress: () {
                  HapticFeedback.heavyImpact();
                  setState(() {
                    _showGrid = true;
                    _showGridOpacitySlider = !_showGridOpacitySlider;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: _buildFourDotsIcon(
                    color: _showGrid
                        ? AppColors.accentAmber
                        : (isDark ? Colors.white54 : Colors.black45),
                    size: 18,
                  ),
                ),
              ),
            ),

            // Auto-align flowchart in place
            Tooltip(
              message: 'Auto-Align In Place',
              child: IconButton(
                icon: const Icon(TackIcons.graph, size: 19, color: AppColors.accentAmber),
                onPressed: _autoArrangeFlowchart,
                visualDensity: VisualDensity.compact,
              ),
            ),

            // Fit whole flowchart to screen
            Tooltip(
              message: 'Fit to View',
              child: IconButton(
                icon: const Icon(TackIcons.scan, size: 19),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _fitCanvasToContent();
                },
                visualDensity: VisualDensity.compact,
              ),
            ),

            // Minimap Toggle
            Tooltip(
              message: _showMinimap ? 'Hide Minimap' : 'Show Minimap',
              child: IconButton(
                icon: Icon(
                  TackIcons.map,
                  size: 18,
                  color: _showMinimap
                      ? AppColors.accentCyan
                      : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showMinimap = !_showMinimap);
                },
                visualDensity: VisualDensity.compact,
              ),
            ),

            // Zen Mode Toggle
            Tooltip(
              message: 'Zen Mode (Hide Tools)',
              child: IconButton(
                icon: const Icon(TackIcons.eyeOff, size: 18),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _isZenMode = true;
                    _showShapesMenu = false;
                    _showGridOpacitySlider = false;
                  });
                },
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateNodeBounds(String id, {double? x, double? y, double? width, double? height}) {
    final idx = _nodes.indexWhere((n) => n.id == id);
    if (idx < 0) return;
    final current = _nodes[idx];
    setState(() {
      _nodes[idx] = current.copyWith(
        x: x ?? current.x,
        y: y ?? current.y,
        width: width ?? current.width,
        height: height ?? current.height,
      );
    });
  }

  Widget _buildNodeResizeBoundingBox(CanvasNode node, bool isDark) {
    if (_activeTool == 'pan') return const SizedBox.shrink();

    return Stack(
      children: [
        // Bounding Box Accent Outline
        Positioned(
          left: node.x - 2,
          top: node.y - 2,
          width: node.width + 4,
          height: node.height + 4,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  node.shapeType == CanvasNodeType.connector
                      ? (node.height + 4) / 2
                      : node.shapeType == CanvasNodeType.startEnd
                          ? (node.height + 4) / 2
                          : 10,
                ),
                border: Border.all(
                  color: AppColors.accentOrange.withValues(alpha: 0.9),
                  width: 1.6,
                ),
              ),
            ),
          ),
        ),

        // Corner Handle: Top-Left
        Positioned(
          left: node.x - 14,
          top: node.y - 14,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (_) {
              setState(() => _isDraggingNode = true);
              _history.recordSnapshot(_nodes, _edges);
            },
            onPanUpdate: (details) {
              final newWidth = (node.width - details.delta.dx).clamp(50.0, node.x + node.width);
              final newX = (node.x + details.delta.dx).clamp(0.0, node.x + node.width - 50.0);
              final newHeight = (node.height - details.delta.dy).clamp(36.0, node.y + node.height);
              final newY = (node.y + details.delta.dy).clamp(0.0, node.y + node.height - 36.0);
              _updateNodeBounds(node.id, x: newX, y: newY, width: newWidth, height: newHeight);
            },
            onPanEnd: (_) {
              setState(() => _isDraggingNode = false);
              _saveCanvasState();
            },
            child: _buildResizeCornerHandle(),
          ),
        ),

        // Corner Handle: Top-Right
        Positioned(
          left: node.x + node.width - 14,
          top: node.y - 14,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (_) {
              setState(() => _isDraggingNode = true);
              _history.recordSnapshot(_nodes, _edges);
            },
            onPanUpdate: (details) {
              final newWidth = (node.width + details.delta.dx).clamp(50.0, _canvasSize - node.x);
              final newHeight = (node.height - details.delta.dy).clamp(36.0, node.y + node.height);
              final newY = (node.y + details.delta.dy).clamp(0.0, node.y + node.height - 36.0);
              _updateNodeBounds(node.id, y: newY, width: newWidth, height: newHeight);
            },
            onPanEnd: (_) {
              setState(() => _isDraggingNode = false);
              _saveCanvasState();
            },
            child: _buildResizeCornerHandle(),
          ),
        ),

        // Corner Handle: Bottom-Left
        Positioned(
          left: node.x - 14,
          top: node.y + node.height - 14,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (_) {
              setState(() => _isDraggingNode = true);
              _history.recordSnapshot(_nodes, _edges);
            },
            onPanUpdate: (details) {
              final newWidth = (node.width - details.delta.dx).clamp(50.0, node.x + node.width);
              final newX = (node.x + details.delta.dx).clamp(0.0, node.x + node.width - 50.0);
              final newHeight = (node.height + details.delta.dy).clamp(36.0, _canvasSize - node.y);
              _updateNodeBounds(node.id, x: newX, width: newWidth, height: newHeight);
            },
            onPanEnd: (_) {
              setState(() => _isDraggingNode = false);
              _saveCanvasState();
            },
            child: _buildResizeCornerHandle(),
          ),
        ),

        // Corner Handle: Bottom-Right
        Positioned(
          left: node.x + node.width - 14,
          top: node.y + node.height - 14,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (_) {
              setState(() => _isDraggingNode = true);
              _history.recordSnapshot(_nodes, _edges);
            },
            onPanUpdate: (details) {
              final newWidth = (node.width + details.delta.dx).clamp(50.0, _canvasSize - node.x);
              final newHeight = (node.height + details.delta.dy).clamp(36.0, _canvasSize - node.y);
              _updateNodeBounds(node.id, width: newWidth, height: newHeight);
            },
            onPanEnd: (_) {
              setState(() => _isDraggingNode = false);
              _saveCanvasState();
            },
            child: _buildResizeCornerHandle(),
          ),
        ),
      ],
    );
  }

  Widget _buildResizeCornerHandle() {
    return Container(
      width: 28,
      height: 28,
      color: Colors.transparent,
      alignment: Alignment.center,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: AppColors.accentOrange, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
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

    // If node is near top border, place capsule below it to avoid clipping.
    // The top branch (+) handle sits at node.y - 32 (28px tall → ends at node.y - 4).
    // Offset by -72 so the capsule clears the + icon with a comfortable gap.
    final bool placeBelow = node.y < 80;
    final capsuleTop = placeBelow
        ? (node.y + node.height + 8).clamp(8.0, _canvasSize - 100.0)
        : (node.y - 72).clamp(8.0, _canvasSize - 100.0);
    final capsuleCenterX = (node.x + (node.width / 2)).clamp(100.0, _canvasSize - 100.0);

    return Positioned(
      left: capsuleCenterX,
      top: capsuleTop,
      child: FractionalTranslation(
        translation: const Offset(-0.5, 0.0),
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
                // 0. Drag to Move Node Handle ("moving thing")
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) {
                    if (_activeTool == 'pan' || _activePointers >= 2) return;
                    setState(() => _isDraggingNode = true);
                    _history.recordSnapshot(_nodes, _edges);
                  },
                  onPanUpdate: (details) {
                    if (_activePointers >= 2 || _activeTool == 'pan') return;
                    _updateNodeBounds(
                      node.id,
                      x: (node.x + details.delta.dx).clamp(0.0, _canvasSize - node.width),
                      y: (node.y + details.delta.dy).clamp(0.0, _canvasSize - node.height),
                    );
                  },
                  onPanEnd: (_) {
                    setState(() => _isDraggingNode = false);
                    _saveCanvasState();
                  },
                  child: Tooltip(
                    message: 'Drag to Move Node',
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          TackIcons.move,
                          size: 15,
                          color: isDark ? AppColors.darkTextPrimary : const Color(0xFF191A23),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

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
                  icon: const TackIcon(TackIcons.pencil, size: 16),
                  tooltip: 'Edit Text',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _editNodeText(node),
                ),
                const SizedBox(width: 4),

                if (node.shapeType == CanvasNodeType.specCard ||
                    node.shapeType == CanvasNodeType.sticky) ...[
                  IconButton(
                    icon: const TackIcon(
                      TackIcons.notes,
                      size: 16,
                      color: AppColors.pastelCyanLight,
                    ),
                    tooltip: node.linkedNoteId != null
                        ? 'Open Linked Note'
                        : 'Promote to Linked Note',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => _openOrPromoteSpecNode(node),
                  ),
                  const SizedBox(width: 4),
                ],

                // 3. Change Shape Action (+ icon from toolbar)
                PopupMenuButton<CanvasNodeType>(
                  tooltip: 'Change Shape',
                  offset: Offset(0, placeBelow ? 40 : -50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  itemBuilder: (context) {
                    final items = [
                      (type: CanvasNodeType.process, label: 'Process', color: AppColors.pastelLimeLight),
                      (type: CanvasNodeType.decision, label: 'Decision (Rhombus)', color: AppColors.pastelLavenderLight),
                      (type: CanvasNodeType.startEnd, label: 'Start / End', color: AppColors.pastelCoralLight),
                      (type: CanvasNodeType.inputOutput, label: 'Input / Output', color: AppColors.pastelAmberLight),
                      (type: CanvasNodeType.connector, label: 'Connector', color: AppColors.pastelCyanLight),
                      (type: CanvasNodeType.specCard, label: 'Spec Card', color: AppColors.pastelCyanLight),
                    ];
                    return items.map((item) {
                      final isCurrent = node.shapeType == item.type;
                      return PopupMenuItem<CanvasNodeType>(
                        value: item.type,
                        child: Row(
                          children: [
                            _buildShapePreview(item.type, item.color, isDark),
                            const SizedBox(width: 12),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 13,
                                color: isCurrent
                                    ? (isDark ? AppColors.pastelLimeLight : AppColors.primaryLight)
                                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              ),
                            ),
                            if (isCurrent) ...[
                              const Spacer(),
                              const Icon(TackIcons.check, size: 16, color: AppColors.pastelLimeLight),
                            ],
                          ],
                        ),
                      );
                    }).toList();
                  },
                  onSelected: (newType) => _changeNodeShape(node, newType),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        TackIcons.square,
                        size: 18,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // 3. Connect From Node Action
                IconButton(
                  icon: const TackIcon(TackIcons.link, size: 16),
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

                // 4. Duplicate Node Action
                IconButton(
                  icon: const TackIcon(TackIcons.copy, size: 16),
                  tooltip: 'Duplicate Node',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: _duplicateSelectedNode,
                ),
                const SizedBox(width: 4),

                // 5. Delete Action
                IconButton(
                  icon: const TackIcon(TackIcons.trash, size: 16, color: AppColors.error),
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
      ),
    );
  }

  // Quick-Branch (+) Handles on the Cardinal Ports of Selected Node (omitting ports with existing edges)
  List<Widget> _buildNodeBranchHandles(bool isDark) {
    final node = _nodes.cast<CanvasNode?>().firstWhere(
          (n) => n?.id == _selectedNodeId,
          orElse: () => null,
        );
    if (node == null || _activeTool == 'pan') return const [];

    final hasRightEdge = _edges.any((e) =>
        (e.fromNodeId == node.id && e.fromPort == 'right') ||
        (e.toNodeId == node.id && e.toPort == 'right'));
    final hasBottomEdge = _edges.any((e) =>
        (e.fromNodeId == node.id && e.fromPort == 'bottom') ||
        (e.toNodeId == node.id && e.toPort == 'bottom'));
    final hasLeftEdge = _edges.any((e) =>
        (e.fromNodeId == node.id && e.fromPort == 'left') ||
        (e.toNodeId == node.id && e.toPort == 'left'));
    final hasTopEdge = _edges.any((e) =>
        (e.fromNodeId == node.id && e.fromPort == 'top') ||
        (e.toNodeId == node.id && e.toPort == 'top'));

    return [
      if (!hasRightEdge)
        Positioned(
          left: node.x + node.width + 6,
          top: node.y + (node.height / 2) - 13,
          child: _buildBranchHandleIcon(
            icon: TackIcons.plus,
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
            icon: TackIcons.plus,
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
            icon: TackIcons.plus,
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
            icon: TackIcons.plus,
            tooltip: 'Branch Up',
            isDark: isDark,
            onTap: () => _branchFromNode(node, 'top'),
          ),
        ),
    ];
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
                child: TackIcon(
                  TackIcons.plus,
                  size: 14,
                  color: Color(0xFF191A23),
                  style: HeroIconStyle.solid,
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
        Widget imgWidget;
        if (node.imagePath != null && node.imagePath!.isNotEmpty) {
          imgWidget = Image.file(
            File(node.imagePath!),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: fillColor,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TackIcon(TackIcons.photo, size: 28),
                    const SizedBox(height: 4),
                    Text('Image', style: TextStyle(fontSize: 10, color: strokeColor)),
                  ],
                ),
              ),
            ),
          );
        } else {
          imgWidget = Container(
            color: fillColor,
            child: const Center(child: TackIcon(TackIcons.photo, size: 32)),
          );
        }

        shapeContent = Container(
          width: node.width,
          height: node.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isConnectingSource || isSelected ? AppColors.accentOrange : strokeColor,
              width: isConnectingSource || isSelected ? 2.5 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.accentOrange.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.5),
            child: imgWidget,
          ),
        );
        break;

      case CanvasNodeType.connector:
        shapeContent = Container(
          width: node.width,
          height: node.height,
          decoration: BoxDecoration(
            color: fillColor,
            shape: BoxShape.circle,
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
              fontSize: 12,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        );
        break;

      case CanvasNodeType.specCard:
        final workspace = context.watch<WorkspaceProvider>();
        final linkedItem = node.linkedNoteId != null
            ? workspace.getItemById(node.linkedNoteId!)
            : null;
        final isLinked = linkedItem != null && !linkedItem.isTrash;

        String cardTitle;
        String cardBody;
        String rawForTasks;
        if (isLinked && linkedItem is TextNote) {
          cardTitle = linkedItem.title;
          cardBody = linkedItem.getSummary();
          rawForTasks = linkedItem.content;
        } else if (isLinked && linkedItem is StickyNote) {
          cardTitle = linkedItem.title;
          cardBody = linkedItem.getSummary();
          rawForTasks = linkedItem.content;
        } else {
          final lines = node.text.trim().split('\n');
          cardTitle = lines.isNotEmpty && lines.first.trim().isNotEmpty
              ? lines.first.trim()
              : 'Spec Card';
          cardBody = lines.length > 1
              ? lines.sublist(1).join('\n').trim()
              : 'Double-tap to write spec or tap Open to expand as note';
          rawForTasks = node.text;
        }

        final totalTasks = RegExp(r'^\s*[-*]\s+\[[ xX]\]', multiLine: true)
            .allMatches(rawForTasks)
            .length;
        final doneTasks = RegExp(r'^\s*[-*]\s+\[[xX]\]', multiLine: true)
            .allMatches(rawForTasks)
            .length;

        shapeContent = Container(
          width: node.width,
          height: node.height,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isConnectingSource || isSelected
                  ? AppColors.accentOrange
                  : strokeColor.withValues(alpha: 0.85),
              width: isConnectingSource || isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  color: isDark
                      ? palette.darkColor.withValues(alpha: 0.75)
                      : palette.lightColor.withValues(alpha: 0.25),
                  child: Row(
                    children: [
                      TackIcon(
                        isLinked ? TackIcons.link : TackIcons.notes,
                        size: 11,
                        color: isDark ? palette.lightColor : AppColors.lightTextPrimary,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          isLinked ? 'LINKED SPEC' : 'SPEC CARD',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      if (totalTasks > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.28)
                                : Colors.white.withValues(alpha: 0.78),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$doneTasks/$totalTasks',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _openOrPromoteSpecNode(node),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                          child: Text(
                            isLinked ? 'Open ↗' : '+ Note',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: isDark
                                  ? palette.lightColor
                                  : AppColors.primaryLight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cardTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: -0.3,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            cardBody,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11.5,
                              height: 1.32,
                              letterSpacing: -0.2,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        break;

      case CanvasNodeType.process:
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
      key: ValueKey(node.id),
      left: node.x,
      top: node.y,
      child: RepaintBoundary(
        child: IgnorePointer(
          ignoring: _activeTool == 'pan',
          child: GestureDetector(
            onTap: () {
              _canvasFocusNode.requestFocus();
              setState(() {
                _selectedNodeId = node.id;
                _selectedEdgeId = null;

                if (_activeTool == 'connect') {
                  if (_connectingFromNodeId == null) {
                    _connectingFromNodeId = node.id;
                  } else if (_connectingFromNodeId != null && _connectingFromNodeId != node.id) {
                    final fromId = _connectingFromNodeId!;
                    final fromNode = _nodes.cast<CanvasNode?>().firstWhere(
                          (n) => n?.id == fromId,
                          orElse: () => null,
                        );
                    if (fromNode == null) {
                      _connectingFromNodeId = null;
                      return;
                    }
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
            onDoubleTap: () {
              if (node.shapeType == CanvasNodeType.specCard &&
                  node.linkedNoteId != null) {
                _openOrPromoteSpecNode(node);
              } else {
                _editNodeText(node);
              }
            },
            onPanStart: (_) {
              if (_activeTool == 'pan' || _activePointers >= 2) return;
              // Disable InteractiveViewer pan so gestures don't conflict
              setState(() => _isDraggingNode = true);
              _history.recordSnapshot(_nodes, _edges);
            },
            onPanUpdate: (details) {
              if (_activePointers >= 2 || _activeTool == 'pan') {
                if (_isDraggingNode) {
                  setState(() => _isDraggingNode = false);
                }
                return;
              }
              setState(() {
                final index = _nodes.indexWhere((n) => n.id == node.id);
                if (index >= 0) {
                  final rawX = _nodes[index].x + details.delta.dx;
                  final rawY = _nodes[index].y + details.delta.dy;
                  _nodes[index] = _nodes[index].copyWith(
                    x: rawX.clamp(0.0, _canvasSize - node.width),
                    y: rawY.clamp(0.0, _canvasSize - node.height),
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
        ),
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

/// Canvas Grid Painter with Dynamic Dot Opacity
class _CanvasGridPainter extends CustomPainter {
  final bool showGrid;
  final bool isDark;
  final double opacity;

  _CanvasGridPainter({
    required this.showGrid,
    required this.isDark,
    this.opacity = 0.18,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!showGrid) return;
    final dotPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: opacity)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const spacing = 28.0;
    final points = <Offset>[];
    for (double x = 0; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        points.add(Offset(x, y));
      }
    }
    canvas.drawPoints(ui.PointMode.points, points, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _CanvasGridPainter oldDelegate) =>
      oldDelegate.showGrid != showGrid ||
      oldDelegate.isDark != isDark ||
      oldDelegate.opacity != opacity;
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

    if (fromPort == 'bottom' && toPort == 'bottom') {
      final detourY = math.max(start.dy, end.dy) + 36.0;
      return [
        start,
        Offset(start.dx, detourY),
        Offset(end.dx, detourY),
        end,
      ];
    } else if (fromPort == 'top' && toPort == 'top') {
      final detourY = math.min(start.dy, end.dy) - 36.0;
      return [
        start,
        Offset(start.dx, detourY),
        Offset(end.dx, detourY),
        end,
      ];
    } else if (fromPort == 'left' && toPort == 'left') {
      final detourX = math.min(start.dx, end.dx) - 36.0;
      return [
        start,
        Offset(detourX, start.dy),
        Offset(detourX, end.dy),
        end,
      ];
    } else if (fromPort == 'right' && toPort == 'right') {
      final detourX = math.max(start.dx, end.dx) + 36.0;
      return [
        start,
        Offset(detourX, start.dy),
        Offset(detourX, end.dy),
        end,
      ];
    } else if ((fromPort == 'bottom' && toPort == 'top') || (fromPort == 'top' && toPort == 'bottom')) {
      final midY = (start.dy + end.dy) / 2;
      return [
        start,
        Offset(start.dx, midY),
        Offset(end.dx, midY),
        end,
      ];
    } else if ((fromPort == 'right' && toPort == 'left') || (fromPort == 'left' && toPort == 'right')) {
      // If right-to-left is going backwards horizontally
      if (fromPort == 'right' && start.dx >= end.dx) {
        final detourY = math.max(start.dy, end.dy) + 36.0;
        return [
          start,
          Offset(start.dx + 20.0, start.dy),
          Offset(start.dx + 20.0, detourY),
          Offset(end.dx - 20.0, detourY),
          Offset(end.dx - 20.0, end.dy),
          end,
        ];
      }
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

      final fromPort = edge.fromPort;
      final toPort = edge.toPort;

      if (fromPort == 'top') start = from.topPort;
      if (fromPort == 'bottom') start = from.bottomPort;
      if (fromPort == 'left') start = from.leftPort;
      if (fromPort == 'right') start = from.rightPort;

      if (toPort == 'top') end = to.topPort;
      if (toPort == 'bottom') end = to.bottomPort;
      if (toPort == 'left') end = to.leftPort;
      if (toPort == 'right') end = to.rightPort;

      final waypoints = computeWaypoints(start, fromPort, end, toPort);
      if (waypoints.length < 2) continue;

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
