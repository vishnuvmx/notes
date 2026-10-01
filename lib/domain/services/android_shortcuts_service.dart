import 'package:flutter/services.dart';
import '../models/base_item.dart';

/// Manages Android dynamic shortcuts (launcher long-press quick jumps)
class AndroidShortcutsService {
  AndroidShortcutsService._();

  static const MethodChannel _channel = MethodChannel('com.notes.tacknotes/process_text');

  /// Publishes recent/favorite notes to Android ShortcutManager
  static Future<void> syncDynamicShortcuts(List<BaseWorkspaceItem> items) async {
    try {
      final activeNotes = items
          .where((i) => !i.isArchived && !i.isTrash)
          .take(2)
          .map((i) => {
                'id': i.id,
                'title': i.title.trim().isNotEmpty ? i.title.trim() : i.getSummary(),
                'type': i.runtimeType.toString(),
              })
          .toList();

      await _channel.invokeMethod('updateShortcuts', {'shortcuts': activeNotes});
    } catch (_) {
      // Gracefully ignore on platforms/launchers without shortcut support
    }
  }
}
