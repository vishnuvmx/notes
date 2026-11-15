---
id: mem_001
title: Locked Product & Navigation Rules
type: decision
created: '2026-11-15'
updated: '2026-11-15'
tags:
  - architecture
  - navigation
status: active
verification: unverified
confidence: 1
sources:
  - AGENTS.md
  - lib/features/notes/screens/note_editor_screen.dart
validFrom: '2026-11-15'
version: 1
tenantId: default
workspaceId: default
projectId: default
visibility: workspace
---

# Locked Product & Navigation Rules

Notes view in Tack is GRID ONLY (no list-view mode or toggle anywhere). No redundant buttons on the same screen. Note navigation follows Home -> Read mode -> Edit mode: Back in Edit mode flushes auto-save and returns to Read mode (newly created blank drafts with startInEditMode discard and pop); Back in Read mode returns Home.
