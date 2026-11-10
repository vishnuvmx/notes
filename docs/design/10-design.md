# 10 — Tack Design: Consolidated Source of Truth

> **Status:** Draft v0.1 — consolidates documents 01–09. Everything here is **proposed** unless labelled *Current*. Where a decision is still open it is listed in §12 and the section says "pending Dn".
> **Supersedes** for design purposes: the design sections of `AGENTS.md`, `README.md`, `AUDIT.md`, `.agents/rules/project_context.md` (which no longer match the code; see §13).
> **Does not replace:** `AGENTS.md` for agent behaviour rules, until D4 is answered.
> Evidence labels: see `01-product-analysis.md`.

---

## 1. Purpose

A single place that says what Tack is, who it is for, how it is organised, how it looks and behaves, and what is deliberately excluded. Designers and developers should be able to answer "should this exist, where does it live, what does it look like?" from this file and follow links to detail.

---

## 2. Product definition

**One sentence (proposed):** *Tack is a phone-native, local-first thinking pad where written notes and flow diagrams are linked objects. Capture in one tap, shape it into a note, lay it out as a flow, carry the open tasks into tomorrow.*

**Audience (hypotheses, low confidence):**
- **A. Spec-and-flow thinker:** student/engineer/designer writing specs, decisions and diagrams.
- **B. Capture-everything Android user:** saves text, links and images from other apps.

**Differentiation test** — a feature must pass two of four:
1. Android-native advantage · 2. Note ↔ spatial link · 3. Local-first trust · 4. Phone-ergonomic.

**Journey:** Capture → Explore → Connect → Build → Execute → Reflect, with the largest gaps today in **Capture** (no inbox) and **Execute** (no task view). See `01` §5.4.

---

## 3. Scope

### 3.1 In the redesign MVP (see `04` §3)
Data safety and complete backup · stable links with rename safety · full-text search + "Do anything" sheet · Capture → **Inbox** · **Today** with open tasks · one insertion/transform menu · accessibility baseline · single token source · board performance and selection basics.

### 3.2 Later
Open-format export (Markdown + JSON Canvas) · widget redesign · local graph polish · spec↔board two-way · timeline · resurfacing · Spaces (gated on D1).

### 3.3 Retired or merged
Sticky as a separate type · Clipboard as a separate type/tab · Archive · drawer navigation · header theme toggle · static greeting · duplicate Today/Graph/Favorites/Create controls · About + Release Notes screens (replaced by one About) · persistent notification (unless explicitly kept).

### 3.4 Rejected (for now)
Focus sessions · contextual clipboard · "universal workspace" framing · databases/views/relations · collaboration, comments, permissions · plugin system · cloud sync · AI features.

---

## 4. Vocabulary

| Term | Meaning | Replaces |
|---|---|---|
| **Note** | A Markdown document with optional properties | Note, Sticky, Clip |
| **Board** | A typed flowchart canvas | Whiteboard |
| **Inbox** | The state of a note that was captured and not yet triaged | – (new) |
| **Today** | Home surface: today's note, Inbox count, open tasks, pinned | Home |
| **Library** | Grid of all notes with filters | Home/Notes tabs, drawer All Notes |
| **Pin** | Keep an item at the top and on Today | Favorite (+ "pin to top") |
| **Spec card** | A board node that points to a note | same |
| **Embed** | `![[Board]]` / `![[Board#node]]` in a note | same |
| **Link** | `[[Note]]` resolved to a stable id | same (title-based today) |
| **Task** | A `- [ ]` / `- [x]` line in any note (derived, not stored separately) | – |
| **Capture** | The single create control (+) and all Android capture entry points | Create sheet, Quick Note, Instant Blank Note |

Naming rules: sentence case; verbs for actions ("Save", "Pin", "Move to folder"); "Favorites" is retired in favour of "Pinned" (and the British/American "Favourites/Favorites" inconsistency disappears with it).

