---
id: mem_012
title: Starter showcase note/board & bundled asset image support
type: decision
created: '2026-11-18'
updated: '2026-11-18'
tags:
  - starter
  - showcase
  - note
  - board
status: active
verification: unverified
confidence: 1
validFrom: '2026-11-18'
version: 1
tenantId: default
workspaceId: default
projectId: default
visibility: workspace
---

# Starter showcase note/board & bundled asset image support

Bundled Flutter assets (assets/... or asset:...) are supported uniformly in RichNoteContentView (_buildResolvedMarkdownImage), NoteExportService PDF export, and WhiteboardCanvasScreen (_resolveNodeAssetPath + PNG/PDF export). MockInitialData seeds Tack Complete Guide and Capture to Clarity using bundled onboarding images, and LocalStorageWorkspaceRepository upgrades untouched v1 starter items once via tack_starter_showcase_v2_seeded.
