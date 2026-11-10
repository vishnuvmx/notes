import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme switcher state provider with persistent storage.
/// Default on first launch is `ThemeMode.system` per docs/design/05-information-architecture.md §6.
class ThemeProvider extends ChangeNotifier {
  static const String _themePrefKey = 'app_theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider({ThemeMode? initialMode}) {
    if (initialMode != null) {
      _themeMode = initialMode;
    }
    _loadPersistedTheme();
  }

  ThemeMode get themeMode => _themeMode;

  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  /// Static helper to preload saved theme mode before runApp.
  static Future<ThemeMode> loadSavedThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_themePrefKey);
      if (saved == 'light') return ThemeMode.light;
      if (saved == 'dark') return ThemeMode.dark;
      if (saved == 'system') return ThemeMode.system;
    } catch (_) {}
    return ThemeMode.system;
  }

  Future<void> _loadPersistedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_themePrefKey);
      if (saved != null) {
        final loadedMode = saved == 'light'
            ? ThemeMode.light
            : (saved == 'dark' ? ThemeMode.dark : ThemeMode.system);
        if (_themeMode != loadedMode) {
          _themeMode = loadedMode;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      String modeStr = 'system';
      if (mode == ThemeMode.light) modeStr = 'light';
      if (mode == ThemeMode.dark) modeStr = 'dark';
      await prefs.setString(_themePrefKey, modeStr);
    } catch (_) {}
  }

  void toggleTheme(BuildContext context) {
    if (isDarkMode(context)) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}
