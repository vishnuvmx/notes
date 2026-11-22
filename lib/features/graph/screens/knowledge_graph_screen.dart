import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/routing/tack_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tack_icons.dart';
import '../../../shared/models/base_item.dart';
import '../../notes/models/text_note.dart';
import '../../whiteboard/models/whiteboard_item.dart';
import '../../notes/services/wiki_link_service.dart';
import '../../../shared/providers/workspace_provider.dart';
import '../../../shared/widgets/app_search_field.dart';
import '../../../shared/widgets/tactile_ink_target.dart';
import '../../notes/screens/note_editor_screen.dart';
import '../../whiteboard/screens/whiteboard_canvas_screen.dart';

enum _GraphEdgeKind { wikiLink, specBoard, hierarchy, tag }

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

/// Interactive 2D Local & Global Knowledge Graph (100% offline).
/// Visualizes `[[Wiki-Links]]`, `![[Embeds]]`, Whiteboard Spec Cards, Sub-Note
/// hierarchies, and `#tag` hubs with tactile Neo-Pop styling.
class KnowledgeGraphScreen extends StatefulWidget {
  /// Optional item ID to start in 1-hop Local Graph mode.
  final String? focusItemId;

  const KnowledgeGraphScreen({super.key, this.focusItemId});

  @override
  State<KnowledgeGraphScreen> createState() => _KnowledgeGraphScreenState();
}

