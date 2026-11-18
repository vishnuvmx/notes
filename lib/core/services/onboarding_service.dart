import 'package:shared_preferences/shared_preferences.dart';

/// Persists first-run onboarding completion status cleanly on-device.
class OnboardingService {
  OnboardingService._();

  static const String prefKey = 'has_completed_onboarding';

  /// Returns `true` if the user has already completed or skipped onboarding.
  static Future<bool> hasCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(prefKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Convenience inverse for launch routing in `main()`.
  static Future<bool> shouldShowOnboarding() async => !(await hasCompleted());

  /// Marks onboarding complete so subsequent launches enter the workspace directly.
  static Future<void> markCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKey, true);
    } catch (_) {}
  }

  /// Clears completion status (used when replaying onboarding or in tests).
  static Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefKey);
    } catch (_) {}
  }
}
