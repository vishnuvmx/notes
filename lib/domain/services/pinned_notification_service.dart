import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service managing persistent status bar note pinning and Quick Capture tile on Android.
class PinnedNotificationService {
  static const MethodChannel _channel = MethodChannel('com.notes.tacknotes/process_text');
  static const String _prefQuickCaptureKey = 'tack_quick_capture_enabled';
  static const String _prefPinnedIdsKey = 'tack_pinned_note_ids';

  /// Pin a note directly to the Android status bar / notification drawer.
  static Future<bool> pinNote({
    required String id,
    required String title,
    required String content,
    String? paletteId,
  }) async {
    try {
      final success = await _channel.invokeMethod<bool>('pinNote', {
        'id': id,
        'title': title,
        'content': content,
        'paletteId': paletteId,
      }) ?? false;

      if (success) {
        final prefs = await SharedPreferences.getInstance();
        final pinnedIds = prefs.getStringList(_prefPinnedIdsKey) ?? [];
        if (!pinnedIds.contains(id)) {
          pinnedIds.add(id);
          await prefs.setStringList(_prefPinnedIdsKey, pinnedIds);
        }
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  /// Unpin a note from the status bar.
  static Future<bool> unpinNote(String id) async {
    try {
      final success = await _channel.invokeMethod<bool>('unpinNote', {'id': id}) ?? false;
      final prefs = await SharedPreferences.getInstance();
      final pinnedIds = prefs.getStringList(_prefPinnedIdsKey) ?? [];
      if (pinnedIds.contains(id)) {
        pinnedIds.remove(id);
        await prefs.setStringList(_prefPinnedIdsKey, pinnedIds);
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  /// Checks if a note is currently pinned to the status bar.
  static Future<bool> isNotePinned(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final pinnedIds = prefs.getStringList(_prefPinnedIdsKey) ?? [];
    return pinnedIds.contains(id);
  }

  /// Toggles status bar pin state for a note.
  static Future<bool> togglePinNote({
    required String id,
    required String title,
    required String content,
    String? paletteId,
  }) async {
    final isPinned = await isNotePinned(id);
    if (isPinned) {
      await unpinNote(id);
      return false;
    } else {
      await pinNote(id: id, title: title, content: content, paletteId: paletteId);
      return true;
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
}
