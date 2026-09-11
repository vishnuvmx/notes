import 'base_item.dart';

/// Concrete Sticky Note model inheriting from BaseWorkspaceItem.
class StickyNote extends BaseWorkspaceItem {
  final String content;
  final double rotationAngle; // Slight playful skew angle in radians
  final int priority; // 0 = normal, 1 = important, 2 = urgent

  const StickyNote({
    required super.id,
    required super.title,
    required super.createdAt,
    required super.updatedAt,
    required super.paletteId,
    super.isFavorite,
    super.isArchived,
    super.isTrash,
    required this.content,
    this.rotationAngle = 0.0,
    this.priority = 0,
  }) : super(type: ItemType.sticky);

  @override
  String getSummary() {
    if (content.trim().isEmpty) return title;
    final snippet = content
        .replaceAll(RegExp(r'^\s*#+\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\[[ xX]\]'), '')
        .replaceAll(RegExp(r'[*_~=`]+'), '')
        .replaceAll(RegExp(r'</?[a-zA-Z0-9]+>'), '')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return snippet.length > 80 ? '${snippet.substring(0, 80)}...' : snippet;
  }

  @override
  StickyNote copyWith({
    String? title,
    DateTime? updatedAt,
    String? paletteId,
    bool? isFavorite,
    bool? isArchived,
    bool? isTrash,
    String? content,
    double? rotationAngle,
    int? priority,
  }) {
    return StickyNote(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paletteId: paletteId ?? this.paletteId,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      isTrash: isTrash ?? this.isTrash,
      content: content ?? this.content,
      rotationAngle: rotationAngle ?? this.rotationAngle,
      priority: priority ?? this.priority,
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
      'content': content,
      'rotationAngle': rotationAngle,
      'priority': priority,
    };
  }

  factory StickyNote.fromJson(Map<String, dynamic> json) {
    return StickyNote(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      paletteId: json['paletteId'] as String? ?? 'amber',
      isFavorite: json['isFavorite'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      isTrash: json['isTrash'] as bool? ?? false,
      content: json['content'] as String? ?? '',
      rotationAngle: (json['rotationAngle'] as num?)?.toDouble() ?? 0.0,
      priority: json['priority'] as int? ?? 0,
    );
  }
}
