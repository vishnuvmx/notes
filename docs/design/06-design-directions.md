# 06 — Design Directions

> Three distinct directions, presented before any is chosen. A recommendation is given at the end, clearly marked as a recommendation.
> All values below are **proposals** for exploration in Figma. Contrast ratios were computed (WCAG 2.x relative luminance) during this review.

---

## 0. Constraints every direction must satisfy

| Source | Constraint |
|---|---|
| Brief | No excessive gradients; no unneeded glassmorphism; no random floating cards; no excessive rounded containers; no decorative elements without purpose; no unnecessary animation; one icon style |
| Verified code | Offline-first: **fonts must be bundled** (today `google_fonts` fetches at runtime); `lucide_icons_flutter` is the real icon set |
| `AGENTS.md` Locked #1 | Notes view is a **grid** |
| `AGENTS.md` Locked #4 | All values from tokens |
| Brand | The launcher icon is **saturated red with a paper mascot**; the current UI uses none of it |
| Accessibility | ≥4.5:1 text, ≥3:1 UI, 48 dp targets |
| Domain | Pastel object colours (8 palettes) are a user-facing feature (note/node colour); they are *data colours*, not chrome colours |

A principle shared by all three: **separate chrome colour from object colour.** Chrome (navigation, buttons, bars) is neutral plus at most one accent. Object colour (note, node, sticky) is the only place pastels appear. Today both are pastel-flavoured, which makes the UI feel busy and makes colour stop meaning anything.

---

## Direction A — "Paper & Pin"

**Personality:** a well-kept notebook with a single red thumbtack. Calm, warm, literate. The brand pun (*tack*) is the system: pins mark what is pinned, what is connected and what is captured.

| Aspect | Specification |
|---|---|
| **Typography** | UI: **DM Sans** (already in the app; keep equity) 400/500/600. Reading titles in Read mode: a text serif such as **Newsreader** or **Source Serif 4** (OFL) at 28–32 sp. Metadata and code: **JetBrains Mono** (already in the app for code). Three families, each with one job. All bundled as assets. |
| **Colour** | Warm paper canvas `#F7F6F3`; white surfaces `#FFFFFF`; ink `#1B1A17` (16.1:1 on canvas). Secondary text `#55514A` (7.3:1), tertiary `#6B665D` (5.27:1). **One accent: Pin Red `#D92D20`** (white on it 4.83:1; red on canvas 4.47:1 — use `#C2271B`, 5.4:1, for red *text/links*). Pastels appear **only** on objects. |
| **Surface treatment** | Flat. **1 px hairline borders** (`#E4E1DA`) instead of shadows on content; one soft shadow reserved for things that float above content (menus, the Capture sheet, board selection bar). Radii: 8 for controls and chips, 12 for cards, 16 for sheets; pill only for tags. |
| **Navigation** | Bottom bar with five slots (Today · Library · + · Boards · Search). Active slot = ink icon with a small pin-red dot, not a filled pill. No drawer. |
| **Components** | Primary button = **ink fill** (not red), so red keeps its meaning. Cards: white, hairline border, colour shown as a 6 dp left edge or a top band in the object's pastel — never full-fill. Inputs: bottom hairline that thickens on focus. |
| **Illustration** | The existing mascot, used in exactly three places: empty states, first-run, and "all clear" in Inbox. One pose, flat, two colours (red and white). No scatter marks. |
| **Iconography** | Lucide at 24 dp, **1.75 px stroke** if the Flutter package exposes that weight [Hypothesis; check `lucide_icons_flutter` variants] else 2 px; **filled variant only for the active nav slot**. A custom *pin* glyph (4 sizes) is the single bespoke icon. |
| **Board** | Dot grid, white paper canvas; node ports drawn as **small pin heads**; selection bar anchored to screen, not scaled. Connector colour = ink 60 %. Nodes use pastel fill with ink text. |
| **Desktop** | Left rail on paper-warm tone, hairline-separated panes, readable column max-width ~720 dp in Read mode, serif titles. |
| **Mobile** | Large serif titles on Read, tactile press states, thumb-zone capture. |
| **Dark theme** | Warm charcoal, not blue-black: canvas `#141311`, surface `#1D1C19`, text `#F2F0EB` (16.3:1), tertiary `#8F8A80` (4.96:1 on surface), pin `#FF6B5E` (6.1:1). Objects use deep tints of their pastel (all ≥9.9:1 with text). |
| **Risks** | Serif + sans + mono is three families; discipline needed. Resembles Notion's paper-warm mood — differentiate by the pin motif and red accent. |
| **Fit** | Persona A (writes and reads long-form), brand-red continuity. |

