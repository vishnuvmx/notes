import 'package:flutter/material.dart';

import '../../core/services/pinned_notification_service.dart';
import '../../core/theme/tack_icons.dart';
import 'app_floating_dialog.dart';

/// Shared helper that checks notification permission first, explains WHY
/// notifications are needed before triggering the Android OS prompt, and offers
/// a recovery link to System Settings if permission remains denied.
Future<bool> ensureNotificationPermissionWithRationale(
  BuildContext context, {
  required String title,
  required String rationale,
}) async {
  final status = await PinnedNotificationService.getPermissionStatus();
  if (!status.supported || status.granted) {
    return true;
  }
  if (!context.mounted) return false;

  final wantsToAllow = await AppFloatingDialog.confirm(
    context: context,
    title: title,
    message: rationale,
    confirmLabel: 'Allow Notifications',
    cancelLabel: 'Not Now',
    icon: TackIcons.notification,
  );
  if (!wantsToAllow || !context.mounted) return false;

  final granted = await PinnedNotificationService.requestPermission();
  if (granted || !context.mounted) {
    return granted;
  }

  final openSettings = await AppFloatingDialog.confirm(
    context: context,
    title: 'Notifications Are Off',
    message:
        'Turn on notifications for Tack in Android Settings so reminders and pinned notes can appear.',
    confirmLabel: 'Open Settings',
    cancelLabel: 'Dismiss',
    icon: TackIcons.settings,
  );
  if (openSettings) {
    await PinnedNotificationService.openNotificationSettings();
  }
  return false;
}
