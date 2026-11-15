---
id: mem_002
title: 'Centralized TackTokens, Typography & Touch Targets'
type: design_system
created: '2026-11-15'
updated: '2026-11-15'
tags:
  - theme
  - tokens
status: active
verification: unverified
confidence: 1
sources:
  - lib/core/theme/app_colors.dart
  - lib/core/theme/app_typography.dart
  - lib/core/theme/app_spacing.dart
validFrom: '2026-11-15'
version: 1
tenantId: default
workspaceId: default
projectId: default
visibility: workspace
---

# Centralized TackTokens, Typography & Touch Targets

All widgets must use context.tokens (TackTokens: canvasPrimary, surfacePrimary, canvasSunken, textPrimary, textSecondary, textTertiary, borderSubtle, borderStrong, actionPrimary, actionPrimaryFg, accentPin, danger, warning, success, info) from lib/core/theme/app_colors.dart; never use nonexistent textMuted or surfaceAlt getters on TackTokens. Use AppTypography (12sp caption floor, 13sp label, body without letterSpacing param, no labelSm). Keep touch targets >= 48dp (AppSpacing.minTouchTarget), modal corners smooth 28dp with >= 24dp top clearance (AppSpacing.s7), and SVG icons via TackIcon / TackIcons.
