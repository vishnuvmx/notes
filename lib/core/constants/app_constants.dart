/// Centralized application constants for Tack.
class AppConstants {
  AppConstants._();

  static const String appName = 'Tack';
  static const String appVersion = '2.0.0';

  // Platform Method Channels
  static const String processTextChannel = 'com.notes.tacknotes/process_text';
  static const String notificationsChannel =
      'com.notes.tacknotes/notifications';

  // Text Scaler Accessibility Bounds
  static const double minTextScaleFactor = 0.85;
  static const double maxTextScaleFactor = 1.25;
}
