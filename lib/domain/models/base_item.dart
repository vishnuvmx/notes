import 'package:flutter/foundation.dart';

/// Workspace item types supported across Tack.
/// Note & Board are the two primary user-facing objects (`05-information-architecture.md` §1.2);
/// `sticky` and `clipboard` are retained for backwards-compatible deserialization and migration.
enum ItemType {
  note,
  sticky,
  whiteboard,
  clipboard;

  String get label {
    switch (this) {
      case ItemType.note:
        return 'Notes';
      case ItemType.sticky:
        return 'Notes';
      case ItemType.whiteboard:
        return 'Boards';
      case ItemType.clipboard:
        return 'Inbox';
    }
  }
}

/// Abstract base class for all workspace items in Tack.
@immutable
abstract class BaseWorkspaceItem {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ItemType type;
  final String paletteId;
  final bool isFavorite;
  final bool isArchived;
  final bool isTrash;
  final bool isInbox;
  final String? folderName;
  final String? parentId;
  final String? iconEmoji;

  const BaseWorkspaceItem({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.type,
    required this.paletteId,
    this.isFavorite = false,
    this.isArchived = false,
    this.isTrash = false,
    this.isInbox = false,
    this.folderName,
    this.parentId,
    this.iconEmoji,
  });

  /// In Tack's vocabulary (`10-design.md` §4), "Pin" replaces "Favorite" and "Archive".
  bool get isPinned => isFavorite;

  /// Abstract polymorphic summary method implemented uniquely by each child class.
  String getSummary();

  /// Returns a 1-line snippet showing where [query] matched inside this item.
  String extractMatchSnippet(String query) => getSummary();

  /// Abstract copyWith method for immutable state updates.
  BaseWorkspaceItem copyWith({
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
  });

  /// Polymorphic query matching for full-text search.
  bool matchesQuery(String query) {
    if (query.isEmpty) return true;
    final lowerQuery = query.toLowerCase();
    return title.toLowerCase().contains(lowerQuery) ||
        getSummary().toLowerCase().contains(lowerQuery) ||
        (folderName != null && folderName!.toLowerCase().contains(lowerQuery));
  }

  /// Serialization contract for persistence.
  Map<String, dynamic> toJson();
}
