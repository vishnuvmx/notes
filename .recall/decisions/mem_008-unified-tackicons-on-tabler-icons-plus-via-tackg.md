---
id: mem_008
title: Unified TackIcons on tabler_icons_plus via TackGlyph
type: decision
created: '2026-11-18'
updated: '2026-11-18'
tags:
  - theme
  - unified
  - tackicons
  - tabler_icons_plus
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

# Unified TackIcons on tabler_icons_plus via TackGlyph

Migrated TackIcons and TackIcon in lib/core/theme/tack_icons.dart from mixed custom SVG packs + LucideIcons to tabler_icons_plus (^3.52.0) via TackGlyph(outline, solid: ...), supporting outline/filled HeroIconStyle switching cleanly and setting ThemeData.iconTheme to lightTextPrimary/darkTextPrimary in AppTheme.
