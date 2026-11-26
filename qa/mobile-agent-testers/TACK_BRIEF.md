# Tack Multi-Device QA Brief (mobile-agent-testers)

You are testing **Tack** (`com.notes.tacknotes`), an offline-first Android Flutter note-taking, whiteboard flowchart, and task app backed by a native Rust SQLite/FTS5 engine.

## Locked Product Invariants (Flag any violation as `blocker`)
1. **Notes & Boards are GRID ONLY** — no list/grid toggle should exist anywhere.
2. **Navigation hierarchy**: `Home → Read mode → Edit mode → Back returns to Read mode → Back returns to Home`.
3. **Zero crash on launch or board close**: Opening Tack must transition cleanly without closing; opening any Whiteboard and pressing Back (HUD back button OR Android system back) must return to the Boards tab cleanly without closing the app.
4. **No slow fade ghosting**: Toggling `To do` ↔ `Completed` on Today must switch crisply without ghosting/fading text.
5. **Visual Identity & Separation**:
   - Floating Apple Liquid Glass bottom nav bar + detached `( + )` orb must stay visually distinct from both light `#F3F4F6`/`#FFFFFF` cards and dark `#0F1012`/`#18191C` surfaces.
   - `DM Sans` typography everywhere (`JetBrains Mono` strictly for code blocks).
   - Touch targets ≥ 48dp; zero RenderFlex yellow/black overflow stripes at `1.0x`, `1.3x`, and `2.0x` font scale.

## Core Flows to Verify on Every Device Persona
1. **Cold Launch** — Confirm zero white/blank stall and immediate Today screen render.
2. **Today Tab** — Inspect Daily Note card, toggle `To do` ↔ `Completed`, check/uncheck one task, open a reminder sheet and cancel cleanly.
3. **Library Tab** — Scroll the lazy 2+ column grid, verify card heights & tag pills, open a note in Read mode, tap to Edit mode, press Back (must return to Read mode), press Back again (must return to Library).
4. **Boards Tab** — Open a Whiteboard, pan/zoom, tap HUD Back button (must return to Boards tab, NOT exit app).
5. **Search Tab** — Type a query, verify instant results and clean spacing.
6. **Quick Capture (`+`)** — Open Create sheet, verify clean radii/borders (no double stroke) and dismiss.
7. **Profile / Settings & About Tack** — Open Settings, toggle Dark/Light mode, open About Tack & Release Notes, verify crisp layout and zero infinite scroll bugs.

## Output Format
For each persona write:
- `results/<persona>/report.md`: 5-line device summary, severity-ordered issues (`blocker` / `major` / `minor` / `cosmetic`) with screenshot numbers, layout/contrast notes, and score `/10`.
- `results/<persona>/findings.json`: `{"score": N, "issues": [{"title": "...", "severity": "...", "screen": "...", "screens": ["01"]}]}`
