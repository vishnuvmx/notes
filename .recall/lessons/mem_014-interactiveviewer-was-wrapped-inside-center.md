---
id: mem_014
title: InteractiveViewer was wrapped inside Center(
type: bugfix
created: '2026-11-21'
updated: '2026-11-21'
tags:
  - chat-bugfix
  - auto-chat
status: proposed
verification: needs_review
confidence: 0.65
sources:
  - local-chat-sync
validFrom: '2026-11-21'
version: 1
tenantId: default
workspaceId: default
projectId: default
visibility: workspace
---

# InteractiveViewer was wrapped inside Center(

`InteractiveViewer` was wrapped inside `Center(...)` inside `SafeArea`, which shrank its clip viewport to the unzoomed image's bounding box so any zoom or pan clipped the image along its initial edges.
