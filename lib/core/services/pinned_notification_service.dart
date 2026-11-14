import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/base_item.dart';
import '../../shared/models/clipboard_item.dart';
import '../../shared/models/sticky_note.dart';
import '../../features/notes/models/text_note.dart';
import '../../features/tasks/services/open_tasks_service.dart';

/// Service managing Android notification-bar pinning for To-Dos & notes,
/// inline Quick Add replies, and the persistent Quick Capture tile.
class PinnedNotificationService {
  static const MethodChannel _channel =
      MethodChannel('com.notes.tacknotes/notifications');
  static const String _prefQuickCaptureKey = 'tack_quick_capture_enabled';
  static const String _prefPinnedIdsKey = 'tack_pinned_note_ids';

  static Future<void> Function(String noteId, String text)? _onQuickAdd;
  static Future<void> Function(String noteId)? _onCompleteNextTodo;
  static Future<void> Function(String noteId, int lineIndex)? _onCompleteTaskLine;
  static Future<void> Function(String noteId)? _onUnpin;
  static bool _isInitialized = false;

  static final RegExp _uncheckedTodoRegex = RegExp(
    r'^\s*[-*]\s+\[\s\]\s+(.+)$',
    multiLine: true,
  );
  static final RegExp _checkedTodoRegex = RegExp(
    r'^\s*[-*]\s+\[[xX]\]\s+(.+)$',
    multiLine: true,
  );

  /// Initializes listeners for background/foreground notification actions
  /// and drains any actions queued while the app was closed.
  static Future<void> initializeCallbacks({
    required Future<void> Function(String noteId, String text) onQuickAdd,
    required Future<void> Function(String noteId) onCompleteNextTodo,
    Future<void> Function(String noteId, int lineIndex)? onCompleteTaskLine,
    required Future<void> Function(String noteId) onUnpin,
  }) async {
    _onQuickAdd = onQuickAdd;
    _onCompleteNextTodo = onCompleteNextTodo;
    _onCompleteTaskLine = onCompleteTaskLine;
    _onUnpin = onUnpin;

    if (!_isInitialized) {
      _isInitialized = true;
      _channel.setMethodCallHandler((call) async {
        final args = call.arguments;
        if (args is! Map) return;
        final noteId = args['noteId'] as String? ?? '';
        switch (call.method) {
          case 'onNotificationQuickAdd':
            final text = (args['text'] as String? ?? '').trim();
            if (text.isNotEmpty) {
              await _onQuickAdd?.call(noteId, text);
            }
            break;
          case 'onNotificationCompleteTodo':
            if (noteId.isNotEmpty) {
              await _onCompleteNextTodo?.call(noteId);
            }
            break;
          case 'onNotificationCompleteTaskLine':
            final lineIndex = (args['lineIndex'] as num?)?.toInt();
            if (noteId.isNotEmpty && lineIndex != null) {
              await _onCompleteTaskLine?.call(noteId, lineIndex);
            }
            break;
          case 'onNotificationUnpin':
            if (noteId.isNotEmpty) {
              await _removePinnedId(noteId);
              await _onUnpin?.call(noteId);
            }
            break;
        }
      });
    }

    await _drainPendingNativeActions();
  }

  static Future<void> _drainPendingNativeActions() async {
    try {
      final rawList =
          await _channel.invokeMethod<List<dynamic>>('drainPendingNotificationActions');
      if (rawList == null || rawList.isEmpty) return;

      for (final raw in rawList) {
        if (raw is! Map) continue;
        final type = raw['type'] as String? ?? '';
        final noteId = raw['noteId'] as String? ?? '';
        final text = (raw['text'] as String? ?? '').trim();

        if (type == 'unpin' && noteId.isNotEmpty) {
          await _removePinnedId(noteId);
          await _onUnpin?.call(noteId);
        } else if (type == 'complete_todo' && noteId.isNotEmpty) {
          await _onCompleteNextTodo?.call(noteId);
        } else if (type == 'complete_task_line' && noteId.isNotEmpty) {
          final lineIndex = int.tryParse(raw['lineIndex']?.toString() ?? '');
          if (lineIndex != null) {
            await _onCompleteTaskLine?.call(noteId, lineIndex);
          }
        } else if (type == 'quick_add' && text.isNotEmpty) {
          await _onQuickAdd?.call(noteId, text);
        }
      }
    } catch (_) {
      // Gracefully ignore on non-Android platforms
    }
  }

