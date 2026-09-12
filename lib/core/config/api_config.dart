import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central API Configuration for Tack's AI Server.
/// Supports seamless switching between local development, Wi-Fi testing, and production URLs.
class ApiConfig {
  static const String _keyServerUrl = 'tack_ai_server_url';

  /// Default local URL depending on platform:
  /// - Android uses 10.0.2.2 to connect to host computer
  /// - Other platforms use localhost
  static String get defaultBaseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  /// Get the active server URL from preferences, or fallback to default
  static Future<String> getBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_keyServerUrl);
      if (saved != null && saved.trim().isNotEmpty) {
        return saved.trim().replaceAll(RegExp(r'/+$'), '');
      }
    } catch (_) {}
    return defaultBaseUrl;
  }

  /// Save a custom server URL (e.g. Wi-Fi IP or production cloud host)
  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final clean = url.trim().replaceAll(RegExp(r'/+$'), '');
    await prefs.setString(_keyServerUrl, clean);
  }

  /// Reset to platform default
  static Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyServerUrl);
  }

  /// Ping the server /health endpoint to verify connectivity
  static Future<bool> checkServerHealth([String? overrideUrl]) async {
    final baseUrl = overrideUrl ?? await getBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/health');
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body);
        return json is Map && json['status'] == 'ok';
      }
    } catch (_) {}
    return false;
  }
}
