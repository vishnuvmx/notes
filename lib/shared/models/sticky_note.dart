import 'base_item.dart';

/// Concrete Sticky Note model inheriting from BaseWorkspaceItem.
/// Legacy sticky notes are migrated and rendered as standard notes with object
/// color bands or placed on Boards (`05-information-architecture.md` §7.2).
class StickyNote extends BaseWorkspaceItem {
  final String content;
  final double rotationAngle;
  final int priority;

  const StickyNote({
    required super.id,
    required super.title,
    required super.createdAt,
    required super.updatedAt,
    required super.paletteId,
    super.isFavorite,
    super.isArchived,
    super.isTrash,
    super.isInbox,
    super.folderName,
    super.parentId,
    super.iconEmoji,
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
  bool matchesQuery(String query) {
    if (query.isEmpty) return true;
    final lower = query.toLowerCase();
    return title.toLowerCase().contains(lower) ||
        content.toLowerCase().contains(lower);
  }

  @override
  StickyNote copyWith({
    String? title,
    DateTime? updatedAt,
    String? paletteId,
    bool? isFavorite,
    bool? isArchived,
    bool? isTrash,
    bool? isInbox,
    String? folderName,
    bool clearFolder = false,
    String? parentId,
    bool clearParent = false,
    String? iconEmoji,
    bool clearIcon = false,
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
      isInbox: isInbox ?? this.isInbox,
      folderName: clearFolder ? null : (folderName ?? this.folderName),
      parentId: clearParent ? null : (parentId ?? this.parentId),
      iconEmoji: clearIcon ? null : (iconEmoji ?? this.iconEmoji),
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
      'isInbox': isInbox,
      'folderName': folderName,
      'parentId': parentId,
      'iconEmoji': iconEmoji,
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
      isInbox: json['isInbox'] as bool? ?? false,
      folderName: json['folderName'] as String?,
      parentId: json['parentId'] as String?,
      iconEmoji: json['iconEmoji'] as String?,
      content: json['content'] as String? ?? '',
      rotationAngle: (json['rotationAngle'] as num?)?.toDouble() ?? 0.0,
      priority: json['priority'] as int? ?? 0,
    );
  }
}