  /// Enables or disables the persistent Quick Capture notification tile in the status bar.
  static Future<bool> setQuickCaptureEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefQuickCaptureKey, enabled);

      if (enabled) {
        return await _channel.invokeMethod<bool>('showQuickCapture') ?? false;
      } else {
        return await _channel.invokeMethod<bool>('hideQuickCapture') ?? false;
      }
    } catch (_) {
      return false;
    }
  }

  /// Check whether Quick Capture status bar tile is enabled in preferences.
  static Future<bool> isQuickCaptureEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefQuickCaptureKey) ?? false;
  }

  /// Returns all note IDs currently pinned to the notification bar.
  static Future<Set<String>> getPinnedNoteIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_prefPinnedIdsKey) ?? const <String>[]).toSet();
  }

  /// Checks whether a specific note is currently pinned to the notification bar.
  static Future<bool> isNotePinned(String noteId) async {
    final ids = await getPinnedNoteIds();
    return ids.contains(noteId);
  }

  /// Pins a workspace note/to-do item to the Android notification bar.
  static Future<bool> pinNote(BaseWorkspaceItem item) async {
    try {
      final payload = _buildNotificationPayload(item);
      final ok = await _channel.invokeMethod<bool>('pinNoteNotification', {
            'noteId': item.id,
            'title': payload.title,
            'body': payload.body,
            'hasNextTodo': payload.hasNextTodo,
          }) ??
          false;

      if (ok) {
        final prefs = await SharedPreferences.getInstance();
        final list = prefs.getStringList(_prefPinnedIdsKey) ?? <String>[];
        if (!list.contains(item.id)) {
          list.add(item.id);
          await prefs.setStringList(_prefPinnedIdsKey, list);
        }
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// Unpins a note from the Android notification bar.
  static Future<bool> unpinNote(String noteId) async {
    await _removePinnedId(noteId);
    try {
      return await _channel.invokeMethod<bool>('unpinNoteNotification', {
            'noteId': noteId,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Refreshes the notification content if [item] is currently pinned (or unpins if trashed).
  static Future<void> syncPinnedNoteIfActive(BaseWorkspaceItem item) async {
    if (!await isNotePinned(item.id)) return;
    if (item.isTrash || item.isArchived) {
      await unpinNote(item.id);
      return;
    }
    await pinNote(item);
  }

  static Future<void> _removePinnedId(String noteId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefPinnedIdsKey) ?? <String>[];
    if (list.remove(noteId)) {
      await prefs.setStringList(_prefPinnedIdsKey, list);
    }
  }

  static ({String title, String body, bool hasNextTodo}) _buildNotificationPayload(
    BaseWorkspaceItem item,
  ) {
    final title = item.title.trim().isEmpty ? 'Pinned Note' : item.title.trim();
    String rawContent = '';
    if (item is TextNote) {
      rawContent = item.content;
    } else if (item is StickyNote) {
      rawContent = item.content;
    } else if (item is ClipboardItem) {
      rawContent = item.clipText;
    } else {
      rawContent = item.getSummary();
    }

    // Strip YAML frontmatter if present
    final stripped = rawContent.replaceFirst(
      RegExp(r'^---\s*\r?\n[\s\S]*?\r?\n---\s*(\r?\n)?'),
      '',
    );

    final hasNextTodo = _uncheckedTodoRegex.hasMatch(stripped);
    final formattedLines = <String>[];
    for (final line in stripped.split('\n')) {
      final t = line.trim();
      if (t.isEmpty) continue;
      final unchecked = _uncheckedTodoRegex.firstMatch(line);
      if (unchecked != null) {
        final raw = unchecked.group(1)!.trim();
        final parsed = OpenTasksService.parseTaskMetadata(raw);
        final display = parsed.cleanText.isNotEmpty ? parsed.cleanText : raw;
        final dueSuffix = parsed.dueAt != null
            ? DerivedTaskItem(
                noteId: item.id,
                noteTitle: title,
                paletteId: '',
                lineIndex: 0,
                text: display,
                isDone: false,
                noteUpdatedAt: item.updatedAt,
                dueAt: parsed.dueAt,
                hasExplicitTime: parsed.hasExplicitTime,
                recurrence: parsed.recurrence,
              ).formatDueLabel()
            : null;
        formattedLines.add(
          dueSuffix != null ? '☐ $display ($dueSuffix)' : '☐ $display',
        );
        continue;
      }
      final checked = _checkedTodoRegex.firstMatch(line);
      if (checked != null) {
        formattedLines.add('☑ ${checked.group(1)!.trim()}');
        continue;
      }
      formattedLines.add(t.replaceAll(RegExp(r'^#{1,6}\s+'), ''));
      if (formattedLines.length >= 6) break;
    }

    final body = formattedLines.isEmpty
        ? 'Tap to open in Tack'
        : formattedLines.take(6).join('\n');

    return (title: title, body: body, hasNextTodo: hasNextTodo);
  }
}
