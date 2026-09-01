import 'package:flutter/foundation.dart';

/// Workspace item types supported across Tack.
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
        return 'Sticky';
      case ItemType.whiteboard:
        return 'Whiteboard';
      case ItemType.clipboard:
        return 'Clipboard';
    }
  }
}

/// Abstract base class demonstrating OOP Abstraction and Polymorphism.
/// All note types inherit from this base class and specialize their behaviors.
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
  });

  /// Abstract polymorphic summary method implemented uniquely by each child class.
  String getSummary();

  /// Abstract copyWith method for immutable state updates.
  BaseWorkspaceItem copyWith({
    String? title,
    DateTime? updatedAt,
    String? paletteId,
    bool? isFavorite,
    bool? isArchived,
    bool? isTrash,
  });

  /// Polymorphic query matching for search.
  bool matchesQuery(String query) {
    if (query.isEmpty) return true;
    final lowerQuery = query.toLowerCase();
    return title.toLowerCase().contains(lowerQuery) ||
        getSummary().toLowerCase().contains(lowerQuery);
  }

  /// Serialization contract for persistence.
  Map<String, dynamic> toJson();
}