---

## 5. Information architecture (pending D1, D6, D8)

**Mobile bottom bar (5 slots):** Today · Library · **(+) Capture** · Boards · Search. No drawer. *You* sheet (from Today header): Trash, Settings, About.

**Hierarchy (Locked Decision #3, kept):** `Library or Today → Note (Read) → Note (Edit)`; Back from Edit flushes the save and returns to Read; Back from Read returns to the previous route. An untouched empty new draft is discarded on Back (D2 pending).

**Notes view is a grid** (Locked Decision #1, kept until D4). Library: 2/3/4 columns by window class; intrinsic card height; no rotation.

**One create control.** The (+) opens the Capture sheet. Every other create affordance is removed.

**Actions live in one place per object** (card long-press → peek sheet; note overflow; board selection bar). Details in `05` §5.

**Desktop/tablet (explore only, D7):** left rail + list pane + detail pane; keyboard model `Ctrl+K / N / F / Z / Y / /`.

Full graph, object model and flows: `05`.

---

## 6. Core flows (acceptance targets)

| Flow | Target |
|---|---|
| Capture from another app | ≤ 2 taps; editor not opened; saved to Inbox with source app |
| Start the day | Today's note ≤ 1 tap from launch |
| Write and link | `[[` → pick → link without leaving the keyboard |
| Spec to board | Pin note as spec card; v1.2: heading → "Add to board…" |
| Find | Full-text hit within 2 s on 1,000 notes, opens scrolled to the match |
| Triage | One decision per item, one-handed |
| Back up / restore | Preview counts equal library counts, Trash included |

---

## 7. Visual identity (pending D5; written for Direction A "Paper & Pin")

- **Idea:** a kept notebook with one red thumbtack. The pin is the only bespoke motif: pinned items, board ports, active nav slot, capture.
- **Chrome neutral, objects coloured.** Pastels only on notes, nodes and their edges/bands.
- **Brand red returns** as `accent/pin` (`#D92D20` light, `#FF6B5E` dark); **primary buttons are ink**, never red.
- **Type:** DM Sans (UI), a text serif (Read titles), JetBrains Mono (code/metadata); all bundled.
- **Surfaces:** flat, hairline borders; two shadow levels reserved for floating UI; radii 4/8/12/16/pill.
- **Illustration:** the existing mascot, in empty states, first run and Inbox zero only.
- **Icons:** Lucide via one `TackIcon` wrapper; no Material or raw Lucide in widgets.
- **Motion:** 100/150/250 ms, `easeOutCubic`, no bounce; respects Reduce Motion.
- **Avoid:** gradients, glass, rotating cards, decorative scatter marks, emoji in chrome.

Alternatives (B "Index Card", C "Graphite Instrument") and the scoring are in `06`.

---

## 8. Design tokens (summary; full tables in `07`)

| Group | Summary |
|---|---|
| Colour | Neutrals `bg/canvas #F7F6F3 · bg/surface #FFFFFF · text/primary #1B1A17 · text/secondary #55514A · text/tertiary #6B665D · border/subtle #E4E1DA`; dark counterparts `#141311 · #1D1C19 · #F2F0EB · #B3AEA3 · #8F8A80 · #2A2824`. States: success `#1A7F5A`, warning `#B54708`, info `#175CD3`, danger `#C2271B` |
| Objects | 8 fills: amber `#FFD27A`, peach `#FFB59C`, coral `#F2A6A6`, lavender `#C9B8F2`, cyan `#8FD6E6`, lime `#D6E88F`, rose `#F5B8D0`, slate `#D9DEE6`; dark tints in `07` §2.2 |
| Type | `display 32/38 serif · title-lg 24/30 · title 20/26 · title-sm 17/24 · body-lg 17/26 · body 16/24 · body-sm 14/20 · label 13/16 · caption 12/16 · mono 13/20` |
| Space | 4 dp base: 0, 2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64; touch min 48; screen gutter 16 (24 ≥ 600 dp) |
| Radius | 4 / 8 / 12 / 16 / pill |
| Elevation | none for content; `elev/1` menus, `elev/2` sheets |
| Motion | 100 / 150 / 250 ms |

All contrast values in `07` were computed; dark-mode semantic state colours are still to be checked.

---

## 9. Components and interaction (summary)

- **Inventory** and specs: `07` §7. Priority for Figma: button, icon button, chip, text/search field, note card, board card, app bar (Library/Note/Board), bottom bar, bottom sheet, menu, toast, empty state, task row, property pill, editor toolbar, selection bar.
- **One of each:** one bottom-sheet wrapper, one toast, one search field, one card frame, one icon wrapper.
- **Destruction:** undo over confirm; confirm only for permanent delete and replace-restore.
- **Properties:** single editing surface (the property sheet), not raw YAML plus pills.
- **Backlinks:** collapsed count chip by default.
- **Board:** selection bar in screen space; 48 dp hit areas on handles and ports regardless of zoom; marquee/multi-select, align, distribute, group, lock.

---

## 10. Accessibility requirements (non-negotiable)

1. Text ≥ 4.5 : 1, UI components ≥ 3 : 1, in both themes.
2. Hit areas ≥ 48 × 48 dp, including board handles at any zoom.
3. No fixed-height containers holding text; verified at 100/130/200 % font scale.
4. Semantics labels and roles on cards, nav slots, FAB, checkboxes, board nodes (text + shape + colour name) and connectors.
5. Colour is never the only signal (palette names exposed; icons accompany states).
6. Reduce Motion respected.
7. Back gesture never intercepted at screen edges; predictive back supported.
8. Text selection works in Read mode across paragraphs (today only code blocks are selectable).

---

## 11. Technical constraints that shape design (summary; detail in `08`)

- Fonts and icons must be bundled assets (offline-first).
- Library and Search designs assume an indexed store (SQLite + FTS) and a derived task index.
- Board interactions assume the board refactor (indexed nodes, partial repaint, debounced save).
- Capture designs assume the Android handlers stop opening the editor and write to Inbox.
- Link UI assumes stable ids and rename propagation.
- Export UI assumes Markdown + JSON Canvas export (v1.1); JSON Canvas fidelity for typed shapes must be checked.
- Rust is **not** part of the plan (`08` §4); revisit only on a missed measured budget.

---

## 12. Decision log

Status values: **Open** (needs answer) · **Answered** (record answer and date).

| ID | Decision | Recommended default | Status |
|---|---|---|---|
| D1 | One organising model: links + tags + 1-level folders (A) vs sub-note tree (B) vs all three (C) | A, after a usage check | **Open** |
| D2 | Untouched empty draft on Back | Discard | **Open** |
| D3 | Data promise: "your files" vs "exportable" | Exportable (SQLite + export) | **Open** |
| D4 | Amend `AGENTS.md` locked decisions and stale claims | Amend (§13) | **Open** |
| D5 | Visual direction | A + B's press response + C's dark/board logic | **Open** |
| D6 | Retire Sticky and Clipboard types; migrate | Retire | **Open** |
| D7 | Desktop/tablet | Explore in Figma only | **Open** |
| D8 | Archive | Remove | **Open** |
| D9 | Mermaid scope | Flowchart render + convert-to-board; freeze rest | **Open** |
| D10 | Android Auto Backup | Decide explicitly (currently default-on) | **Open** |

---

## 13. Locked decisions and documentation that need correcting (after D4)

**Locked decisions (from `AGENTS.md` §0) — status**
| # | Decision | Status in this design |
|---|---|---|
| 1 | Notes view is grid only | **Kept.** Desktop list variant is explore-only and needs D4 |
| 2 | No redundant buttons | **Kept and enforced**; audit lists 10 violations (`03` §6) |
| 3 | Home → Read → Edit | **Kept** (Today/Library → Read → Edit) |
| 4 | Single source of design tokens | **Kept**; today 344 hard-coded colours and 279 inline styles break it |
| 5 | Append future decisions | Use §12 |

**Statements that do not match the code (correct when D4 is answered; not changed here):**
| File | Claim | Reality |
|---|---|---|
| `AGENTS.md`, `README.md`, `.agents/rules/project_context.md` | Icons via `heroicons`/`HeroIcons` | Lucide + custom SVG; `heroicons` not a dependency |
| `AGENTS.md` §2, §4 | `EditorAppBar`, `CanvasAppBar`, `CanvasToolRail`, `CanvasNodePalette`; screens `sticky_board`, `clipboard` | Classes and screens do not exist |
| `AGENTS.md` §1 | Palette values and names (e.g. Peach `#FF8F6B`, Slate in set) | Code uses different hexes; Slate not in presets; two near-duplicate pairs |
| `AGENTS.md` §3 | `IStorageDriver` is the storage abstraction | Declared, never used |
| `README.md`, About screen | "Atomic JSON file persistence" | One JSON string in `SharedPreferences` |
| `README.md`, About screen | README: "Flutter ^3.13.1"; About: "Flutter SDK 3.29.0" | `pubspec.yaml` constrains the **Dart** SDK to `^3.13.1`; the three statements disagree and none names the actual Flutter version used |
| Release notes | "Grid ↔ List switcher on Home" | Removed per Locked Decision #1 |
| `AUDIT.md` | SQLite, `MainNavigationShell`, `HomeViewMode`, `SmartNoteListCard` | None exist; test compile errors are fixed |
| Welcome note | "Tap (+) and pick … Clip" | Create sheet offers Note, Sticky, Whiteboard |

---

## 14. Content and voice

- Plain, short, active. Sentence case. No exclamation marks.
- No emoji in chrome (current: 👋, ⚡, ☀️ in greeting and chips). Emoji remain a **user-chosen note icon** only.
- Empty states state what the place is for and offer one action.
- Errors name the problem, what is safe, and the next step. Example: "Couldn't save. Your last saved version is safe. Retry."
- Destructive toasts say what happened and offer **Undo**.
- Settings contain only settings (not status messages).

---

## 15. Open questions and validation plan

| Question | Evidence needed | Plan |
|---|---|---|
| Do people use boards, stickies, clips? | Counts of items by type | Read-only script on 5–10 exports |
| Is Inbox valuable or an extra chore? | Captured vs. opened-within-24 h | Prototype test + optional local counter |
| Do organising systems overlap in practice? | `parentId`, folder, tag counts | Same script |
| Is the Today-first launch right? | First-tap behaviour | Figma prototype, 5 sessions |
| Which board interaction fails first? | Task timing | Build-a-12-node-flow task |
| Does Mermaid get used beyond flowcharts? | Fence-type counts | Same script |

---

## 16. Document map

| # | Document | Question it answers |
|---|---|---|
| 01 | `01-product-analysis.md` | What is Tack, who is it for, what is real |
| 02 | `02-competitor-analysis.md` | What to borrow and avoid from Notion, Obsidian, Figma/FigJam |
| 03 | `03-existing-ui-audit.md` | Every screen/component, with verdicts |
| 04 | `04-feature-strategy.md` | What to build, in what order |
| 05 | `05-information-architecture.md` | How it is organised and how people move |
| 06 | `06-design-directions.md` | Three visual directions |
| 07 | `07-design-system.md` | Tokens and components |
| 08 | `08-technical-architecture-review.md` | Architecture, risks, Rust |
| 09 | `09-redesign-roadmap.md` | How to run the redesign |
| 10 | `10-design.md` | This file |

**Change log**
- v0.1 — first consolidation after the analysis phase.