*Screen sketch — Library (mobile):*
```
┌───────────────────────────┐
│ Library          ⌕   ●you │   ← 56 dp bar, hairline bottom
│ Pinned · Work · #spec  ▾  │   ← filter chips, 48 dp
│ ┌────────┐ ┌────────┐     │
│▌Spec: Aut│ │▌Standup  │    │   ← white cards, 6 dp pastel edge
│ Draft ·2h│ │ 3 tasks  │    │
│ └────────┘ └────────┘     │
│        ...                │
├───────────────────────────┤
│ Today Library ＋ Boards ⌕ │
└───────────────────────────┘
```

---

## Direction B — "Index Card"

**Personality:** physical stationery, bold and tactile. An evolution of what Tack already is (pastel cards, "tactile"), but disciplined: the card is *the* component, drawn with ink outlines and hard offset shadows. Playful, recognisable, loud.

| Aspect | Specification |
|---|---|
| **Typography** | **Space Grotesk** or **DM Sans 700–800** for headings; **DM Sans 400/500** for body; **IBM Plex Mono** for labels. Tight tracking on headings only. |
| **Colour** | Paper `#FBF8F1`, ink `#111111`, **objects carry the saturation**: pastels at full strength as card fills (ink text is 5.78–13.6:1 on today's pastels [Verified]). Chrome is black-and-white. Accent for actions: ink. |
| **Surface treatment** | **2 px ink outline; hard offset shadow** (e.g. 3 dp right, 3 dp down, zero blur) in ink on cards and buttons. Pressed state: shadow collapses. No gradients, no blur. Radii small and consistent: 4 dp (controls), 8 dp (cards). |
| **Navigation** | Bottom bar with tab labels in mono caps; active tab = filled ink block with paper text. |
| **Components** | Cards are the primary object everywhere, including tasks and inbox items (as thin cards). Buttons are blocky with the hard shadow. Chips are outlined rectangles. |
| **Illustration** | Hand-cut shapes and one repeated sticker/stamp device ("PINNED", "INBOX", "DONE") in mono caps. Mascot used larger. |
| **Iconography** | Lucide at **2.25–2.5 px stroke**, square caps, to match the outline weight. |
| **Board** | Index-card nodes with the same outline/shadow; connectors in ink, 2 px; strong, graphic. |
| **Desktop** | Pane borders in 2 px ink; looks like a poster; high personality, higher fatigue in long sessions. |
| **Mobile** | Excellent for a Library of short notes; tiring for dense Read mode. |
| **Dark theme** | Inverts awkwardly (hard shadows need light ink on dark); likely needs a separate treatment. |
| **Risks** | Distinctive but **divisive**; long-form reading surface must fall back to a plain paper area, creating two languages in one app. Hard-shadow components cost more to draw consistently in Flutter (custom `BoxDecoration`, no Material elevation). |
| **Fit** | Persona B, short-note users; weak for Persona A's spec writing. |

---

## Direction C — "Graphite Instrument"

**Personality:** a precise tool for thinking at night. Dark-first, dense, quiet. Closer to a code editor or a measuring instrument than a notebook. Confidence through restraint.

| Aspect | Specification |
|---|---|
| **Typography** | **Inter** or **Geist** for UI at 14–15 sp (denser than today); **JetBrains Mono** for metadata, dates, counts, ids; headings in the same family at 600. |
| **Colour** | Graphite neutrals: canvas `#101214`, surface `#171A1D`, raised `#1F2327`, hairline `#2A2F34`; text `#E8EAED` / `#A3AAB2` / `#7F8790`. **One signal colour:** electric cyan `#35C2E0` for focus and selection, amber `#F5B842` for "needs attention" (Inbox count). Pastels shown as small colour chips, never fills. Light theme = inverted, cool-white. |
| **Surface treatment** | Zero shadows; separation by tone steps and hairlines. 6–8 dp radii. |
| **Navigation** | Bottom bar icons only with a thin underline; **command palette first** — search/"Do anything" is the primary entry and sits in the top bar. |
| **Components** | List-dense rows (but grid-only rule applies to notes; the grid uses compact cards), mono metadata line under every title, keyboard-hint chips on desktop. |
| **Illustration** | None. Mascot only in the About screen. |
| **Iconography** | Lucide at 1.5 px stroke. |
| **Board** | Dark dot-grid, thin 1 px connectors, nodes as tinted outlines with a pastel dot; strongest of the three at "spatial thinking tool". |
| **Desktop** | Excellent: dense panes, command palette, keyboard-driven. |
| **Mobile** | Reads as serious; risks feeling cold and loses the brand's friendliness. Dense text hurts at large font scale. |
| **Risks** | Abandons brand red and playfulness; dark-first conflicts with the first-launch **Light** default and with outdoor phone use; accent colours are conventional ("developer tool" look), i.e. closest to a generic aesthetic. |
| **Fit** | Desktop-first Persona A, power users. |

---

## Comparison

Scores 1 (poor) – 5 (strong), **my judgement [Hypothesis]**:

| Criterion | A Paper & Pin | B Index Card | C Graphite |
|---|---|---|---|
| Continuity with existing brand (red icon, tactile, pastels) | 4 | 5 | 1 |
| Long-form reading comfort | 5 | 2 | 4 |
| Suitability for spatial board | 4 | 4 | 5 |
| Accessibility headroom (contrast, targets, text scale) | 5 | 4 | 3 |
| Distinctiveness / recognisability | 4 | 5 | 2 |
| Avoids "generic AI dashboard" look | 4 | 5 | 2 |
| Flutter implementation cost (tokens, components) | 4 | 2 | 4 |
| Dark-mode quality | 4 | 2 | 5 |
| Desktop readiness | 4 | 3 | 5 |
| Risk of fatigue over time | 4 | 2 | 4 |
| **Total (of 50)** | **42** | **34** | **35** |

---

## Recommendation (not yet a decision)

**Take Direction A as the base,** because it fits Tack's real niche (writing specs and reading them back), reconnects the UI to the red brand, makes pastels meaningful by confining them to objects, and is the cheapest to build on the existing token layer. Borrow selectively:

- From **B**: the *tactile press response* (scale/shadow collapse) on cards and the FAB, and "stamp" labels for states (PINNED, INBOX) — as a small, optional accent, not the structure.
- From **C**: the **dark theme logic** (tone steps and hairlines instead of shadows) and the board's dark dot-grid, plus the command-first search.

**Sign-off needed from the product owner:** pick A, B, C or a named hybrid before `07-design-system.md` tokens are frozen in Figma variables. The tokens in `07` are written for A so that they can be tested; swapping to B or C changes values, not structure.

### How to test the choice cheaply (1 day)
Build the **same three screens** in each direction: Library (mobile), Note Read, Board with 12 nodes. Show 5 people in pairs of two at a time and ask: "Which would you trust with notes you can't lose?" and "Which would you keep on your phone for a year?". Record, don't average.
