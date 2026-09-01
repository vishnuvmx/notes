import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/whiteboard_item.dart';
import '../../../state/workspace_provider.dart';

/// Whiteboard & Flowchart Canvas Screen matching Screenshot 4 ("Prime Number Checker").
/// Interactive panning/zooming canvas with flowchart nodes, connectors, and tool rails.
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
  String _activeTool = 'select'; // 'select', 'pan', 'connect', 'text', 'sticky'
  String? _selectedNodeId;
  String? _connectingFromNodeId;
  bool _showGrid = true;
  double _currentScale = 1.0;

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

  void _addNode(CanvasNodeType shapeType) {
    HapticFeedback.lightImpact();
    final now = DateTime.now().millisecondsSinceEpoch;
    final String paletteId;
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
      case CanvasNodeType.process:
      default:
        paletteId = 'lime';
        break;
    }

    // Place node in visible center
    final newNode = CanvasNode(
      id: 'node_$now',
      text: shapeType.label,
      shapeType: shapeType,
      x: 120,
      y: 100 + (_nodes.length * 40.0 % 300),
      width: shapeType == CanvasNodeType.decision ? 140 : 130,
      height: shapeType == CanvasNodeType.decision ? 64 : 52,
      paletteId: paletteId,
    );

    setState(() {
      _nodes.add(newNode);
      _selectedNodeId = newNode.id;
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
            decoration: const InputDecoration(hintText: 'Enter node label...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newText = controller.text.trim();
                setState(() {
                  final index = _nodes.indexWhere((n) => n.id == node.id);
                  if (index >= 0) {
                    _nodes[index] = _nodes[index].copyWith(text: newText);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFFAFBFD),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
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
          IconButton(
            icon: const Icon(Icons.undo_rounded, size: 20),
            onPressed: () {},
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.redo_rounded, size: 20),
            onPressed: () {},
            tooltip: 'Redo',
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md, left: AppSpacing.xs),
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Flowchart diagram ready to share!'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.lightSurface : AppColors.primaryDark,
                foregroundColor: isDark ? AppColors.darkBackground : AppColors.lightSurface,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                minimumSize: const Size(60, 36),
              ),
              child: const Text('Share'),
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
            panEnabled: _activeTool == 'pan' || _activeTool == 'select',
            child: SizedBox(
              width: 1400,
              height: 1400,
              child: CustomPaint(
                painter: _CanvasGridAndEdgesPainter(
                  nodes: _nodes,
                  edges: _edges,
                  showGrid: _showGrid,
                  isDark: isDark,
                ),
                child: Stack(
                  children: _nodes.map((node) => _buildNodeWidget(node, isDark)).toList(),
                ),
              ),
            ),
          ),

          // Top Node Shapes Palette (Screenshot 4)
          Positioned(
            top: AppSpacing.md,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: _buildTopNodePalette(isDark),
          ),

          // Left Tool Rail (Screenshot 4)
          Positioned(
            left: AppSpacing.md,
            top: 90,
            child: _buildLeftToolRail(isDark),
          ),

          // Right Zoom Controls (+, -, fit) (Screenshot 4)
          Positioned(
            right: AppSpacing.md,
            top: 90,
            child: _buildRightZoomControls(isDark),
          ),

          // Bottom Minimap & Controls Bar (Screenshot 4)
          Positioned(
            bottom: AppSpacing.lg,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: _buildBottomControlsBar(isDark),
          ),
        ],
      ),
    );
  }

  // Top Node Palette: Start/End, Process, Decision, I/O, Connector
  Widget _buildTopNodePalette(bool isDark) {
    final items = [
      (type: CanvasNodeType.startEnd, label: 'Start / End', icon: Icons.play_circle_outline_rounded, color: AppColors.pastelCoralLight),
      (type: CanvasNodeType.process, label: 'Process', icon: Icons.rectangle_outlined, color: AppColors.pastelLimeLight),
      (type: CanvasNodeType.decision, label: 'Decision', icon: Icons.diamond_outlined, color: AppColors.pastelLavenderLight),
      (type: CanvasNodeType.inputOutput, label: 'Input / Output', icon: Icons.polyline_outlined, color: AppColors.pastelAmberLight),
      (type: CanvasNodeType.connector, label: 'Connector', icon: Icons.circle_outlined, color: AppColors.pastelCyanLight),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppSpacing.roundedMd,
        boxShadow: AppSpacing.floatingControlShadow,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          return InkWell(
            onTap: () => _addNode(item.type),
            borderRadius: AppSpacing.roundedSm,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, size: 22, color: item.color),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 9,
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
    );
  }

  // Left Tool Rail (Select, Pan, Line, Text, Sticky, Image)
  Widget _buildLeftToolRail(bool isDark) {
    final tools = [
      (id: 'select', icon: Icons.near_me_outlined),
      (id: 'pan', icon: Icons.pan_tool_outlined),
      (id: 'connect', icon: Icons.trending_flat_rounded),
      (id: 'text', icon: Icons.title_rounded),
      (id: 'sticky', icon: Icons.sticky_note_2_outlined),
      (id: 'image', icon: Icons.image_outlined),
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
          return IconButton(
            icon: Icon(
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
            onPressed: () => setState(() => _activeTool = tool.id),
          );
        }).toList(),
      ),
    );
  }

  // Right Zoom Controls (+, -, fit)
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
              final matrix = _transformationController.value.clone()..scaleByDouble(1.25);
              _transformationController.value = matrix;
            },
            tooltip: 'Zoom In',
          ),
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 20),
            onPressed: () {
              final matrix = _transformationController.value.clone()..scaleByDouble(0.8);
              _transformationController.value = matrix;
            },
            tooltip: 'Zoom Out',
          ),

        ],
      ),
    );
  }

  // Bottom Controls Bar (Minimap, Grid switch, Zoom percentage)
  Widget _buildBottomControlsBar(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Minimap thumbnail placeholder
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

        // Controls Box (Grid toggle + Zoom percentage)
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

  // Interactive Flowchart Node Rendering
  Widget _buildNodeWidget(CanvasNode node, bool isDark) {
    final palette = AppColors.getPaletteById(node.paletteId);
    final isSelected = _selectedNodeId == node.id;

    Color fillColor = palette.softBackground;
    Color strokeColor = palette.lightColor;

    if (isDark) {
      fillColor = palette.darkColor.withValues(alpha: 0.6);
      strokeColor = palette.lightColor;
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
            border: Border.all(color: strokeColor, width: isSelected ? 2.5 : 1.5),
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
                angle: 0.785398, // 45 degrees for diamond
                child: Container(
                  width: node.height * 0.85,
                  height: node.height * 0.85,
                  decoration: BoxDecoration(
                    color: fillColor,
                    border: Border.all(color: strokeColor, width: isSelected ? 2.5 : 1.5),
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
              border: Border.all(color: strokeColor, width: isSelected ? 2.5 : 1.5),
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

      case CanvasNodeType.process:
      default:
        shapeContent = Container(
          width: node.width,
          height: node.height,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: strokeColor, width: isSelected ? 2.5 : 1.5),
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
          setState(() {
            _selectedNodeId = node.id;
            if (_activeTool == 'connect') {
              if (_connectingFromNodeId == null) {
                _connectingFromNodeId = node.id;
              } else if (_connectingFromNodeId != node.id) {
                _edges.add(CanvasEdge(
                  id: 'edge_${DateTime.now().millisecondsSinceEpoch}',
                  fromNodeId: _connectingFromNodeId!,
                  toNodeId: node.id,
                ));
                _connectingFromNodeId = null;
                _saveCanvasState();
              }
            }
          });
        },
        onDoubleTap: () => _editNodeText(node),
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
        onPanEnd: (_) => _saveCanvasState(),
        child: shapeContent,
      ),
    );
  }
}

/// Canvas Grid & Flowchart Connector Lines Painter
class _CanvasGridAndEdgesPainter extends CustomPainter {
  final List<CanvasNode> nodes;
  final List<CanvasEdge> edges;
  final bool showGrid;
  final bool isDark;

  _CanvasGridAndEdgesPainter({
    required this.nodes,
    required this.edges,
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
    final linePaint = Paint()
      ..color = isDark ? Colors.white70 : const Color(0xFF1E293B)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final arrowPaint = Paint()
      ..color = isDark ? Colors.white70 : const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    for (final edge in edges) {
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

      if (edge.fromPort == 'right') start = from.rightPort;
      if (edge.toPort == 'left') end = to.leftPort;

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
