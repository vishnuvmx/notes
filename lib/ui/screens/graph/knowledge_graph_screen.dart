import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../domain/models/base_item.dart';
import '../../../domain/models/text_note.dart';
import '../../../domain/models/whiteboard_item.dart';
import '../../../domain/services/wiki_link_service.dart';
import '../../../state/workspace_provider.dart';
import '../editor/note_editor_screen.dart';
import '../whiteboard/whiteboard_canvas_screen.dart';

enum _GraphEdgeKind {
  wikiLink,
  specBoard,
  hierarchy,
  tag,
}

class _GraphNode {
  final String id;
  final String label;
  final String? iconEmoji;
  final String paletteId;
  final BaseWorkspaceItem? item;
  final bool isTagHub;
  Offset position;
  int degree;

  _GraphNode({
    required this.id,
    required this.label,
    required this.paletteId,
    required this.position,
    this.iconEmoji,
    this.item,
    this.isTagHub = false,
  }) : degree = 0;

  double get radius {
    if (isTagHub) return (11.0 + math.min(degree * 1.4, 8.0));
    return (16.0 + math.min(degree * 2.2, 14.0));
  }
}

class _GraphEdge {
  final String sourceId;
  final String targetId;
  final _GraphEdgeKind kind;

  const _GraphEdge({
    required this.sourceId,
    required this.targetId,
    required this.kind,
  });
}

/// Interactive 2D Local & Global Knowledge Graph (Obsidian-inspired, 100% offline).
/// Visualizes `[[Wiki-Links]]`, `![[Embeds]]`, Whiteboard Spec Cards, Sub-Note
/// hierarchies, and `#tag` hubs with tactile Neo-Pop styling.
class KnowledgeGraphScreen extends StatefulWidget {
  /// Optional item ID to start in 1-hop Local Graph mode.
  final String? focusItemId;

  const KnowledgeGraphScreen({
    super.key,
    this.focusItemId,
  });

  @override
  State<KnowledgeGraphScreen> createState() => _KnowledgeGraphScreenState();
}

class _KnowledgeGraphScreenState extends State<KnowledgeGraphScreen> {
  static const double _kCanvasSize = 1800.0;
  final TransformationController _transformController = TransformationController();
  final TextEditingController _searchController = TextEditingController();

  late bool _isLocalMode;
  bool _showTags = true;
  bool _showBoards = true;
  bool _showHierarchy = true;
  bool _showOrphans = true;
  bool _isSearching = false;
  String _query = '';
  String? _selectedNodeId;

  List<_GraphNode> _nodes = const [];
  List<_GraphEdge> _edges = const [];
  String _lastGraphSignature = '';

