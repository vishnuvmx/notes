---
id: mem_007
title: Composited fade-out transitions via TackAnimatedTransition
type: bugfix
created: '2026-11-15'
updated: '2026-11-15'
tags:
  - theme
  - composited
  - fade-out
  - transitions
status: active
verification: unverified
confidence: 1
validFrom: '2026-11-15'
version: 1
tenantId: default
workspaceId: default
projectId: default
visibility: workspace
---

# Composited fade-out transitions via TackAnimatedTransition

In Flutter CurvedAnimation, reverse evaluation calls activeCurve.transform(parent.value) directly as t drops from 1.0 to 0.0 (not 1 - curve(1 - t)), so Curves.easeOutCubic or Interval(0, x) stalls exit transitions near 1.0. Page routes, AppFloatingDialog.showCustom, and RichNoteContentView lightbox now share TackAnimatedTransition in lib/core/theme/app_theme.dart (disposing CurvedAnimation properly, wrapping child in RepaintBoundary inside FadeTransition + outer SlideTransition/ScaleTransition, and using Interval(0.28, 1.0, curve: Curves.easeInCubic) or easeInCubic for crisp exits), while AnimatedSwitchers use TackAnimatedTransition.switcherTransition with switchOutCurve: Curves.easeInCubic and SmartBottomNavBar avoids Opacity saveLayers.