class _KnowledgeGraphScreenState extends State<KnowledgeGraphScreen> {
  static const double _kCanvasSize = 1800.0;
  final TransformationController _transformController =
      TransformationController();
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
    _transformController.value = Matrix4.identity()
      ..setTranslationRaw(tx, ty, 0.0);
  }

  void _rebuildGraphIfNeeded(List<BaseWorkspaceItem> rawItems) {
    final activeItems = rawItems
        .where(
          (i) =>
              !i.isTrash &&
              !i.isArchived &&
              i.type != ItemType.clipboard &&
              (_showBoards || i.type != ItemType.whiteboard),
        )
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
      final ordered = a.compareTo(b) < 0
          ? '$a->$b:${kind.name}'
          : '$b->$a:${kind.name}';
      if (edgeKeys.add(ordered)) {
        edgeList.add(_GraphEdge(sourceId: a, targetId: b, kind: kind));
      }
    }

    // 2. Build edges from Wiki-Links, Spec Cards, Sub-Note parentId, and #tags
    for (final item in activeItems) {
      // Parent -> Sub-note hierarchy
      if (_showHierarchy &&
          item.parentId != null &&
          nodeMap.containsKey(item.parentId)) {
        addEdge(item.parentId!, item.id, _GraphEdgeKind.hierarchy);
      }

      if (item is WhiteboardCanvasItem) {
        for (final cNode in item.nodes) {
          if (cNode.linkedNoteId != null &&
              nodeMap.containsKey(cNode.linkedNoteId)) {
            addEdge(item.id, cNode.linkedNoteId!, _GraphEdgeKind.specBoard);
          }
          for (final wl in WikiLinkService.extractAllLinks(cNode.text)) {
            final target = WikiLinkService.resolveTarget(
              wl.target,
              activeItems,
            );
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
          nodeMap.putIfAbsent(tagId, () {
            final hash = clean.codeUnits.fold<int>(0, (a, b) => a * 31 + b);
            final angle = (hash % 360) * (math.pi / 180.0);
            return _GraphNode(
              id: tagId,
              label: '#$clean',
              paletteId: 'lime',
              isTagHub: true,
              position:
                  center + Offset(math.cos(angle) * 260, math.sin(angle) * 260),
            );
          });
          addEdge(item.id, tagId, _GraphEdgeKind.tag);
        }
      }
    }

    // 3. Filter for 1-Hop Local Graph if enabled
    var filteredNodes = nodeMap.values.toList();
    var filteredEdges = edgeList;

    if (_isLocalMode &&
        widget.focusItemId != null &&
        nodeMap.containsKey(widget.focusItemId)) {
      final focusId = widget.focusItemId!;
      final keepIds = <String>{focusId};
      for (final e in edgeList) {
        if (e.sourceId == focusId) keepIds.add(e.targetId);
        if (e.targetId == focusId) keepIds.add(e.sourceId);
      }
      filteredNodes = filteredNodes
          .where((n) => keepIds.contains(n.id))
          .toList();
      filteredEdges = edgeList
          .where(
            (e) => keepIds.contains(e.sourceId) && keepIds.contains(e.targetId),
          )
          .toList();
    } else if (!_showOrphans) {
      final connectedIds = <String>{};
      for (final e in filteredEdges) {
        connectedIds.add(e.sourceId);
        connectedIds.add(e.targetId);
      }
      filteredNodes = filteredNodes
          .where((n) => connectedIds.contains(n.id))
          .toList();
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
        final targetLen = edge.kind == _GraphEdgeKind.tag
            ? idealSpringLen * 1.15
            : idealSpringLen;
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
      final rawTag = node.label.startsWith('#')
          ? node.label.substring(1)
          : node.label;
      if (workspace.selectedTag?.toLowerCase() != rawTag.toLowerCase()) {
        workspace.setSelectedTag(rawTag);
      }
      workspace.setBottomNavIndex(1);
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    final item = node.item;
    if (item == null) return;
    HapticFeedback.mediumImpact();
    if (item is WhiteboardCanvasItem) {
      Navigator.of(context).push(
        TackRoutes.sharedAxisHorizontal(WhiteboardCanvasScreen(item: item)),
      );
    } else {
      Navigator.of(context)
          .push(TackRoutes.sharedAxisHorizontal(NoteEditorScreen(item: item)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = tokens.isDark;
    final workspace = context.watch<WorkspaceProvider>();
    _rebuildGraphIfNeeded(workspace.rawItems);

    final selectedNode = _selectedNodeId == null
        ? null
        : _nodes.cast<_GraphNode?>().firstWhere(
            (n) => n?.id == _selectedNodeId,
            orElse: () => null,
          );

    final hasFiltersActive =
        !_showTags || !_showBoards || !_showHierarchy || !_showOrphans;
    final hasSearchMiss =
        _query.isNotEmpty &&
        _nodes.isNotEmpty &&
        !_nodes.any((n) => n.label.toLowerCase().contains(_query));
    final textScale = MediaQuery.textScalerOf(context)
        .scale(1.0)
        .clamp(1.0, 1.3);

    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSearching) {
          setState(() {
            _isSearching = false;
            _searchController.clear();
            _query = '';
          });
        }
      },
      child: Scaffold(
        backgroundColor: tokens.canvasPrimary,
        appBar: AppBar(
          backgroundColor: tokens.surfacePrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: TackIcon(TackIcons.back, size: 20, color: tokens.textPrimary),
            onPressed: () {
              if (_isSearching) {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _query = '';
                });
              } else {
                Navigator.of(context).pop();
              }
            },
            tooltip: 'Back',
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isLocalMode ? 'Local Graph' : 'Knowledge Graph',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleSm(
                  color: tokens.textPrimary,
                  weight: FontWeight.w800,
                ),
              ),
              Text(
                '${_nodes.length} nodes · ${_edges.length} links',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption(
                  color: tokens.textTertiary,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            if (widget.focusItemId != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s1),
                child: TactileFilterPill(
                  label: _isLocalMode ? '1-Hop' : 'Global',
                  semanticsLabel: _isLocalMode
                      ? 'Showing 1-hop local graph'
                      : 'Showing global graph',
                  isSelected: _isLocalMode,
                  unselectedColor: tokens.canvasSunken,
                  unselectedFg: tokens.textPrimary,
                  selectedBorderColor: tokens.actionPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s3,
                    vertical: AppSpacing.s1 + 4,
                  ),
                  textStyle: AppTypography.caption(
                    color: _isLocalMode
                        ? tokens.actionPrimaryFg
                        : tokens.textPrimary,
                    weight: FontWeight.w700,
                  ),
                  onTap: () {
                    setState(() {
                      _isLocalMode = !_isLocalMode;
                      _lastGraphSignature = '';
                    });
                  },
                ),
              ),
            IconButton(
              icon: TackIcon(
                _isSearching ? TackIcons.close : TackIcons.search,
                size: 20,
                color: tokens.textPrimary,
              ),
              tooltip: _isSearching ? 'Close filter' : 'Filter Graph',
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
              icon: TackIcon(
                TackIcons.expandNavigation,
                size: 20,
                color: tokens.textPrimary,
              ),
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
            if (workspace.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_nodes.isEmpty)
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.s7,
                    _isSearching ? 120 : 72,
                    AppSpacing.s7,
                    AppSpacing.s7,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TackIcon(
                          TackIcons.graph,
                          size: 48,
                          color: tokens.textTertiary,
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        Text(
                          hasFiltersActive
                              ? 'No nodes match current filters'
                              : (_isLocalMode
                                    ? 'No local connections yet'
                                    : 'No connected notes yet'),
                          textAlign: TextAlign.center,
                          style: AppTypography.title(color: tokens.textPrimary),
                        ),
                        const SizedBox(height: AppSpacing.s2),
                        Text(
                          hasFiltersActive
                              ? 'Reset one or more graph filters to see notes and boards again.'
                              : (_isLocalMode
                                    ? 'Add [[Wiki-Links]], #tags, or switch to the Global Graph.'
                                    : 'Link notes with [[Wiki-Links]], embed boards with ![[Board]], or add #tags to grow your knowledge graph.'),
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySm(
                            color: tokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s5),
                        if (hasFiltersActive)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(
                                0,
                                AppSpacing.minTouchTarget,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _showTags = true;
                                _showBoards = true;
                                _showHierarchy = true;
                                _showOrphans = true;
                                _lastGraphSignature = '';
                              });
                            },
                            child: const Text('Reset filters'),
                          )
                        else if (_isLocalMode)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(
                                0,
                                AppSpacing.minTouchTarget,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _isLocalMode = false;
                                _lastGraphSignature = '';
                              });
                            },
                            child: const Text('Show Global Graph'),
                          )
                        else
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(
                                0,
                                AppSpacing.minTouchTarget,
                              ),
                            ),
                            icon: TackIcon(
                              TackIcons.back,
                              size: 16,
                              color: tokens.textPrimary,
                            ),
                            label: const Text('Back to Notes'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                      ],
                    ),
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
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _KnowledgeGraphPainter(
                          nodes: _nodes,
                          edges: _edges,
                          selectedNodeId: _selectedNodeId,
                          searchQuery: _query,
                          tokens: tokens,
                          textScale: textScale,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Top Filter Chips & Search Bar
            Positioned(
              top: AppSpacing.s2,
              left: AppSpacing.s4,
              right: AppSpacing.s4,
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isSearching)
                      AppSearchField(
                        controller: _searchController,
                        autofocus: true,
                        hintText: 'Highlight node by title or #tag...',
                        margin: const EdgeInsets.only(bottom: AppSpacing.s2),
                        onChanged: (val) =>
                            setState(() => _query = val.trim().toLowerCase()),
                        onClear: () => setState(() => _query = ''),
                      ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: '#Tags',
                            active: _showTags,
                            tokens: tokens,
                            onTap: () => setState(() {
                              _showTags = !_showTags;
                              _lastGraphSignature = '';
                            }),
                          ),
                          const SizedBox(width: AppSpacing.s2),
                          _buildFilterChip(
                            label: 'Boards',
                            active: _showBoards,
                            tokens: tokens,
                            onTap: () => setState(() {
                              _showBoards = !_showBoards;
                              _lastGraphSignature = '';
                            }),
                          ),
                          const SizedBox(width: AppSpacing.s2),
                          _buildFilterChip(
                            label: 'Sub-notes',
                            active: _showHierarchy,
                            tokens: tokens,
                            onTap: () => setState(() {
                              _showHierarchy = !_showHierarchy;
                              _lastGraphSignature = '';
                            }),
                          ),
                          if (!_isLocalMode) ...[
                            const SizedBox(width: AppSpacing.s2),
                            _buildFilterChip(
                              label: 'Orphans',
                              active: _showOrphans,
                              tokens: tokens,
                              onTap: () => setState(() {
                                _showOrphans = !_showOrphans;
                                _lastGraphSignature = '';
                              }),
                            ),
                          ],
                          if (hasFiltersActive) ...[
                            const SizedBox(width: AppSpacing.s2),
                            _buildFilterChip(
                              label: 'Reset',
                              active: false,
                              tokens: tokens,
                              onTap: () => setState(() {
                                _showTags = true;
                                _showBoards = true;
                                _showHierarchy = true;
                                _showOrphans = true;
                                _lastGraphSignature = '';
                              }),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (hasSearchMiss) ...[
                      const SizedBox(height: AppSpacing.s2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s3,
                          vertical: AppSpacing.s1,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.surfacePrimary,
                          borderRadius: AppSpacing.roundedPill,
                          border: Border.all(color: tokens.borderSubtle),
                          boxShadow: AppSpacing.elev1(isDark),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'No nodes match "$_query"',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption(
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s2),
                            TactileInkTarget(
                              semanticsLabel: 'Clear graph search',
                              borderRadius: AppSpacing.roundedPill,
                              height: 32,
                              minWidth: AppSpacing.minTouchTarget,
                              minHeight: AppSpacing.minTouchTarget,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s3,
                              ),
                              color: tokens.canvasSunken,
                              triggerHaptics: true,
                              onTap: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              child: Text(
                                'Clear',
                                style: AppTypography.caption(
                                  color: tokens.textPrimary,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Selected Node Card
            if (selectedNode != null)
              Positioned(
                left: AppSpacing.s4,
                right: AppSpacing.s4,
                bottom: AppSpacing.s4,
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSpacing.readMaxWidth,
                      ),
                      child: _buildSelectedNodeDock(selectedNode, tokens),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool active,
    required TackTokens tokens,
    required VoidCallback onTap,
  }) {
    final fg = active ? tokens.actionPrimaryFg : tokens.textPrimary;
    return TactileFilterPill(
      label: label,
      isSelected: active,
      onTap: onTap,
      unselectedColor: tokens.surfacePrimary.withValues(alpha: 0.94),
      unselectedFg: tokens.textPrimary,
      selectedBorderColor: tokens.actionPrimary,
      unselectedBorderColor: tokens.borderSubtle,
      borderWidth: 1.2,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s2,
      ),
      textStyle: AppTypography.label(color: fg, weight: FontWeight.w700),
    );
  }

  Widget _buildSelectedNodeDock(_GraphNode node, TackTokens tokens) {
    final palette = AppColors.getPaletteById(node.paletteId);
    final accent = palette.resolveAccentColor(tokens.isDark);
    final item = node.item;
    final subtitle = node.isTagHub
        ? '${node.degree} tagged notes · Open in Library'
        : '${node.degree} connections${(item?.getSummary().trim().isNotEmpty ?? false) ? ' · ${item!.getSummary()}' : ''}';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: ShapeDecoration(
        color: tokens.surfacePrimary,
        shape: SmoothRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          smoothness: AppSpacing.defaultSmoothing,
          side: BorderSide(color: tokens.borderSubtle, width: 1.0),
        ),
        shadows: AppSpacing.elev2(tokens.isDark),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: palette.resolveSoftBackground(tokens.isDark),
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(color: accent.withValues(alpha: 0.45)),
            ),
            child: Center(
              child: node.iconEmoji != null && node.iconEmoji!.isNotEmpty
                  ? Text(
                      node.iconEmoji!,
                      style: AppTypography.titleSm(color: tokens.textPrimary),
                    )
                  : TackIcon(
                      node.isTagHub
                          ? TackIcons.tag
                          : (item is WhiteboardCanvasItem
                                ? TackIcons.workflow
                                : TackIcons.notes),
                      size: 19,
                      color: accent,
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  node.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSm(color: tokens.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(color: tokens.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          ElevatedButton(
            onPressed: () => _openNodeItem(node),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, AppSpacing.minTouchTarget),
              backgroundColor: tokens.actionPrimary,
              foregroundColor: tokens.actionPrimaryFg,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              shape: const RoundedRectangleBorder(
                borderRadius: AppSpacing.roundedPill,
              ),
            ),
            child: const Text('Open'),
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
  final TackTokens tokens;
  final double textScale;

  _KnowledgeGraphPainter({
    required this.nodes,
    required this.edges,
    required this.selectedNodeId,
    required this.searchQuery,
    required this.tokens,
    required this.textScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = tokens.isDark;
    // 1. Subtle tactile dot matrix
    final gridPaint = Paint()
      ..color = tokens.textPrimary.withValues(alpha: isDark ? 0.05 : 0.06);
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

      final isHighlighted =
          selectedNodeId != null &&
          (edge.sourceId == selectedNodeId || edge.targetId == selectedNodeId);
      final isDimmed = selectedNodeId != null && !isHighlighted;

      Color edgeColor;
      switch (edge.kind) {
        case _GraphEdgeKind.wikiLink:
          edgeColor = isHighlighted ? tokens.accentPin : tokens.textSecondary;
          break;
        case _GraphEdgeKind.specBoard:
          edgeColor = AppColors.getPaletteById('cyan')
              .resolveAccentColor(isDark);
          break;
        case _GraphEdgeKind.hierarchy:
          edgeColor = AppColors.getPaletteById('lavender')
              .resolveAccentColor(isDark);
          break;
        case _GraphEdgeKind.tag:
          edgeColor = tokens.textTertiary;
          break;
      }

      final paint = Paint()
        ..color = edgeColor.withValues(
          alpha: isDimmed ? 0.14 : (isHighlighted ? 0.92 : 0.45),
        )
        ..strokeWidth = isHighlighted
            ? 2.4
            : (edge.kind == _GraphEdgeKind.tag ? 1.1 : 1.6)
        ..style = PaintingStyle.stroke;

      canvas.drawLine(a.position, b.position, paint);
    }

    // 3. Draw nodes & crisp labels
    for (final node in nodes) {
      final isSelected = node.id == selectedNodeId;
      final matchesSearch =
          searchQuery.isNotEmpty &&
          node.label.toLowerCase().contains(searchQuery);
      final isDimmed =
          (selectedNodeId != null && !activeNeighbors.contains(node.id)) ||
          (searchQuery.isNotEmpty && !matchesSearch);

      final palette = AppColors.getPaletteById(node.paletteId);
      final fillColor = node.isTagHub
          ? AppColors.getPaletteById('lime').resolveSoftBackground(isDark)
          : palette.resolveCardColor(isDark);
      final strokeColor = isSelected || matchesSearch
          ? tokens.accentPin
          : (isDark ? palette.lightColor : tokens.textPrimary);

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
          Paint()..color = tokens.accentPin.withValues(alpha: 0.22),
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
          node.position -
              Offset(emojiPainter.width / 2, emojiPainter.height / 2),
        );
      }

      // Label below node
      final baseLabelSize = (node.isTagHub ? 12.0 : 12.5) * textScale;
      final labelPainter = TextPainter(
        text: TextSpan(
          text: node.label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: baseLabelSize,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
            letterSpacing: -0.25,
            color: tokens.textPrimary.withValues(alpha: isDimmed ? 0.28 : 0.92),
          ),
        ),
        maxLines: 1,
        ellipsis: '…',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 148 * textScale);

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
        oldDelegate.tokens != tokens ||
        oldDelegate.textScale != textScale;
  }
}
