# UI_change.md — Tack Visual Identity & Multi-Device UI Diff Tracker

> Temporary working log for visual identity iterations, verified across multiple Android device personas (`qa/mobile-agent-testers/`) and checked with pixel/region diffs (`qa/ui-diff/`).

---

## 1. Visual Identity Contract (Current Baseline)

| Surface / Token | Light Mode | Dark Mode | Notes |
|---|---|---|---|
| App Canvas (`bgCanvas`) | `#F3F4F6` | `#0F1012` | Matches Android `NormalTheme` & launch splash background |
| Elevated Card (`bgSurface`) | `#FFFFFF` | `#18191C` | Grid-only cards (`NeoNoteCard`, `BoardGridCard`), `16dp` squircle |
| Typography | `DM Sans` | `DM Sans` | `JetBrains Mono` strictly for code blocks; `-1%` to `-2%` tracking |
| Floating Nav Bar (`SmartBottomNavBar`) | Apple Liquid Glass (`#CBE7EBF3 → #B8D9E0EC`, `blur 24`, specular rim + `17%` outer hairline) | Smoked Obsidian Glass (`#CC262933 → #BA171920`, `blur 24`, specular rim) | Crystalline optical lens pill + finger-scrubbing + detached `( + )` orb |
| Page Transitions (`TackCardOpenContainer`, `TackRoutes`) | Crisp `160ms` open / `130ms` close pure slide | Crisp `160ms` open / `130ms` close pure slide | Zero fade ghosting; zero `OverflowBox`/`GlobalKey` reparenting |
| Today `To do` ↔ `Completed` | Instant content switch + `180ms` height settle | Instant content switch + `180ms` height settle | Zero opacity fade on task rows; spring pill glide on segment header |

---

## 2. Logged Visual Identity Changes (Working Iteration List)

| ID | Area | Change Made | Visual Goal | Multi-Device Check | Status |
|---|---|---|---|---|---|
| `UI-01` | **Smart Bottom Nav** | Upgraded from flat grey capsule (`#EAECEF`) to Apple Liquid Glass (`BackdropFilter`, specular curved rim, outer contrast hairline, interactive sliding lens) | Separate dock cleanly from light/white cards and dark backgrounds; elevate brand feel | Light / Dark / 720p / Tablet | Needs live visual diff review |
| `UI-02` | **Today Task Toggle** | Removed `AnimatedSwitcher` + `FadeTransition` between `To do` and `Completed` | Eliminate ghosting/fading text when switching segments | Light / Dark / 1.3x–2.0x | Ready |
| `UI-03` | **Note & Board Open/Close** | Replaced `OpenContainer` / container-transform with direct 160ms/130ms hardware slide; removed 3× `6000×6000` whiteboard `RepaintBoundary`s | Instant opening, zero glitches, zero board-close crash | All personas | Ready |
| `UI-04` | **App Cold Launch** | Native Android splash overlay (`launch_background` with `@drawable/ic_launcher_foreground`) removed on `onFlutterUiDisplayed()` + parallel boot + lazy tabs | Zero blank white/grey flash when opening Tack | Light / Dark (API 30–36) | Ready |
| `UI-05` | **About Tack & What's New** | Bare `48×48` logo, colored `16.5sp` headings without squircle/icon boxes, removed Architecture & Full License Notices | Cleaner visual hierarchy, zero slop | Light / Dark / 1.3x | Verified |
| `UI-06` | **Whiteboard HUD & Spec Sheet** | `MainAxisAlignment.spaceBetween` on top HUD capsules; cleaned up Canvas Spec Card sheet | Clean breathing room across narrow & wide screens | Phone / Tablet | Verified |

---

## 3. Open Visual Polish Backlog (Work Here Next)

- [ ] Review **Liquid Glass Nav Bar** contrast on `pixel_default_light`, `pixel_default_dark`, and `small_phone_dark` side-by-side in `.ui-diff/compare/`.
- [ ] Audit `<48dp` touch targets and unnamed TalkBack controls reported by `qa/mobile-agent-testers/a11y.py` across all 6 personas.
- [ ] Verify `accessibility_200` (200% font scale) and `compact_large_text` (1.3x on compact screen) for any text truncation in `Today`, `Library`, `Boards`, and `Search`.
- [ ] Verify `tablet_landscape` multi-column grid spacing and floating dock width (`maxWidth` cap on tablets so the Liquid Glass dock doesn't stretch awkwardly wide across 1600px!).

---

## 4. Workflow Commands

```powershell
# 1. Capture baseline screenshots + a11y + crash audit across all 6 Android device personas
.\qa\mobile-agent-testers\run_matrix.ps1 -RunName baseline

# 2. After making UI edits, install updated APK and capture current run
.\qa\mobile-agent-testers\run_matrix.ps1 -RunName current

# 3. Run ui-diff (pixelmatch + red bounding-box Before/After/Diff PNGs + blink GIFs + auto-update table below)
node qa\ui-diff\diff_runner.mjs --base .ui-diff\baseline --head .ui-diff\current
```

---

## 5. Latest `ui-diff` & Multi-Device Report

<!-- ui-diff:begin -->
_No captures run yet. Boot an Android emulator (`Pixel_API_36`) or connect a phone and run `.\qa\mobile-agent-testers\run_matrix.ps1 -RunName baseline`._
<!-- ui-diff:end -->
