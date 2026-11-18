---
id: mem_013
title: 'Container Transform, TOC jump precision, and To-Do switcher polish'
type: decision
created: '2026-11-18'
updated: '2026-11-18'
tags:
  - tasks
  - slide
  - navigation
  - note
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

# Container Transform, TOC jump precision, and To-Do switcher polish

Container Transform (package:animations OpenContainer via TackCardOpenContainer) wraps NeoNoteCard, BoardGridCard, _WorthRevisitingCard, and existing _TodaysDailyNoteCard (with SmoothRectangleBorder.lerpFrom/lerpTo interpolation), while non-card item opens use TackRoutes.slideUp / sharedAxisHorizontal. DocumentOutlineSheet opens as a top-right floating popover and Inline [TOC] + DocumentOutlineSheet jump via RichNoteNavigationController + Scrollable.ensureVisible(alignment: 0.03) with auto-unfold. TodayScreen _SegmentedTasksCard uses AnimatedSize(topCenter) + top-aligned directional SlideTransition.
