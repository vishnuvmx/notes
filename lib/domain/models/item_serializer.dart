import 'base_item.dart';
import 'text_note.dart';
import 'sticky_note.dart';
import 'whiteboard_item.dart';
import 'clipboard_item.dart';

/// Polymorphic serialization helper for all workspace item types.
class ItemSerializer {
  static BaseWorkspaceItem? fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    if (typeStr == null) return null;
    switch (typeStr) {
      case 'note':
        return TextNote.fromJson(json);
      case 'sticky':
        return StickyNote.fromJson(json);
      case 'whiteboard':
        return WhiteboardCanvasItem.fromJson(json);
      case 'clipboard':
        return ClipboardItem.fromJson(json);
      default:
        return null;
    }
  }
}
