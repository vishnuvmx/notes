import 'package:flutter/material.dart';
import 'base_item.dart';

/// Node shape types matching the flowchart editor palette in Screenshot 4.
enum CanvasNodeType {
  startEnd,     // Rounded pill
  process,      // Rectangle
  decision,     // Diamond
  inputOutput,  // Parallelogram
  connector,    // Small circle
  sticky,       // Sticky note shape
  textOnly,     // Floating text
  image,        // Pinned/draggable image node
  specCard;     // Figma-Specs style Markdown Spec / Linked Note card

  String get label {
    switch (this) {
      case CanvasNodeType.startEnd:
        return 'Start / End';
      case CanvasNodeType.process:
        return 'Process';
      case CanvasNodeType.decision:
        return 'Decision';
      case CanvasNodeType.inputOutput:
        return 'Input / Output';
      case CanvasNodeType.connector:
        return 'Connector';
      case CanvasNodeType.sticky:
        return 'Sticky Note';
      case CanvasNodeType.textOnly:
        return 'Text';
      case CanvasNodeType.image:
        return 'Image';
      case CanvasNodeType.specCard:
        return 'Spec Card';
    }
  }
}

/// Canvas node model composed inside WhiteboardCanvasItem.
@immutable
class CanvasNode {
  final String id;
  final String text;
  final CanvasNodeType shapeType;
  final double x;
  final double y;
  final double width;
  final double height;
  final String paletteId;
  final String? imagePath;
  final String? linkedNoteId;

  const CanvasNode({
    required this.id,
    required this.text,
    required this.shapeType,
    required this.x,
    required this.y,
    this.width = 140,
    this.height = 64,
    this.paletteId = 'peach',
    this.imagePath,
    this.linkedNoteId,
  });

  CanvasNode copyWith({
    String? text,
    CanvasNodeType? shapeType,
    double? x,
    double? y,
    double? width,
    double? height,
    String? paletteId,
    String? imagePath,
    String? linkedNoteId,
  }) {
    return CanvasNode(
      id: id,
      text: text ?? this.text,
      shapeType: shapeType ?? this.shapeType,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      paletteId: paletteId ?? this.paletteId,
      imagePath: imagePath ?? this.imagePath,
      linkedNoteId: linkedNoteId ?? this.linkedNoteId,
    );
  }

  Offset get center => Offset(x + width / 2, y + height / 2);
  Offset get topPort => Offset(x + width / 2, y);
  Offset get bottomPort => Offset(x + width / 2, y + height);
  Offset get leftPort => Offset(x, y + height / 2);
  Offset get rightPort => Offset(x + width, y + height / 2);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'shapeType': shapeType.name,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'paletteId': paletteId,
      'imagePath': imagePath,
      if (linkedNoteId != null) 'linkedNoteId': linkedNoteId,
    };
  }

  factory CanvasNode.fromJson(Map<String, dynamic> json) {
    return CanvasNode(
      id: json['id'] as String,
      text: json['text'] as String? ?? '',
      shapeType: CanvasNodeType.values.firstWhere(
        (e) => e.name == json['shapeType'],
        orElse: () => CanvasNodeType.process,
      ),
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 140.0,
      height: (json['height'] as num?)?.toDouble() ?? 64.0,
      paletteId: json['paletteId'] as String? ?? 'peach',
      imagePath: json['imagePath'] as String?,
      linkedNoteId: json['linkedNoteId'] as String?,
    );
  }
}

/// Canvas connector edge between two nodes.
@immutable
class CanvasEdge {
  final String id;
  final String fromNodeId;
  final String toNodeId;
  final String? label; // e.g. "Yes", "No"
  final String fromPort; // 'top', 'bottom', 'left', 'right'
  final String toPort;

  const CanvasEdge({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    this.label,
    this.fromPort = 'bottom',
    this.toPort = 'top',
  });

  CanvasEdge copyWith({
    String? label,
    String? fromPort,
    String? toPort,
  }) {
    return CanvasEdge(
      id: id,
      fromNodeId: fromNodeId,
      toNodeId: toNodeId,
      label: label ?? this.label,
      fromPort: fromPort ?? this.fromPort,
      toPort: toPort ?? this.toPort,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromNodeId': fromNodeId,
      'toNodeId': toNodeId,
      'label': label,
      'fromPort': fromPort,
      'toPort': toPort,
    };
  }

