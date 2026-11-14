import 'package:flutter/services.dart';

import '../../features/tasks/services/open_tasks_service.dart';
import '../../shared/models/base_item.dart';

/// Immutable notification payload representing one upcoming scheduled task reminder.
class TaskReminderPayload {
  final String taskId;
  final String noteId;
  final int lineIndex;
  final String title;
  final String body;
  final DateTime triggerAt;
  final String dueLabel;
  final String? repeatLabel;

  const TaskReminderPayload({
    required this.taskId,
    required this.noteId,
    required this.lineIndex,
    required this.title,
    required this.body,
    required this.triggerAt,
    required this.dueLabel,
    this.repeatLabel,
  });

  /// Stable positive 31-bit Android PendingIntent / Notification request ID.
  int get stableNotificationId {
    var hash = 2166136261;
    for (final code in taskId.codeUnits) {
      hash ^= code;
      hash = (hash * 16777619) & 0x7FFFFFFF;
    }
    return 100000 + (hash % 2000000);
  }

  Map<String, dynamic> toChannelMap() {
    return <String, dynamic>{
      'taskId': taskId,
      'notifId': stableNotificationId,
      'noteId': noteId,
      'lineIndex': lineIndex,
      'title': title,
      'body': body,
      'triggerAtMillis': triggerAt.millisecondsSinceEpoch,
      'dueLabel': dueLabel,
      if (repeatLabel != null) 'repeatLabel': repeatLabel,
    };
  }
}

/// Bridges Markdown `@due(...)` / `@repeat(...)` checklist tasks to native Android
/// `AlarmManager` local reminder notifications on `com.notes.tacknotes/notifications`.
class TaskReminderService {
  TaskReminderService._();

  static const MethodChannel _channel =
      MethodChannel('com.notes.tacknotes/notifications');

  /// Maximum pending alarms scheduled at once so Android AlarmManager stays well
  /// below OEM per-app alarm quota limits.
  static const int maxScheduledAlarms = 48;

  /// Builds chronologically ordered upcoming reminder payloads from active notes.
  static List<TaskReminderPayload> buildUpcomingReminders(
    Iterable<BaseWorkspaceItem> items, {
    DateTime? now,
    int maxAlarms = maxScheduledAlarms,
  }) {
    final ref = now ?? DateTime.now();
    final tasks = OpenTasksService.extractTasks(
      items,
      includeCompleted: false,
      now: ref,
    );

    final reminders = <TaskReminderPayload>[];
    final seenTaskIds = <String>{};

    for (final task in tasks) {
      final triggerAt = task.reminderTriggerAt;
      if (triggerAt == null || !triggerAt.isAfter(ref)) continue;
      if (!seenTaskIds.add(task.id)) continue;

      final dueLabel = task.formatDueLabel(ref) ?? 'Due';
      final repeatLabel = task.recurrence?.label;
      final subtitleParts = <String>[
        task.noteTitle,
        dueLabel,
        if (repeatLabel != null) repeatLabel,
      ];

      reminders.add(
        TaskReminderPayload(
          taskId: task.id,
          noteId: task.noteId,
          lineIndex: task.lineIndex,
          title: task.text,
          body: subtitleParts.join(' · '),
          triggerAt: triggerAt,
          dueLabel: dueLabel,
          repeatLabel: repeatLabel,
        ),
      );
    }

    reminders.sort((a, b) => a.triggerAt.compareTo(b.triggerAt));
    if (reminders.length > maxAlarms) {
      return reminders.sublist(0, maxAlarms);
    }
    return reminders;
  }

  /// Syncs all upcoming `@due(...)` reminders to the native Android alarm scheduler.
  static Future<void> syncWorkspaceReminders(
    Iterable<BaseWorkspaceItem> items, {
    DateTime? now,
  }) async {
    final payloads = buildUpcomingReminders(items, now: now);
    try {
      await _channel.invokeMethod<bool>(
        'syncTaskReminders',
        payloads.map((p) => p.toChannelMap()).toList(),
      );
    } catch (_) {
      // Gracefully no-op on non-Android platforms or headless tests.
    }
  }

  /// Cancels every pending scheduled task reminder alarm.
  static Future<void> cancelAll() async {
    try {
      await _channel.invokeMethod<bool>('cancelAllTaskReminders');
    } catch (_) {
      // Gracefully no-op on non-Android platforms or headless tests.
    }
  }
}
