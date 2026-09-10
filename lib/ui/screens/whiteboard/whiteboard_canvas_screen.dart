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

class _WhiteboardCanvasScreenState extends State<WhiteboardCanvasScreen> {
  late List<CanvasNode> _nodes;
  late List<CanvasEdge> _edges;
  final TransformationController _transformationController = TransformationController();
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final FocusNode _canvasFocusNode = FocusNode();

  final CanvasHistoryManager _history = CanvasHistoryManager();

  String _activeTool = 'select'; // 'select', 'pan', 'connect', 'text', 'sticky', 'image'
  String? _selectedNodeId;
  String? _selectedEdgeId;
  String? _connectingFromNodeId;
  bool _isDraggingNode = false;
  bool _showGrid = true;
  double _currentScale = 1.0;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _nodes = List.from(widget.item.nodes);
    _edges = List.from(widget.item.edges);

    _transformationController.addListener(() {
      final scale = _transformationController.value.getMaxScaleOnAxis();
      if (scale != _currentScale) {
        setState(() => _currentScale = scale);
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _canvasFocusNode.dispose();
    super.dispose();
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

    final now = DateTime.now().millisecondsSinceEpoch;
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
      id: 'node_$now',
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
      id: 'node_${DateTime.now().millisecondsSinceEpoch}',
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
      _addNode(
        CanvasNodeType.image,
        position: const Offset(200, 200),
        imagePath: file.path,
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

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
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
          text: '${widget.item.title} Diagram',
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
              boundaryMargin: const EdgeInsets.all(1000),
              minScale: 0.3,
              maxScale: 3.0,
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
                    final start = ports.start;
                    final end = ports.end;

                    final midY = (start.dy + end.dy) / 2;
                    final d1 = _distToSegment(tap, start, Offset(start.dx, midY));
                    final d2 = _distToSegment(tap, Offset(start.dx, midY), Offset(end.dx, midY));
                    final d3 = _distToSegment(tap, Offset(end.dx, midY), end);

                    if (math.min(d1, math.min(d2, d3)) <= 22.0) {
                      _showEdgeEditDialog(edge);
                      return;
                    }
                  }
                },
                child: RepaintBoundary(
                  key: _repaintBoundaryKey,
                  child: SizedBox(
                    width: 1400,
                    height: 1400,
                    child: CustomPaint(
                      painter: _CanvasGridAndEdgesPainter(
                        nodes: _nodes,
                        edges: _edges,
                        selectedEdgeId: _selectedEdgeId,
                        showGrid: _showGrid,
                        isDark: isDark,
                      ),
                      child: Stack(
                        children: [
                          ..._nodes.map((node) => _buildNodeWidget(node, isDark)),
                          if (_selectedNodeId != null) _buildSelectedNodeCapsule(isDark),
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
                top: 70,
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
              top: AppSpacing.md,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              child: _buildTopNodePalette(isDark),
            ),

            // Left Tool Rail
            Positioned(
              left: AppSpacing.md,
              top: 90,
              child: _buildLeftToolRail(isDark),
            ),

            // Right Zoom Controls (+, -, fit)
            Positioned(
              right: AppSpacing.md,
              top: 90,
              child: _buildRightZoomControls(isDark),
            ),

            // Bottom Controls Bar (Minimap & Zoom)
            Positioned(
              bottom: AppSpacing.lg,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              child: _buildBottomControlsBar(isDark),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI Builder Methods =================

  // Top Node Palette: Start/End, Process, Decision, I/O, Connector
  Widget _buildTopNodePalette(bool isDark) {
    final items = [
      (type: CanvasNodeType.startEnd, label: 'Start / End', icon: TackIcons.play, color: AppColors.pastelCoralLight),
      (type: CanvasNodeType.process, label: 'Process', icon: TackIcons.square, color: AppColors.pastelLimeLight),
      (type: CanvasNodeType.decision, label: 'Decision', icon: TackIcons.diamond, color: AppColors.pastelLavenderLight),
      (type: CanvasNodeType.inputOutput, label: 'Input / Output', icon: TackIcons.flow, color: AppColors.pastelAmberLight),
      (type: CanvasNodeType.connector, label: 'Connector', icon: TackIcons.checkCircle, color: AppColors.pastelCyanLight),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppSpacing.roundedMd,
        boxShadow: AppSpacing.floatingControlShadow,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: items.map((item) {
            return InkWell(
              onTap: () => _addNode(item.type),
              borderRadius: AppSpacing.roundedSm,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TackIcon(item.icon, size: 20, color: item.color),
                    const SizedBox(height: 2),
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
            );
          }).toList(),
        ),
      ),
    );
  }

  // Left Tool Rail
  Widget _buildLeftToolRail(bool isDark) {
    final tools = [
      (id: 'select', icon: TackIcons.cursor, tooltip: 'Select & Move'),
      (id: 'pan', icon: TackIcons.hand, tooltip: 'Pan Canvas'),
      (id: 'connect', icon: TackIcons.flow, tooltip: 'Connect Nodes'),
      (id: 'text', icon: TackIcons.notes, tooltip: 'Tap to Add Text'),
      (id: 'sticky', icon: TackIcons.sticky, tooltip: 'Tap to Add Sticky Note'),
      (id: 'image', icon: TackIcons.photo, tooltip: 'Insert Image'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppSpacing.floatingControlShadow,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: tools.map((tool) {
          final isSelected = _activeTool == tool.id;
          return Tooltip(
            message: tool.tooltip,
            child: IconButton(
              icon: TackIcon(
                tool.icon,
                color: isSelected
                    ? (isDark ? AppColors.primaryLight : AppColors.primaryDark)
                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                size: 20,
              ),
              style: isSelected
                  ? IconButton.styleFrom(
                      backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt,
                    )
                  : null,
              onPressed: () {
                if (tool.id == 'image') {
                  _pickAndInsertImage();
                } else {
                  setState(() => _activeTool = tool.id);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // Right Zoom Controls
  Widget _buildRightZoomControls(bool isDark) {
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
        children: [
          IconButton(
            icon: const Icon(Icons.fullscreen_rounded, size: 20),
            onPressed: () => _transformationController.value = Matrix4.identity(),
            tooltip: 'Fit to View',
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 20),
            onPressed: () {
              final matrix = _transformationController.value.clone()..scaleByDouble(1.25, 1.25, 1.0, 1.0);
              _transformationController.value = matrix;
            },
            tooltip: 'Zoom In',
          ),
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 20),
            onPressed: () {
              final matrix = _transformationController.value.clone()..scaleByDouble(0.8, 0.8, 1.0, 1.0);
              _transformationController.value = matrix;
            },
            tooltip: 'Zoom Out',
          ),
        ],
      ),
    );
  }

  // Bottom Controls Bar
  Widget _buildBottomControlsBar(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Minimap
        Container(
          width: 58,
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: AppSpacing.roundedSm,
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            boxShadow: AppSpacing.floatingControlShadow,
          ),
          child: Center(
            child: Icon(
              Icons.account_tree_outlined,
              size: 20,
              color: isDark ? AppColors.pastelCyanLight : AppColors.pastelCyanDark,
            ),
          ),
        ),

        // Grid switch + scale
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: AppSpacing.roundedPill,
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            boxShadow: AppSpacing.floatingControlShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  _showGrid ? Icons.grid_on_rounded : Icons.grid_off_rounded,
                  size: 18,
                  color: _showGrid ? AppColors.accentAmber : null,
                ),
                onPressed: () => setState(() => _showGrid = !_showGrid),
                tooltip: 'Toggle Grid',
              ),
              const SizedBox(width: 4),
              Text(
                '${(_currentScale * 100).toInt()}%',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
            ],
          ),
        ),
      ],
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
        ? (node.y + node.height + 8).clamp(8.0, 1340.0)
        : (node.y - 48).clamp(8.0, 1340.0);
    final capsuleLeft = (node.x + (node.width / 2) - 100).clamp(8.0, 1200.0);

    return Positioned(
      left: capsuleLeft,
      top: capsuleTop,
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
                      height: 36,
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: palette.lightColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black26, width: 1),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(palette.name, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  }).toList();
                },
                onSelected: _changeNodeColor,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.getPaletteById(node.paletteId).lightColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? Colors.white38 : Colors.black26, width: 1.2),
                    ),
                  ),
                ),
              ),

              // 2. Edit Label Button (Pencil Icon)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16),
                tooltip: 'Edit Label',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => _editNodeText(node),
              ),

              // 3. Duplicate Button
              IconButton(
                icon: const TackIcon(TackIcons.copy, size: 16),
                tooltip: 'Duplicate (+20, +20)',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: _duplicateSelectedNode,
              ),

              // 4. Delete Node Button
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
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: 0.785398, // 45 degrees
                child: Container(
                  width: node.height * 0.85,
                  height: node.height * 0.85,
                  decoration: BoxDecoration(
                    color: fillColor,
                    border: Border.all(
                      color: strokeColor,
                      width: isConnectingSource || isSelected ? 2.5 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
            ],
          ),
        );
        break;

      case CanvasNodeType.inputOutput:
        shapeContent = Transform(
          transform: Matrix4.skewX(-0.25),
          child: Container(
            width: node.width,
            height: node.height,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: strokeColor,
                width: isConnectingSource || isSelected ? 2.5 : 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Transform(
              transform: Matrix4.skewX(0.25),
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
                  id: 'edge_${DateTime.now().millisecondsSinceEpoch}',
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
                x: (_nodes[index].x + details.delta.dx).clamp(0.0, 1200.0),
                y: (_nodes[index].y + details.delta.dy).clamp(0.0, 1200.0),
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

/// Canvas Grid & Flowchart Connector Lines Painter
class _CanvasGridAndEdgesPainter extends CustomPainter {
  final List<CanvasNode> nodes;
  final List<CanvasEdge> edges;
  final String? selectedEdgeId;
  final bool showGrid;
  final bool isDark;

  _CanvasGridAndEdgesPainter({
    required this.nodes,
    required this.edges,
    this.selectedEdgeId,
    required this.showGrid,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw dot grid
    if (showGrid) {
      final dotPaint = Paint()
        ..color = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)
        ..strokeWidth = 1.5;

      const spacing = 20.0;
      for (double x = 0; x < size.width; x += spacing) {
        for (double y = 0; y < size.height; y += spacing) {
          canvas.drawCircle(Offset(x, y), 0.8, dotPaint);
        }
      }
    }

    // 2. Draw connector lines & arrows
    for (final edge in edges) {
      final isSelected = edge.id == selectedEdgeId;

      final linePaint = Paint()
        ..color = isSelected
            ? AppColors.accentOrange
            : (isDark ? Colors.white70 : const Color(0xFF1E293B))
        ..strokeWidth = isSelected ? 3.5 : 2.0
        ..style = PaintingStyle.stroke;

      final arrowPaint = Paint()
        ..color = isSelected
            ? AppColors.accentOrange
            : (isDark ? Colors.white70 : const Color(0xFF1E293B))
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

      if (edge.fromPort == 'top') start = from.topPort;
      if (edge.fromPort == 'bottom') start = from.bottomPort;
      if (edge.fromPort == 'left') start = from.leftPort;
      if (edge.fromPort == 'right') start = from.rightPort;

      if (edge.toPort == 'top') end = to.topPort;
      if (edge.toPort == 'bottom') end = to.bottomPort;
      if (edge.toPort == 'left') end = to.leftPort;
      if (edge.toPort == 'right') end = to.rightPort;

      final path = Path();
      path.moveTo(start.dx, start.dy);

      if (start.dx == end.dx || start.dy == end.dy) {
        path.lineTo(end.dx, end.dy);
      } else {
        // Orthogonal right-angle connector
        final midY = (start.dy + end.dy) / 2;
        path.lineTo(start.dx, midY);
        path.lineTo(end.dx, midY);
        path.lineTo(end.dx, end.dy);
      }

      canvas.drawPath(path, linePaint);

      // Draw arrow head at end
      canvas.save();
      canvas.translate(end.dx, end.dy);
      final arrowPath = Path()
        ..moveTo(0, 0)
        ..lineTo(-5, -8)
        ..lineTo(5, -8)
        ..close();
      canvas.drawPath(arrowPath, arrowPaint);
      canvas.restore();

      // Draw label if exists (e.g. "Yes" / "No")
      if (edge.label != null) {
        final textSpan = TextSpan(
          text: edge.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        final labelOffset = Offset(
          (start.dx + end.dx) / 2 + 4,
          (start.dy + end.dy) / 2 - 8,
        );
        textPainter.paint(canvas, labelOffset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasGridAndEdgesPainter oldDelegate) => true;
}
