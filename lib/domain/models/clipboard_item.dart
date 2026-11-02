import 'base_item.dart';

/// Concrete Clipboard Item model inheriting from BaseWorkspaceItem.
class ClipboardItem extends BaseWorkspaceItem {
  final String clipText;
  final String sourceApp;
  final bool isPinned;

  const ClipboardItem({
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
    required this.clipText,
    this.sourceApp = 'System Clipboard',
    this.isPinned = false,
  }) : super(type: ItemType.clipboard);

  @override
  String getSummary() {
    if (clipText.trim().isEmpty) return title;
    final snippet = clipText.trim().replaceAll('\n', ' ');
    return snippet.length > 70 ? '${snippet.substring(0, 70)}...' : snippet;
  }

  @override
  ClipboardItem copyWith({
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
    String? clipText,
    String? sourceApp,
    bool? isPinned,
  }) {
    return ClipboardItem(
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
      clipText: clipText ?? this.clipText,
      sourceApp: sourceApp ?? this.sourceApp,
      isPinned: isPinned ?? this.isPinned,
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
      'clipText': clipText,
      'sourceApp': sourceApp,
      'isPinned': isPinned,
    };
  }

  factory ClipboardItem.fromJson(Map<String, dynamic> json) {
    return ClipboardItem(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      paletteId: json['paletteId'] as String? ?? 'slate',
      isFavorite: json['isFavorite'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      isTrash: json['isTrash'] as bool? ?? false,
      folderName: json['folderName'] as String?,
      parentId: json['parentId'] as String?,
      iconEmoji: json['iconEmoji'] as String?,
      clipText: json['clipText'] as String? ?? '',
      sourceApp: json['sourceApp'] as String? ?? 'System Clipboard',
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }
}