  factory CanvasEdge.fromJson(Map<String, dynamic> json) {
    return CanvasEdge(
      id: json['id'] as String,
      fromNodeId: json['fromNodeId'] as String,
      toNodeId: json['toNodeId'] as String,
      label: json['label'] as String?,
      fromPort: json['fromPort'] as String? ?? 'bottom',
      toPort: json['toPort'] as String? ?? 'top',
    );
  }
}

/// Concrete Whiteboard Canvas model inheriting from BaseWorkspaceItem and composing Nodes and Edges.
class WhiteboardCanvasItem extends BaseWorkspaceItem {
  final List<CanvasNode> nodes;
  final List<CanvasEdge> edges;
  final double zoomScale;
  final Offset panOffset;

  const WhiteboardCanvasItem({
    required super.id,
    required super.title,
    required super.createdAt,
    required super.updatedAt,
    required super.paletteId,
    super.isFavorite,
    super.isArchived,
    super.isTrash,
    super.folderName,
    super.parentId,
    super.iconEmoji,
    this.nodes = const [],
    this.edges = const [],
    this.zoomScale = 1.0,
    this.panOffset = Offset.zero,
  }) : super(type: ItemType.whiteboard);

  @override
  String getSummary() {
    final specCount = nodes.where((n) => n.shapeType == CanvasNodeType.specCard).length;
    if (specCount > 0) {
      return '${nodes.length} nodes ($specCount spec${specCount == 1 ? '' : 's'}), ${edges.length} connections';
    }
    return '${nodes.length} nodes, ${edges.length} connections';
  }

  @override
  bool matchesQuery(String query) {
    if (query.isEmpty) return true;
    final lower = query.toLowerCase();
    final matchInNodes = nodes.any((n) => n.text.toLowerCase().contains(lower));
    return super.matchesQuery(query) || matchInNodes;
  }

  @override
  WhiteboardCanvasItem copyWith({
    String? title,
    DateTime? updatedAt,
    String? paletteId,
    bool? isFavorite,
    bool? isArchived,
    bool? isTrash,
    String? folderName,
    bool clearFolder = false,
    String? parentId,
    bool clearParent = false,
    String? iconEmoji,
    bool clearIcon = false,
    List<CanvasNode>? nodes,
    List<CanvasEdge>? edges,
    double? zoomScale,
    Offset? panOffset,
  }) {
    return WhiteboardCanvasItem(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paletteId: paletteId ?? this.paletteId,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      isTrash: isTrash ?? this.isTrash,
      folderName: clearFolder ? null : (folderName ?? this.folderName),
      parentId: clearParent ? null : (parentId ?? this.parentId),
      iconEmoji: clearIcon ? null : (iconEmoji ?? this.iconEmoji),
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      zoomScale: zoomScale ?? this.zoomScale,
      panOffset: panOffset ?? this.panOffset,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'type': type.name,
      'paletteId': paletteId,
      'isFavorite': isFavorite,
      'isArchived': isArchived,
      'isTrash': isTrash,
      'folderName': folderName,
      'parentId': parentId,
      'iconEmoji': iconEmoji,
      'nodes': nodes.map((n) => n.toJson()).toList(),
      'edges': edges.map((e) => e.toJson()).toList(),
      'zoomScale': zoomScale,
      'panX': panOffset.dx,
      'panY': panOffset.dy,
    };
  }

  factory WhiteboardCanvasItem.fromJson(Map<String, dynamic> json) {
    return WhiteboardCanvasItem(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      paletteId: json['paletteId'] as String? ?? 'cyan',
      isFavorite: json['isFavorite'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      isTrash: json['isTrash'] as bool? ?? false,
      folderName: json['folderName'] as String?,
      parentId: json['parentId'] as String?,
      iconEmoji: json['iconEmoji'] as String?,
      nodes: (json['nodes'] as List<dynamic>?)
              ?.map((n) => CanvasNode.fromJson(Map<String, dynamic>.from(n as Map)))
              .toList() ??
          [],
      edges: (json['edges'] as List<dynamic>?)
              ?.map((e) => CanvasEdge.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      zoomScale: (json['zoomScale'] as num?)?.toDouble() ?? 1.0,
      panOffset: Offset(
        (json['panX'] as num?)?.toDouble() ?? 0.0,
        (json['panY'] as num?)?.toDouble() ?? 0.0,
      ),
    );
  }
}
