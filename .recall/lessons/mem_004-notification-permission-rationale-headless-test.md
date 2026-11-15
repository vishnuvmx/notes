---
id: mem_004
title: Notification Permission Rationale & Headless Test Guard
type: lesson
created: '2026-11-15'
updated: '2026-11-15'
tags:
  - permissions
  - android
  - testing
status: active
verification: unverified
confidence: 1
sources:
  - lib/features/tasks/widgets/task_reminder_sheet.dart
  - lib/shared/widgets/permission_rationale_dialog.dart
  - lib/core/services/pinned_notification_service.dart
validFrom: '2026-11-15'
version: 1
tenantId: default
workspaceId: default
projectId: default
visibility: workspace
---

# Notification Permission Rationale & Headless Test Guard

Guard ensureNotificationPermissionWithRationale calls in TaskReminderSheet with !kIsWeb && Platform.isAndroid, avoid showing an infinite CircularProgressIndicator over an awaiting permission dialog, and never block saving @due/@repeat markdown metadata if notification permission is declined or unsupported; unmocked MethodChannel awaits inside FakeAsync widget tests hang pumpAndSettle().
