import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service managing the Quick Capture tile and persistent capture on Android.
class PinnedNotificationService {
  static const MethodChannel _channel = MethodChannel('com.notes.tacknotes/process_text');
  static const String _prefQuickCaptureKey = 'tack_quick_capture_enabled';

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
