import '../../../shared/models/base_item.dart';

/// Concrete Text Note model inheriting from BaseWorkspaceItem.
class TextNote extends BaseWorkspaceItem {
  final String content;
  final List<String> tags;
  final List<String> links;
  final int estimatedMinutes;
  final String? sourceApp;

  const TextNote({
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
    this.tags = const [],
    this.links = const [],
    this.estimatedMinutes = 3,
    this.sourceApp,
  }) : super(type: ItemType.note);

  int get letterCount => content.replaceAll(RegExp(r'\s'), '').length;

  int get wordCount {
    if (content.trim().isEmpty) return 0;
    return content.trim().split(RegExp(r'\s+')).length;
  }

  int get lineCount {
    if (content.isEmpty) return 1;
    return content.split('\n').length;
  }

  @override
  String getSummary() {
    if (content.trim().isEmpty) return 'Empty note';
    // Strip YAML frontmatter block if present
    var body = content;
    if (body.startsWith('---\n')) {
      final endIdx = body.indexOf('\n---', 4);
      if (endIdx != -1) {
        body = body.substring(endIdx + 4);
      }
    }
    final cleaned = body
        .replaceAll(RegExp(r'^\s*#+\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\[[ xX]\]'), '')
        .replaceAll(RegExp(r'[*_~=`]+'), '')
        .replaceAll(RegExp(r'</?[a-zA-Z0-9]+>'), '')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return 'Empty note';
    return cleaned.length > 110 ? '${cleaned.substring(0, 110)}...' : cleaned;
  }

  @override
  String extractMatchSnippet(String query) {
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isEmpty) return getSummary();
    for (final rawLine in content.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line == '---') continue;
      if (line.toLowerCase().contains(trimmedQuery)) {
        final cleaned = line
            .replaceAll(RegExp(r'^\s*#+\s*'), '')
            .replaceAll(RegExp(r'[*_~=`]+'), '')
            .trim();
        return cleaned.length > 100 ? '${cleaned.substring(0, 100)}...' : cleaned;
      }
    }
    return getSummary();
  }

  @override
  bool matchesQuery(String query) {
    if (query.isEmpty) return true;
    final lowerQuery = query.toLowerCase().trim();
    final tagQuery = lowerQuery.replaceAll('#', '');
    final matchInTags = tags.any((t) => t.toLowerCase().contains(tagQuery));
    final matchInBody = content.toLowerCase().contains(lowerQuery);
    final matchInSource =
        sourceApp != null && sourceApp!.toLowerCase().contains(lowerQuery);
    return super.matchesQuery(query) ||
        matchInBody ||
        matchInTags ||
        matchInSource;
  }

  @override
  TextNote copyWith({
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
    List<String>? tags,
    List<String>? links,
    int? estimatedMinutes,
    String? sourceApp,
  }) {
    return TextNote(
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
      tags: tags ?? this.tags,
      links: links ?? this.links,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      sourceApp: sourceApp ?? this.sourceApp,
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
      'tags': tags,
      'links': links,
      'estimatedMinutes': estimatedMinutes,
      'sourceApp': sourceApp,
    };
  }

  factory TextNote.fromJson(Map<String, dynamic> json) {
    return TextNote(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      paletteId: json['paletteId'] as String? ?? 'peach',
      isFavorite: json['isFavorite'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      isTrash: json['isTrash'] as bool? ?? false,
      isInbox: json['isInbox'] as bool? ?? false,
      folderName: json['folderName'] as String?,
      parentId: json['parentId'] as String?,
      iconEmoji: json['iconEmoji'] as String?,
      content: json['content'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      links: (json['links'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 3,
      sourceApp: json['sourceApp'] as String?,
    );
  }
}
