import 'dart:async';
import 'package:flutter/services.dart';

/// Data payload received from Android ACTION_PROCESS_TEXT, ACTION_SEND, or ACTION_VIEW.
class IncomingTextData {
  final String text;
  final String? title;
  final String? fileName;
  final String? imagePath;
  final String? sourceApp;
  final String? packageName;
  final String? action;
  final String? noteId;

  const IncomingTextData({
    required this.text,
    this.title,
    this.fileName,
    this.imagePath,
    this.sourceApp,
    this.packageName,
    this.action,
    this.noteId,
  });

  factory IncomingTextData.fromMap(Map<dynamic, dynamic> map) {
    return IncomingTextData(
      text: map['text'] as String? ?? '',
      title: map['title'] as String?,
      fileName: map['fileName'] as String?,
      imagePath: map['imagePath'] as String?,
      sourceApp: map['sourceApp'] as String?,
      packageName: map['packageName'] as String?,
      action: map['action'] as String?,
      noteId: map['noteId'] as String?,
    );
  }

  bool get isValid =>
      text.trim().isNotEmpty ||
      (imagePath != null && imagePath!.isNotEmpty) ||
      action == 'OPEN_NOTE' ||
      action == 'QUICK_CAPTURE' ||
      action == 'NEW_NOTE' ||
      action == 'NEW_WHITEBOARD';
}

/// Service handling incoming text intents from Android system integration
/// (such as "Save to Tack" in the text selection overflow menu).
class ProcessTextService {
  static const MethodChannel _channel = MethodChannel('com.notes.tacknotes/process_text');
  static void Function(IncomingTextData data)? _onTextReceived;
  static bool _isInitialized = false;

  /// Initialize listener for text sent while app is in foreground/background.
  static void initialize({required void Function(IncomingTextData data) onTextReceived}) {
    _onTextReceived = onTextReceived;
    if (_isInitialized) return;
    _isInitialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onReceiveText') {
        final raw = call.arguments;
        if (raw is Map) {
          final data = IncomingTextData.fromMap(raw);
          if (data.isValid) {
            _onTextReceived?.call(data);
          }
        }
      }
    });
  }

  /// Query any initial text payload if app was launched directly by an intent.
  static Future<IncomingTextData?> getInitialText() async {
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>('getInitialText');
      if (raw != null) {
        final data = IncomingTextData.fromMap(raw);
        if (data.isValid) {
          return data;
        }
      }
    } catch (_) {
      // Gracefully ignore platform channel errors on non-Android platforms
    }
    return null;
  }
}