  @override
  void initState() {
    super.initState();
    _isLocalMode = widget.focusItemId != null;
    _selectedNodeId = widget.focusItemId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerCamera();
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _centerCamera() {
    if (!mounted) return;
    final size = MediaQuery.sizeOf(context);
    final tx = (size.width / 2) - (_kCanvasSize / 2);
    final ty = ((size.height - 160) / 2) - (_kCanvasSize / 2);
    _transformController.value = Matrix4.identity()..setTranslationRaw(tx, ty, 0.0);
  }

  void _rebuildGraphIfNeeded(List<BaseWorkspaceItem> rawItems) {
    final activeItems = rawItems
        .where((i) =>
            !i.isTrash &&
            !i.isArchived &&
            i.type != ItemType.clipboard &&
            (_showBoards || i.type != ItemType.whiteboard))
        .toList();

    final sig =
        '${activeItems.map((e) => '${e.id}:${e.updatedAt.millisecondsSinceEpoch}:${e.parentId}:${e.title}').join('|')}'
        '$_isLocalMode|${widget.focusItemId}|$_showTags|$_showBoards|$_showHierarchy|$_showOrphans';
    if (sig == _lastGraphSignature) return;
    _lastGraphSignature = sig;

    final nodeMap = <String, _GraphNode>{};
    final edgeList = <_GraphEdge>[];
    final edgeKeys = <String>{};

    const center = Offset(_kCanvasSize / 2, _kCanvasSize / 2);

    // 1. Seed workspace item nodes deterministically on a spiral
    for (int i = 0; i < activeItems.length; i++) {
      final item = activeItems[i];
      final angle = i * 2.39996323; // Golden angle
      final dist = 90.0 + 36.0 * math.sqrt(i + 1);
      final initialPos = item.id == widget.focusItemId
          ? center
          : center + Offset(math.cos(angle) * dist, math.sin(angle) * dist);
      nodeMap[item.id] = _GraphNode(
        id: item.id,
        label: item.title.isEmpty ? 'Untitled' : item.title,
        iconEmoji: item.iconEmoji,
        paletteId: item.paletteId,
        item: item,
        position: initialPos,
      );
    }

    void addEdge(String a, String b, _GraphEdgeKind kind) {
      if (a == b || !nodeMap.containsKey(a) || !nodeMap.containsKey(b)) return;
      final ordered = a.compareTo(b) < 0 ? '$a->$b:${kind.name}' : '$b->$a:${kind.name}';
      if (edgeKeys.add(ordered)) {
        edgeList.add(_GraphEdge(sourceId: a, targetId: b, kind: kind));
      }
    }

    // 2. Build edges from Wiki-Links, Spec Cards, Sub-Note parentId, and #tags
    for (final item in activeItems) {
      // Parent -> Sub-note hierarchy
      if (_showHierarchy && item.parentId != null && nodeMap.containsKey(item.parentId)) {
        addEdge(item.parentId!, item.id, _GraphEdgeKind.hierarchy);
      }

      if (item is WhiteboardCanvasItem) {
        for (final cNode in item.nodes) {
          if (cNode.linkedNoteId != null && nodeMap.containsKey(cNode.linkedNoteId)) {
            addEdge(item.id, cNode.linkedNoteId!, _GraphEdgeKind.specBoard);
          }
          for (final wl in WikiLinkService.extractAllLinks(cNode.text)) {
            final target = WikiLinkService.resolveTarget(wl.target, activeItems);
            if (target != null) {
              addEdge(item.id, target.id, _GraphEdgeKind.specBoard);
            }
          }
        }
      } else {
        final body = WikiLinkService.contentOfItem(item);
        for (final wl in WikiLinkService.extractAllLinks(body)) {
          final target = WikiLinkService.resolveTarget(wl.target, activeItems);
          if (target != null) {
            final kind = target is WhiteboardCanvasItem
                ? _GraphEdgeKind.specBoard
                : _GraphEdgeKind.wikiLink;
            addEdge(item.id, target.id, kind);
          }
        }
      }

      if (_showTags && item is TextNote) {
        for (final rawTag in item.tags) {
          final clean = rawTag.trim().toLowerCase();
          if (clean.isEmpty) continue;
          final tagId = 'tag:#$clean';
          nodeMap.putIfAbsent(
            tagId,
            () {
              final hash = clean.codeUnits.fold<int>(0, (a, b) => a * 31 + b);
              final angle = (hash % 360) * (math.pi / 180.0);
              return _GraphNode(
                id: tagId,
                label: '#$clean',
                paletteId: 'lime',
                isTagHub: true,
                position: center + Offset(math.cos(angle) * 260, math.sin(angle) * 260),
              );
            },
          );
          addEdge(item.id, tagId, _GraphEdgeKind.tag);
        }
      }
    }

    // 3. Filter for 1-Hop Local Graph if enabled
    var filteredNodes = nodeMap.values.toList();
    var filteredEdges = edgeList;

    if (_isLocalMode && widget.focusItemId != null && nodeMap.containsKey(widget.focusItemId)) {
      final focusId = widget.focusItemId!;
      final keepIds = <String>{focusId};
      for (final e in edgeList) {
        if (e.sourceId == focusId) keepIds.add(e.targetId);
        if (e.targetId == focusId) keepIds.add(e.sourceId);
      }
      filteredNodes = filteredNodes.where((n) => keepIds.contains(n.id)).toList();
      filteredEdges = edgeList
          .where((e) => keepIds.contains(e.sourceId) && keepIds.contains(e.targetId))
          .toList();
    } else if (!_showOrphans) {
      final connectedIds = <String>{};
      for (final e in filteredEdges) {
        connectedIds.add(e.sourceId);
        connectedIds.add(e.targetId);
      }
      filteredNodes = filteredNodes.where((n) => connectedIds.contains(n.id)).toList();
    }

    // Recompute degrees
    final degMap = <String, int>{};
    for (final e in filteredEdges) {
      degMap[e.sourceId] = (degMap[e.sourceId] ?? 0) + 1;
      degMap[e.targetId] = (degMap[e.targetId] ?? 0) + 1;
    }
    for (final n in filteredNodes) {
      n.degree = degMap[n.id] ?? 0;
    }

    // 4. Run fast deterministic spring-repulsion simulation
    _runForceSimulation(filteredNodes, filteredEdges, center);

    _nodes = filteredNodes;
    _edges = filteredEdges;
  }

  void _runForceSimulation(
    List<_GraphNode> nodes,
    List<_GraphEdge> edges,
    Offset center,
  ) {
    if (nodes.length <= 1) {
      if (nodes.length == 1) nodes.first.position = center;
      return;
    }

    final byId = {for (final n in nodes) n.id: n};
    const int iterations = 70;
    const double repulsion = 9200.0;
    const double idealSpringLen = 148.0;
    const double springK = 0.045;
    const double centerPull = 0.018;

    for (int step = 0; step < iterations; step++) {
      final cooling = 1.0 - (step / iterations) * 0.72;
      final forces = <String, Offset>{for (final n in nodes) n.id: Offset.zero};

      // Pairwise Coulomb repulsion
      for (int i = 0; i < nodes.length; i++) {
        for (int j = i + 1; j < nodes.length; j++) {
          final a = nodes[i];
          final b = nodes[j];
          var delta = a.position - b.position;
          var distSq = delta.dx * delta.dx + delta.dy * delta.dy;
          if (distSq < 16.0) {
            delta = const Offset(4.0, 1.5);
            distSq = 18.25;
          }
          final dist = math.sqrt(distSq);
          final forceMag = (repulsion / distSq).clamp(0.0, 55.0);
          final unit = delta / dist;
          forces[a.id] = forces[a.id]! + unit * forceMag;
          forces[b.id] = forces[b.id]! - unit * forceMag;
        }
      }

      // Hooke spring attraction along edges
      for (final edge in edges) {
        final a = byId[edge.sourceId];
        final b = byId[edge.targetId];
        if (a == null || b == null) continue;
        final delta = b.position - a.position;
        final dist = math.max(delta.distance, 1.0);
        final targetLen = edge.kind == _GraphEdgeKind.tag ? idealSpringLen * 1.15 : idealSpringLen;
        final displacement = dist - targetLen;
        final pull = (delta / dist) * (displacement * springK);
        forces[a.id] = forces[a.id]! + pull;
        forces[b.id] = forces[b.id]! - pull;
      }

      // Gentle gravity toward canvas center
      for (final n in nodes) {
        if (_isLocalMode && n.id == widget.focusItemId) {
          n.position = center;
          continue;
        }
        final toCenter = (center - n.position) * centerPull;
        final total = (forces[n.id]! + toCenter) * cooling;
        final clamped = Offset(
          total.dx.clamp(-28.0, 28.0),
          total.dy.clamp(-28.0, 28.0),
        );
        final next = n.position + clamped;
        n.position = Offset(
          next.dx.clamp(120.0, _kCanvasSize - 120.0),
          next.dy.clamp(120.0, _kCanvasSize - 120.0),
        );
      }
    }
  }

  void _handleCanvasTapUp(TapUpDetails details) {
    final localPos = details.localPosition;
    _GraphNode? hit;
    double bestDist = double.infinity;

    for (final node in _nodes) {
      final d = (node.position - localPos).distance;
      final hitRadius = node.radius + 14.0;
      if (d <= hitRadius && d < bestDist) {
        bestDist = d;
        hit = node;
      }
    }

    HapticFeedback.selectionClick();
    setState(() {
      _selectedNodeId = hit?.id;
    });
  }

  void _openNodeItem(_GraphNode node) {
    final workspace = context.read<WorkspaceProvider>();
    if (node.isTagHub) {
      workspace.setSelectedTag(node.label);
      Navigator.of(context).pop();
      return;
    }
    final item = node.item;
    if (item == null) return;
    HapticFeedback.mediumImpact();
    if (item is WhiteboardCanvasItem) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => WhiteboardCanvasScreen(item: item)),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => NoteEditorScreen(item: item)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workspace = context.watch<WorkspaceProvider>();
    _rebuildGraphIfNeeded(workspace.rawItems);

    final selectedNode = _selectedNodeId == null
        ? null
        : _nodes.cast<_GraphNode?>().firstWhere(
              (n) => n?.id == _selectedNodeId,
              orElse: () => null,
            );

    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFF191A23);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const TackIcon(TackIcons.back, size: 22),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isLocalMode ? 'Local Graph' : 'Knowledge Graph',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: isDark ? Colors.white : const Color(0xFF191A23),
              ),
            ),
            Text(
              '${_nodes.length} nodes  •  ${_edges.length} links',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
        actions: [
          if (widget.focusItemId != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: ActionChip(
                label: Text(_isLocalMode ? '1-Hop' : 'Global'),
                labelStyle: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _isLocalMode ? const Color(0xFF191A23) : null,
                ),
                backgroundColor:
                    _isLocalMode ? AppColors.pastelLimeLight : surfaceColor,
                shape: const RoundedRectangleBorder(borderRadius: AppSpacing.roundedPill),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _isLocalMode = !_isLocalMode;
                    _lastGraphSignature = '';
                  });
                },
              ),
            ),
          IconButton(
            icon: Icon(
              _isSearching ? LucideIcons.x : LucideIcons.search,
              size: 19,
            ),
            tooltip: 'Filter Graph',
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _query = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.locateFixed, size: 19),
            tooltip: 'Recenter',
            onPressed: () {
              HapticFeedback.lightImpact();
              _centerCamera();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Interactive 2D Graph Canvas
          if (_nodes.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.network,
                      size: 46,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No connected notes yet',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : const Color(0xFF191A23),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Link notes with [[Wiki-Links]], embed boards with ![[Board]], or add #tags to grow your local knowledge graph.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13.5,
                        height: 1.45,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            InteractiveViewer(
              transformationController: _transformController,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(420),
              minScale: 0.35,
              maxScale: 2.6,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: _handleCanvasTapUp,
                child: SizedBox(
                  width: _kCanvasSize,
                  height: _kCanvasSize,
                  child: CustomPaint(
                    painter: _KnowledgeGraphPainter(
                      nodes: _nodes,
                      edges: _edges,
                      selectedNodeId: _selectedNodeId,
                      searchQuery: _query,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
            ),

          // Top Filter Chips & Search Bar
          Positioned(
            top: 10,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isSearching)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor, width: 1.3),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13.5,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Highlight node by title or #tag...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 11),
                      ),
                      onChanged: (val) => setState(() => _query = val.trim().toLowerCase()),
                    ),
                  ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: '#Tags',
                        active: _showTags,
                        isDark: isDark,
                        onTap: () => setState(() {
                          _showTags = !_showTags;
                          _lastGraphSignature = '';
                        }),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Boards',
                        active: _showBoards,
                        isDark: isDark,
                        onTap: () => setState(() {
                          _showBoards = !_showBoards;
                          _lastGraphSignature = '';
                        }),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Sub-notes',
                        active: _showHierarchy,
                        isDark: isDark,
                        onTap: () => setState(() {
                          _showHierarchy = !_showHierarchy;
                          _lastGraphSignature = '';
                        }),
                      ),
                      if (!_isLocalMode) ...[
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Orphans',
                          active: _showOrphans,
                          isDark: isDark,
                          onTap: () => setState(() {
                            _showOrphans = !_showOrphans;
                            _lastGraphSignature = '';
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Selected Node Card
          if (selectedNode != null)
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
              child: _buildSelectedNodeDock(selectedNode, isDark, surfaceColor, borderColor),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool active,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppColors.pastelLimeLight
              : (isDark ? AppColors.darkSurface.withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.92)),
          borderRadius: AppSpacing.roundedPill,
          border: Border.all(
            color: active
                ? const Color(0xFF191A23)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: active
                ? const Color(0xFF191A23)
                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedNodeDock(
    _GraphNode node,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    final palette = AppColors.getPaletteById(node.paletteId);
    final accent = palette.resolveAccentColor(isDark);
    final item = node.item;
    final subtitle = node.isTagHub
        ? '${node.degree} tagged notes  •  Tap Open to filter feed'
        : '${node.degree} connections  •  ${item?.getSummary() ?? ''}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: palette.lightColor.withValues(alpha: isDark ? 0.22 : 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: node.iconEmoji != null && node.iconEmoji!.isNotEmpty
                  ? Text(node.iconEmoji!, style: const TextStyle(fontSize: 18))
                  : Icon(
                      node.isTagHub
                          ? LucideIcons.hash
                          : (item is WhiteboardCanvasItem
                              ? LucideIcons.workflow
                              : LucideIcons.fileText),
                      size: 18,
                      color: accent,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  node.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : const Color(0xFF191A23),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => _openNodeItem(node),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : const Color(0xFF191A23),
              foregroundColor: isDark ? const Color(0xFF191A23) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Open →',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KnowledgeGraphPainter extends CustomPainter {
  final List<_GraphNode> nodes;
  final List<_GraphEdge> edges;
  final String? selectedNodeId;
  final String searchQuery;
  final bool isDark;

  _KnowledgeGraphPainter({
    required this.nodes,
    required this.edges,
    required this.selectedNodeId,
    required this.searchQuery,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Subtle tactile dot matrix
    final gridPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.05)
          : const Color(0xFF191A23).withValues(alpha: 0.06);
    const step = 36.0;
    for (double x = step; x < size.width; x += step) {
      for (double y = step; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.1, gridPaint);
      }
    }

    final nodeMap = {for (final n in nodes) n.id: n};
    final activeNeighbors = <String>{};
    if (selectedNodeId != null) {
      activeNeighbors.add(selectedNodeId!);
      for (final e in edges) {
        if (e.sourceId == selectedNodeId) activeNeighbors.add(e.targetId);
        if (e.targetId == selectedNodeId) activeNeighbors.add(e.sourceId);
      }
    }

    // 2. Draw edges
    for (final edge in edges) {
      final a = nodeMap[edge.sourceId];
      final b = nodeMap[edge.targetId];
      if (a == null || b == null) continue;

      final isHighlighted = selectedNodeId != null &&
          (edge.sourceId == selectedNodeId || edge.targetId == selectedNodeId);
      final isDimmed = selectedNodeId != null && !isHighlighted;

      Color edgeColor;
      switch (edge.kind) {
        case _GraphEdgeKind.wikiLink:
          edgeColor = isHighlighted
              ? AppColors.accentAmber
              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569));
          break;
        case _GraphEdgeKind.specBoard:
          edgeColor = AppColors.accentCyan;
          break;
        case _GraphEdgeKind.hierarchy:
          edgeColor = AppColors.pastelLavenderLight;
          break;
        case _GraphEdgeKind.tag:
          edgeColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
          break;
      }

      final paint = Paint()
        ..color = edgeColor.withValues(alpha: isDimmed ? 0.14 : (isHighlighted ? 0.92 : 0.45))
        ..strokeWidth = isHighlighted ? 2.4 : (edge.kind == _GraphEdgeKind.tag ? 1.1 : 1.6)
        ..style = PaintingStyle.stroke;

      canvas.drawLine(a.position, b.position, paint);
    }

    // 3. Draw nodes & crisp labels
    for (final node in nodes) {
      final isSelected = node.id == selectedNodeId;
      final matchesSearch =
          searchQuery.isNotEmpty && node.label.toLowerCase().contains(searchQuery);
      final isDimmed = (selectedNodeId != null && !activeNeighbors.contains(node.id)) ||
          (searchQuery.isNotEmpty && !matchesSearch);

      final palette = AppColors.getPaletteById(node.paletteId);
      final fillColor = node.isTagHub
          ? (isDark ? const Color(0xFF283018) : AppColors.pastelLimeSoft)
          : palette.resolveCardColor(isDark);
      final strokeColor = isSelected || matchesSearch
          ? AppColors.accentAmber
          : (isDark ? palette.lightColor : const Color(0xFF191A23));

      final r = node.radius;
      final fillPaint = Paint()
        ..color = fillColor.withValues(alpha: isDimmed ? 0.28 : 1.0)
        ..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..color = strokeColor.withValues(alpha: isDimmed ? 0.25 : 1.0)
        ..strokeWidth = isSelected || matchesSearch ? 3.0 : 1.8
        ..style = PaintingStyle.stroke;

      if (isSelected || matchesSearch) {
        canvas.drawCircle(
          node.position,
          r + 6,
          Paint()..color = AppColors.accentAmber.withValues(alpha: 0.22),
        );
      }

      if (node.item is WhiteboardCanvasItem) {
        final rect = Rect.fromCenter(
          center: node.position,
          width: r * 2.1,
          height: r * 1.65,
        );
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
        canvas.drawRRect(rrect, fillPaint);
        canvas.drawRRect(rrect, strokePaint);
      } else {
        canvas.drawCircle(node.position, r, fillPaint);
        canvas.drawCircle(node.position, r, strokePaint);
      }

      // Emoji or inner dot
      if (node.iconEmoji != null && node.iconEmoji!.isNotEmpty) {
        final emojiPainter = TextPainter(
          text: TextSpan(
            text: node.iconEmoji!,
            style: TextStyle(fontSize: r * 0.9),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        emojiPainter.paint(
          canvas,
          node.position - Offset(emojiPainter.width / 2, emojiPainter.height / 2),
        );
      }

      // Label below node
      final labelPainter = TextPainter(
        text: TextSpan(
          text: node.label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: node.isTagHub ? 11.0 : 12.2,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
            letterSpacing: -0.25,
            color: (isDark ? Colors.white : const Color(0xFF191A23))
                .withValues(alpha: isDimmed ? 0.28 : 0.92),
          ),
        ),
        maxLines: 1,
        ellipsis: '…',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 140);

      labelPainter.paint(
        canvas,
        Offset(
          node.position.dx - labelPainter.width / 2,
          node.position.dy + r + 5,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _KnowledgeGraphPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.edges != edges ||
        oldDelegate.selectedNodeId != selectedNodeId ||
        oldDelegate.searchQuery != searchQuery ||
        oldDelegate.isDark != isDark;
  }
}
