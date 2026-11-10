# 07 — Design System (proposal for Direction A, "Paper & Pin")

> **Status: proposal.** Written for Direction A so tokens can be tested; B or C would change values, not structure (`06-design-directions.md`).
> Today's tokens live in `lib/core/theme/{app_colors,app_spacing,app_typography,app_theme,tack_icons}.dart`. This document does not change them.
> All contrast figures were **computed** during this review (WCAG 2.x). Anything that depends on a package capability I could not check is marked **[Hypothesis]**.

---

## 1. Principles

1. **One source of truth.** Every colour, size, radius, shadow, duration and text style is a named token (Locked Decision #4). Figma variables and Flutter tokens share names.
2. **Chrome is neutral; objects carry colour.** Pastels colour notes and nodes only.
3. **Hierarchy by weight and tone, not by decoration.** No gradients, no glass, no ornamental shadows.
4. **Every control has one job and one home** (Locked Decision #2).
5. **Touch first, scalable always.** 48 dp targets; no fixed-height containers that hold text; designs verified at 100 %, 130 % and 200 % font scale.
6. **Offline means self-contained.** Fonts and icons are bundled assets.
7. **Colour is never the only signal.** Every pastel has a name exposed to assistive tech and an icon/label where meaning matters.

---

## 2. Colour

### 2.1 Neutral and semantic tokens

| Token | Light | Dark | Role | Contrast (text on its background) |
|---|---|---|---|---|
| `bg/canvas` | `#F7F6F3` | `#141311` | App background | – |
| `bg/surface` | `#FFFFFF` | `#1D1C19` | Cards, sheets, inputs | – |
| `bg/sunken` | `#EFEDE8` | `#0E0D0C` | Wells, code blocks, selected row | – |
| `border/subtle` | `#E4E1DA` | `#2A2824` | Hairlines on content | decorative |
| `border/strong` | `#CFCBC2` | `#3B3833` | Input outlines, dividers that must be seen | ≥3:1 target on canvas |
| `text/primary` | `#1B1A17` | `#F2F0EB` | Body, titles | 16.1 : 1 on `bg/canvas` · 16.3 : 1 |
| `text/secondary` | `#55514A` | `#B3AEA3` | Supporting text | 7.3 : 1 · 8.4 : 1 |
| `text/tertiary` | `#6B665D` | `#8F8A80` | Timestamps, hints (minimum: still body-legible) | 5.27 : 1 on canvas, 5.7 : 1 on white · 5.41 : 1 on `#141311`, 4.96 : 1 on `#1D1C19` |
| `accent/pin` | `#D92D20` | `#FF6B5E` | Pin motif, active-slot dot, brand moments | 4.83 : 1 (white on it) · 6.65 : 1 on dark canvas |
| `accent/pin-text` | `#C2271B` | `#FF6B5E` | Red used as text/links | 5.4 : 1 on canvas |
| `action/primary` | `#1B1A17` | `#F2F0EB` | Primary button fill | 17.4 : 1 (white on it) |
| `focus/ring` | `#1B1A17` 2 px + 2 px offset | `#F2F0EB` | Keyboard/D-pad focus | ≥3:1 |
| `state/success` | `#1A7F5A` | `#4FC79A`* | Done, saved | 4.97 : 1 on white |
| `state/warning` | `#B54708` | `#F5A25D`* | Needs attention | 5.43 : 1 on white |
| `state/info` | `#175CD3` | `#7FB0FF`* | Neutral info | 5.99 : 1 on white |
| `state/danger` | `#C2271B` | `#FF6B5E` | Destructive | 5.83 : 1 (white on it) |

\* Dark-mode semantic values are proposals not yet contrast-checked; check them before freezing variables.

**Rules.** Primary buttons are **ink**, never red (red must stay the brand/pin colour and must not be confused with *danger*). Danger always pairs colour with an icon and the word. Disabled = 38 % opacity with a visible label change, never colour alone.

### 2.2 Object palette (8 colours)

Replaces the current 8, which contain two near-duplicate pairs (Peach/Terracotta, Amber/Yellow) and one missing documented colour (Slate). The new set matches the eight names in `AGENTS.md`: Peach, Amber, Coral, Lavender, Cyan, Lime, Rose, Slate.

| id | Name | Light fill | Ink `#1B1A17` on fill | Dark fill | Text `#F2F0EB` on fill |
|---|---|---|---|---|---|
| `amber` | Warm Amber | `#FFD27A` | 12.22 : 1 | `#4A2F12` | 10.81 : 1 |
| `peach` | Sunset Peach | `#FFB59C` | 10.23 : 1 | `#4A2418` | 11.84 : 1 |
| `coral` | Coral Blush | `#F2A6A6` | 8.93 : 1 | `#4A1E1E` | 12.33 : 1 |
| `lavender` | Lavender Mist | `#C9B8F2` | 9.63 : 1 | `#2E2650` | 12.22 : 1 |
| `cyan` | Cyan Breeze | `#8FD6E6` | 10.71 : 1 | `#124049` | 9.94 : 1 |
| `lime` | Lime Zing | `#D6E88F` | 13.09 : 1 | `#343F12` | 9.88 : 1 |
| `rose` | Rose Bubble | `#F5B8D0` | 10.48 : 1 | `#4A1E33` | 12.09 : 1 |
| `slate` | Slate Pure | `#D9DEE6` | 12.88 : 1 | `#2F3440` | 10.94 : 1 |

Usage: **fill on board nodes; 6 dp edge or top band on cards; never as a button or chrome colour.** Migration note: map old ids `terracotta → peach`, `yellow → amber`, unknown `slate` stays `slate`.

**Do not** use the old `indexColor` accents as text on white: Peach `#D66033` is 3.76 : 1, Cyan `#0F8698` 4.30 : 1, Lime `#869E1C` 3.03 : 1 (all fail 4.5 : 1) [Verified by calculation].

### 2.3 Informed by the supplied `DESIGN.md` (Notion marketing reference)

| Idea | Verdict | Note |
|---|---|---|
| Warm off-white canvas with white cards | **Adopt** | `#F7F6F3` / `#FFFFFF`; kept the warm cast but not the same hex |
| Hairline borders instead of shadows on content | **Adopt** | `border/subtle` |
| Hierarchy via alpha of one text colour | **Modify** | Use named tones (`primary/secondary/tertiary`) so contrast is guaranteed; alpha text over varied backgrounds is hard to verify |
| One chromatic filled action (blue) | **Modify** | Tack's one chromatic *accent* is Pin Red, and the filled action is **ink** |
| Rotating accent hues for feature panels | **Reject for chrome; adopt for objects** | Object palette only |
| `#757575` secondary text | **Reject** | 4.23 : 1 on `#F6F5F4`, fails AA for body text |
| Hero highlight pill, decorative character marks, logo wall | **Reject** | Marketing devices; no product purpose |
| Display sizes 54–96 px with −4.6 px tracking | **Reject** | Not applicable to a phone app |
| Editorial serif for specific moments | **Adopt narrowly** | Read-mode titles only |
| 200 ms ease transitions | **Adopt** | Functional only |

---

## 3. Typography

All families bundled as assets (OFL-licensed: DM Sans, Newsreader or Source Serif 4, JetBrains Mono). Today the app depends on runtime font download [Verified: no `fonts:` in `pubspec.yaml`].

| Token | Family | Size / line height (sp) | Weight | Tracking | Use |
|---|---|---|---|---|---|
| `display` | Serif | 32 / 38 | 600 | −1 % | Read-mode note title |
| `title-lg` | DM Sans | 24 / 30 | 700 | −2 % | Screen titles on large screens, sheet titles |
| `title` | DM Sans | 20 / 26 | 600 | −1.5 % | App bar titles, section heads |
| `title-sm` | DM Sans | 17 / 24 | 600 | −1 % | Card titles, list row titles |
| `body-lg` | DM Sans (note body may switch to serif; test in Figma) | 17 / 26 | 400 | 0 | Read mode paragraphs |
| `body` | DM Sans | 16 / 24 | 400 | 0 | Edit mode, default text |
| `body-sm` | DM Sans | 14 / 20 | 400 | 0 | Secondary text, card summaries |
| `label` | DM Sans | 13 / 16 | 500 | +0.1 % | Chips, buttons, tabs |
| `caption` | DM Sans | 12 / 16 | 400 | +0.2 % | Timestamps, counts. **12 sp is the floor.** |
| `mono` | JetBrains Mono | 13 / 20 | 400 | 0 | Code, ids, metadata |

**Deviation to approve:** `AGENTS.md` asks for ~−2 % tracking across the hierarchy. For ≤16 sp body text, negative tracking reduces legibility on small screens [Hypothesis; test at 100 % and 200 % scale], so tracking relaxes to 0 for body and caption. Titles keep −1 % to −2 %.

**Text scaling:** components must use `minHeight` and intrinsic sizing, not fixed heights. Replace today's `SizedBox(height: 218)` card, 220 dp folder grid extent and 82 dp template strip. Verify at 200 %.

---

## 4. Layout and spacing

### 4.1 Scale (4 dp base)
`space/0=0 · 1=2 · 2=4 · 3=8 · 4=12 · 5=16 · 6=20 · 7=24 · 8=32 · 9=40 · 10=48 · 11=64`

### 4.2 Metrics
| Token | Value | Notes |
|---|---|---|
| `touch/min` | 48 dp | Visual may be smaller; hit area never |
| `gutter/screen` | 16 dp | 24 dp on ≥ 600 dp |
| `gap/grid` | 12 dp | Library grid |
| `appbar/height` | 56 dp | |
| `bottombar/height` | 64 dp + system inset | |
| `row/height` | 56 dp min | Lists; grows with text scale |
| `read/maxwidth` | 720 dp | Centre the column on wide screens |
| `sidebar/width` | 240–280 dp | Desktop/tablet only |
| `list-pane/width` | 320–400 dp | Desktop/tablet only |

### 4.3 Grid and window classes
Android window size classes: compact < 600 dp, medium 600–839 dp, expanded ≥ 840 dp [Background; confirm against current Android guidance].

| Class | Library grid | Layout |
|---|---|---|
| Compact | 2 columns | Single pane, bottom bar |
| Medium | 3 columns | Single pane, navigation rail |
| Expanded | 4 columns or list-pane + detail | Rail + list-pane + detail |

Card height is **intrinsic** (min 120 dp); this needs a lazy staggered/masonry grid. Flutter's built-in `SliverGrid` requires fixed extents, so a package such as `flutter_staggered_grid_view` or a custom sliver is a likely dependency [Hypothesis; evaluate]. Today's home grid builds every card eagerly in two `Column`s [Reported].

---

## 5. Radii, borders, elevation

| Token | Value | Use |
|---|---|---|
| `radius/xs` | 4 dp | Tags inside text, code chips |
| `radius/sm` | 8 dp | Buttons, inputs, chips |
| `radius/md` | 12 dp | Cards, menus |
| `radius/lg` | 16 dp | Sheet top corners, dialogs |
| `radius/pill` | 999 | Tags and the Capture button only |
| `border/hair` | 1 dp `border/subtle` | Default separation |
| `elev/0` | none | Content |
| `elev/1` | blur 16, y 6, α 0.10 | Menus, selection bar, popovers |
| `elev/2` | blur 24, y 8, α 0.12 | Sheets, dialogs |
| `scrim` | black α 0.40 | Behind sheets |

Collapsing today's radius set (6, 8, 10, 12, 13, 14, 16, 18, 20, 24, 32) to five removes about a dozen magic numbers.

---

## 6. Iconography

- **Set:** Lucide (already the real dependency; `heroicons` is *not*) via a single `TackIcon` wrapper; eliminate direct `LucideIcons.*` and `Icons.*` uses (≈80 occurrences).
- **Size:** 20 (inline), 24 (default), 32 (empty states). **Stroke:** 1.75 px if the package supports it [Hypothesis] else 2 px; filled style only for the active nav slot and the pin.
- **Custom glyphs:** Pin (4 sizes), Inbox, Board. The 18 SVGs in `icons/` should be audited against Lucide; replace duplicates.
- **Semantic fixes:** sort icon ≠ list-view icon; saving state ≠ undo icon; forward chevron ≠ chevron-down.

---

## 7. Components

Sizes in dp. **States** for all interactive components: default · pressed · focused · disabled · selected · (error where input).

| Component | Spec | Notes |
|---|---|---|
| **Button – primary** | h 48, radius 8, fill `action/primary`, label `label` in `bg/canvas` | One per screen region |
| **Button – secondary** | h 48, 1 dp `border/strong`, ink text | |
| **Button – text** | h 48, ink text, no border | |
| **Button – danger** | as secondary with `state/danger` text + icon | Confirmation only for irreversible actions |
| **Icon button** | 48×48 hit, 24 icon | |
| **Capture button (+)** | 56×56 circle, ink fill, paper plus icon, `elev/1`; only pill/circle in chrome | Sole create control |
| **Chip / filter** | h 40 (hit 48), radius 8, hairline, selected = `bg/sunken` + ink | Replaces `GestureDetector` pills without ripple |
| **Tag** | h 24, pill, `caption`, border-only | Non-interactive unless inside a filter |
| **Text field** | h 48, hairline bottom border → 2 dp on focus; clear button 48 hit | One shared decoration; fixes the global `InputDecorationTheme` leak noted in `AUDIT.md` |
| **Search field** | as text field + leading icon; optional trailing clear | Single widget used everywhere |
| **Note card** | surface, hairline, radius 12, padding 12; 6 dp object-colour band at the leading edge; title `title-sm` (max 2 lines); summary `body-sm` (max 3); footer `caption` (date, pinned pin glyph) | **No rotation.** Min height 120 |
| **Board card** | same frame; 120 dp thumbnail rendered from the board | Replaces glyph-only card |
| **Inbox card** | surface, source-app chip, text preview, 3 actions as 48 dp buttons | |
| **Task row** | 56 dp, 24 dp checkbox in 48 hit, text, note name `caption` | |
| **Property pill** | h 32 (hit 48), radius 8, key `caption` + value `label` | One edit surface (the pill sheet) |
| **App bar** | 56; variants: *Library* (title + search + You), *Note* (back, title, mode toggle, overflow), *Board* (back, title, undo, redo, overflow) | Max 3 trailing icons |
| **Bottom bar** | 64 + inset; 5 slots; active = filled icon + pin dot | Labels always visible |
| **Editor toolbar** | docked above keyboard, 48 dp buttons, horizontally scrollable, undo/redo pinned left | Replaces 38 dp buttons |
| **Bottom sheet** | one drag handle (36×4), radius-lg top, scrim, max height 90 %, bottom padding = `max(keyboard, safe-area)` | A single `AppBottomSheet`; no raw `showModalBottomSheet` |
| **Peek sheet** | sheet variant, 3 lines of content preview + action row | Long-press on cards |
| **Menu / popup** | radius 12, `elev/1`, items 48 dp | |
| **Dialog** | radius 16, max width 320; used only for irreversible or text-entry prompts | |
| **Toast** | one component; bottom offset derived from bottom-bar height token; action 48 hit | Replaces `TackToast`, hand-rolled snackbar, stock `SnackBar` |
| **Empty state** | mascot 96 dp, title, one sentence, one action | Mascot only here, first run, Inbox-zero |
| **Skeleton** | `bg/sunken` blocks, no shimmer | Reduce-motion safe |
| **Inline error** | icon + message + retry, `state/danger` | New: today there are none |
| **Selection bar (board)** | screen-space, `elev/1`, 48 dp actions | Not scaled with canvas zoom |
| **Backlinks panel** | collapsible; default = count chip; expand on tap | From Notion's display-mode idea |

### 7.1 Board tokens
| Token | Value |
|---|---|
| `board/grid-dot` | 1.5 dp at 20 dp spacing, `border/subtle` |
| `board/node/min` | 56 × 40 dp (today 50 × 36) |
| `board/connector` | 2 dp, `text/primary` α 0.6 |
| `board/port` | 10 dp pin head visual, 48 dp hit target in screen space |
| `board/handle` | 16 dp visual, 48 dp hit, screen space |
| `board/zoom` | 0.2 – 3.0 [Hypothesis; today 0.15 – 3.5] |
| `board/selection` | 2 dp `focus/ring` + 8 dp handle squares |

---

## 8. Interaction principles

| Area | Principle |
|---|---|
| **Feedback** | Every tappable surface shows pressed feedback (Material ink or scale 0.98 on cards). No raw `GestureDetector` on interactive chips |
| **Destruction** | Prefer **undo over confirm**: delete → toast with Undo. Confirm only for permanent delete and Restore → Replace |
| **Focus (keyboard/D-pad)** | Visible `focus/ring`; logical order; `Esc` closes menus/sheets |
| **Selection** | Long-press to enter selection on cards (post-MVP) and board nodes; a bar shows count and actions |
| **Drag and drop** | Board node drag, Library → folder (desktop) |
| **Gestures** | Edge-swipe back is never intercepted (keep the 28 px edge-zone rule from the board); pinch/pan only on canvas |
| **Haptics** | Selection tick on commit actions (save, pin, connect). None on scroll or hover |
| **Motion** | 100 ms press · 150 ms fade/scale · 250 ms sheet/page. One easing `easeOutCubic`. **No bounce/spring**; respect `disableAnimations` |
| **Loading** | Skeletons ≥ 300 ms; never flash an empty state during hydration |
| **Errors** | Say what failed, what is safe, what to do |
| **Keyboard (desktop)** | `Ctrl+K` search/actions, `Ctrl+N` capture, `Ctrl+F` find, `Ctrl+Z/Y`, `Ctrl+/` insert |
| **Back** | `Library/Today → Read → Edit`; Back from Edit flushes save and goes to Read |
| **Accessibility** | Semantics on cards, nav slots, FAB, checkboxes, board nodes (label = text + shape + colour name); 200 % text; Reduce Motion; contrast ≥ 4.5 : 1 text, 3 : 1 UI |

---

## 9. Figma variable architecture

```
Collections
├── 01 Primitives          (raw: neutral/50…900, red/500, object/amber/light, space/*, radius/*)
├── 02 Semantic            modes: Light | Dark
│     bg/*, text/*, border/*, accent/*, action/*, state/*, object/<id>/fill, object/<id>/on
├── 03 Type                text styles bound to tokens (display … mono)
├── 04 Component           button/height, card/padding, board/*
└── 05 Density/Scale       modes: 100% | 130% | 200% (for text scale previews)
```

Naming: `group/role/state` (e.g. `text/secondary`, `object/amber/fill`). Components use semantic variables only; never primitives.

### Mapping to current code (for the later implementation phase)

| Current | Proposed |
|---|---|
| `AppColors.lightBackground / darkBackground` | `bg/canvas` |
| `AppColors.lightSurface / darkCard` | `bg/surface` |
| `AppColors.lightBorder / darkBorder` | `border/subtle` |
| `AppColors.lightTextPrimary / …Secondary / …Muted` | `text/primary / secondary / tertiary` |
| `AppColors.presetPalettes[i].lightColor/darkColor/softBackground/indexColor/pinColor` | `object/<id>/fill` (light/dark) + `object/<id>/name`; drop `soft`, `index`, `pin` |
| `AppSpacing.xs…xxxl, radiusSm…radiusPill, *Shadow*` | `space/*`, `radius/*`, `elev/*` |
| `AppTypography.sectionHeadline, cardTitleStyle, …` | `title-lg`, `title-sm`, … |
| 344 `Color(0x…)` + 279 inline `TextStyle(` in widgets | Zero; lint rule to forbid |

A single `ThemeExtension<TackTokens>` carrying these values is the natural Flutter carrier [Hypothesis; confirm in `08`].

---

## 10. Definition of done for a component (before it is built)

1. All states drawn in light and dark.
2. Drawn at 100 %, 130 %, 200 % font scale without fixed heights.
3. 48 dp hit area annotated.
4. Semantics label and role written.
5. Uses only semantic variables.
6. Appears in the component page with usage, do and don't.
