---
id: mem_005
title: Cross-Screen UX & Search Filter Invariants
type: bugfix
created: '2026-11-15'
updated: '2026-11-15'
tags:
  - ux-audit
  - search
  - tasks
status: active
verification: unverified
confidence: 1
sources:
  - lib/features/home/screens/home_screen.dart
  - lib/features/tasks/screens/today_screen.dart
  - lib/features/graph/screens/knowledge_graph_screen.dart
  - lib/features/notes/widgets/document_outline_sheet.dart
validFrom: '2026-11-15'
version: 1
tenantId: default
workspaceId: default
projectId: default
visibility: workspace
---

# Cross-Screen UX & Search Filter Invariants

Library filter bar scrolls with CustomScrollView and clips within viewport; TodayScreen groups tasks by noteId (separating identically titled notes) and expands beyond 12 tasks via Show all; KnowledgeGraphScreen strips leading # on tag hubs when filtering into Library; search/filter modals clear both state and TextEditingController on Clear filter; date pickers clamp initialDate inside [firstDate, lastDate].
