---
id: mem_006
title: Verified Test & Kotlin Build Commands
type: convention
created: '2026-11-15'
updated: '2026-11-15'
tags:
  - verification
  - performance
status: active
verification: unverified
confidence: 1
sources:
  - test/phase2_ui_audit_test.dart
  - test/task_reminders_test.dart
validFrom: '2026-11-15'
version: 1
tenantId: default
workspaceId: default
projectId: default
visibility: workspace
---

# Verified Test & Kotlin Build Commands

Verify Flutter widget/unit tests with flutter test (59 passing tests covering card_grid_layout_test.dart, latex_math_test.dart, phase2_ui_audit_test.dart, tack_icons_test.dart, task_reminders_test.dart) and Android Kotlin compilation with android\gradlew.bat -p android :app:compileDebugKotlin --console=plain. Performance patterns: composited SlidingPillTrack, RepaintBoundary IndexedStack tabs, and ZOrderColumn reverse paint order.
