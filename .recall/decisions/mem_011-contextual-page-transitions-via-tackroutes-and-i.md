---
id: mem_011
title: Contextual page transitions via TackRoutes and image Hero flights
type: decision
created: '2026-11-18'
updated: '2026-11-18'
tags:
  - settings
  - transitions
  - slide
  - contextual
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

# Contextual page transitions via TackRoutes and image Hero flights

Implemented TackRoutes in lib/core/routing/tack_routes.dart (exported via app_router.dart): sharedAxisHorizontal for drill-down links (sub-notes, WikiLinks, backlinks, breadcrumbs, FolderViews, AboutTack, Graph->item, Whiteboard->SpecNote), slideUp for modal context shifts (ProfileSettings, KnowledgeGraph, Mermaid->Whiteboard expand, Welcome Guide replay), and heroImageShuttle Hero flights on Markdown image blocks to _ImageLightboxViewer—animating both animation and secondaryAnimation via disposed CurvedAnimations with crisp exit curves.
