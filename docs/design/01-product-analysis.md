# 01 — Product Analysis

> Research and analysis only. No application code was changed to produce this document.
>
> Evidence labels used in every document in this folder:
> **[Verified]** = read in the code or fetched from a primary source during this review.
> **[Inferred]** = reasoned from code that was read but not run.
> **[Hypothesis]** = a product or design bet that needs validation.

---

## 1. What Tack actually is today

### 1.1 The one-paragraph truth

Tack is a **local-first, Android-only Markdown notebook with a flowchart whiteboard attached**. Its centre of gravity is the note editor and the linking layer around it (wiki links, backlinks, a graph, frontmatter, templates, daily notes). Around that sits an unusually deep Android capture surface (share target, text-selection action, Quick Settings tile, home widget, launcher shortcuts, "open .md file"). "Sticky notes", "clipboard" and "tasks" exist as labels and data types, but **not as distinct products**.

### 1.2 Evidence

| Fact | Evidence |
|---|---|
| ~32.8k lines across `lib/` and `android/app/src`; the four biggest files are `whiteboard_canvas_screen.dart` (5,139), `note_editor_screen.dart` (2,731), `rich_note_content_view.dart` (2,032), `mermaid_diagram_card.dart` (1,690) | [Verified] `wc -l` |
| Git history runs 2026-09-01 → 2026-11-03; version `2.0.0+2` | [Verified] `git log`, `pubspec.yaml` |
| Four item types: `note`, `sticky`, `whiteboard`, `clipboard`, all subclasses of `BaseWorkspaceItem` | [Verified] `lib/domain/models/base_item.dart` |
| Persistence = one JSON string in `SharedPreferences` (`tack_workspace_items_v2`), rewritten in full on every save | [Verified] `workspace_repo_impl.dart:16, 131-141` |
| Windows and web folders exist but contain only the stock Flutter runner; the UI has no responsive layout code | [Verified] directory listing; [Inferred] from absence of `LayoutBuilder` in screens |
| None of the bottom-bar tabs is its own route: "Home", "Notes", "Whiteboard" and "Clipboard" are **filters on the same Home screen** | [Verified] `home_screen.dart:174-197` |
| No sticky-board screen and no clipboard screen exist, despite `AGENTS.md` listing them | [Verified] `lib/ui/screens/` has only `editor, folders, graph, home, settings, whiteboard` |
| No task model, due dates or reminders. "Tasks" = Markdown `[ ]` checkboxes inside notes | [Verified] grep for `Task`, `dueDate` found nothing |
| No class or screen called "Smart Actions Menu" | [Verified] grep |
| Brand icon is saturated red with a paper mascot; **the app UI contains no brand red** (primary is ink, accents are pastels) | [Verified] `icon.png` vs `app_colors.dart` |

### 1.3 What each historical concept became

| Historical concept | What exists in code | Honest status |
|---|---|---|
| **Sticky Notes** | `StickyNote` model (content, `rotationAngle`, `priority`) and `StickyNoteCard`. Created from the (+) sheet, edited in the *same* editor as notes. | A note with a different card. No board, no stacking, no reminders. Priority is stored but not surfaced as a control. |
| **Whiteboard** | A real 6000×6000 canvas with 9 node types, orthogonal connectors, auto-arrange, minimap, PNG/JPG/PDF export, spec cards that link to notes. | **The most distinctive and most complete surface**, but built as a 4,700-line single widget with no automated tests. |
| **Clipboard** | `ClipboardItem` and a card with a Copy pill. Items arrive via a manual "Save from Clipboard" dock or the Android share path. | A saved-snippet list. **It is not a clipboard manager**; there is no background capture. Android 10+ restricts clipboard reads to the foreground app or the default keyboard [Inferred from platform knowledge, not re-verified here]. |
| **Tasks** | Checkbox lines in Markdown; tap-to-toggle in Read mode; Daily Note carries unchecked `- [ ]` items forward from the previous daily note; a home widget button creates a note pre-filled with three `[ ]` lines. | Tasks are text. Nothing aggregates them. |
| **Smart Actions Menu** | Closest equivalents: the slash/“Turn into” sheet (17 commands), the long-press `NoteActionSheet`, the Quick Settings tile and widget buttons. | Not a single coherent concept. Three separate action surfaces. |

---

## 2. Why each feature exists (reconstructed intent)

This is reconstructed from code, templates, release notes and commit messages. It is not interview data.

| Feature | Probable reason it was built | Problem it addresses |
|---|---|---|
| Android capture ingress (share, process-text, tile, widget, shortcuts, `.md` open) | Original Java project grew into a phone-first tool; the developer wanted capture to be one gesture away | "I saw/thought something and the app is three taps away." |
| Markdown + Read/Edit modes | Writing without a block editor's friction; Read mode makes notes feel finished | Plain notes that still render nicely on a phone |
| Wiki links, backlinks, unlinked mentions, graph | Obsidian-style connected thinking | Notes become a web, not a pile |
| Frontmatter properties (status, priority, target date) | Notion-style structure without a database | Lightweight metadata on specs |
| Templates (PRD/spec, design rulebook, decision log, meeting notes, Cornell) | Developer is producing specs and decisions, not just journalling | Starting a structured document from a blank screen |
| Daily note + carry-forward tasks | Daily-note habit from Obsidian/Logseq | Continuity day to day |
| Whiteboard + spec cards + `![[Board]]` embeds | Flowchart thinking tied to written specs | "My diagram and my spec live in different apps." |
| Mermaid rendering + convert-to-board | Developers already write Mermaid | Text → diagram without leaving the note |
| Colour palettes (8 pastels) | "Tactile" brand personality | Visual differentiation of items |

**Observation [Verified]:** the templates and features skew strongly toward **specification, decision and flow thinking** (PRD, design rulebook, decision log, flowcharts, Mermaid), not toward generic journalling or shopping lists. That is the real, already-built niche.

---

## 3. Working state: complete, incomplete, broken

Full evidence is in `03-existing-ui-audit.md`. Headline items:

**Complete and solid**
- Read → Edit → back chain (`PopScope` + `_handleBackPress`), autosave on a 600 ms debounce.
- Wiki-link resolution (id → title → alias), backlinks, unlinked mentions with "convert to link".
- Whiteboard CRUD, connectors, auto-arrange, export.
- Android intent plumbing (Kotlin → one `MethodChannel`).

**Half-built or dead**
- **Archive can never be populated**: `toggleArchive` exists in the provider and repo, but no UI calls it. The drawer still shows "Archive". [Verified by grep]
- **Quick-capture notification can never be switched on**: `setQuickCaptureEnabled(true)` is only called to re-sync an already-true preference; no setting writes it. [Verified]
- `IStorageDriver` is declared in `AGENTS.md` as an architectural pillar, but is never implemented or imported. [Verified]
- Whiteboard viewport (`zoomScale`, `panOffset`) is in the model but never saved. Snap-to-grid has no UI. `isPrint` export path is unreachable.
- Mermaid pan/zoom is wrapped in `IgnorePointer` and can never receive gestures.

**Likely wrong (data-safety class)**
- **Backups can silently omit data.** `exportWorkspaceJson()` serialises `_items`, but `loadItems()` overwrites `_items` with the *currently filtered* list (category or search). Export while on the Whiteboard tab, or mid-search, and you back up a subset. Trash and archive are never exported at all. [Verified in `workspace_provider.dart:116-126, 736-751`]
- **Today's Note can overwrite itself** when opened from a filtered category, because the lookup also reads `_items`. [Inferred from the same mechanism]
- **Renaming a note breaks inbound `[[links]]`** because links are stored as title text and no rename propagation exists. [Verified absence by grep]
- **Edits in the last 600 ms before the app is backgrounded may be lost**: no lifecycle flush hook in the editor. [Inferred]

**Documentation drift** (important for anyone onboarding): `AGENTS.md`, `README.md` and `.agents/rules/project_context.md` claim `heroicons`, a sticky board, a clipboard screen, `EditorAppBar`/`CanvasAppBar`/`CanvasToolRail` classes, and "atomic JSON file persistence". None of these match the code. `AUDIT.md` describes a SQLite store, a `MainNavigationShell` and a list-view toggle that no longer exist. Release notes still advertise a "Grid ↔ List switcher", contradicting Locked Decision #1. [All Verified]

---

## 4. Provisional audience

> **Confidence: low.** The `ux-researcher-designer` skill in `.agents/` requires 20+ users and two data sources before calling something a persona. There is no usage data and no interviews. The two profiles below are **design hypotheses** to be validated, not findings.

### Persona hypothesis A — "The spec-and-flow thinker" (primary)
- **Who:** a student, junior engineer or designer on Android who writes specs, decisions and diagrams for their own projects.
- **Evidence from the product:** PRD/spec, design-rulebook and decision-log templates; Mermaid; flowchart nodes named Start/End, Process, Decision, I/O; spec cards that pin a note into a diagram.
- **Job to be done:** *"Turn a half-formed idea into a written spec and a diagram that point at each other, from my phone, without an account."*
- **Frustration today (with generic tools):** the diagram lives in one app, the spec in another, and neither links to the other.

### Persona hypothesis B — "The capture-everything Android user" (secondary)
- **Who:** someone who reads a lot on their phone and wants to save text and links from other apps.
- **Evidence:** share target for text, markdown and images; "Save to Tack" text-selection action; Quick Settings tile; widget; `.md` file opening.
- **Job to be done:** *"Save this now, make sense of it later."*
- **Frustration today:** capture lands directly in a full editor as a new note, so everything becomes an unfiled note. There is no "inbox" state.

### What to validate before Figma is finalised
1. Do users create boards at all, or notes only? (The embedded usage data does not exist; add privacy-respecting local counters or run 5 moderated sessions.)
2. Do stickies differ from short notes in practice?
3. Is Read mode where people spend their time, or is it a speed bump?
4. How many items does a heavy user have? (Drives storage and performance decisions.)

---

## 5. Positioning

### 5.1 What Tack should not be
- **Not Notion:** no workspace collaboration, no databases-as-product, no permissions, no AI sidebar. Those are Notion's moat and a one-person project cannot out-build them. (Verified Notion capabilities are in `02-competitor-analysis.md`.)
- **Not Obsidian:** no plugin ecosystem, no desktop-first vault-of-files philosophy as the headline. Obsidian's mobile app already exists and is free. [Verified: obsidian.md/mobile]
- **Not FigJam:** no real-time multiplayer, no workshop tools (timer, voting, stamps).

### 5.2 Where the gap actually is [Hypothesis, grounded in what already exists]

> **Tack is a phone-native thinking pad where a written spec and a flow diagram are the same object graph.**

The only things in the combined Notion/Obsidian/FigJam set that Tack does *by construction* and the others do not do on a phone, without setup:

1. **Capture from anywhere in Android** with zero account and zero network (Android intents are first-class, not an afterthought).
2. **Note ↔ board linking as a primary feature:** a board node can *be* a note (spec card); a note can embed a board node (`![[Board#node]]`); both resolve through the same link service.
3. **Diagram from text:** Mermaid fence → renderable → one tap into an editable board.

Obsidian has Canvas, where cards can be notes, and Canvas views can be embedded in notes [Verified: obsidian.md/canvas]. So (2) is not unique in principle. The gap is that **Obsidian Canvas is a general layout tool; Tack's board is a typed flowchart** (Start/End, Process, Decision, I/O with orthogonal connectors and auto-arrange). That specificity, packaged for touch, is the differentiation.

### 5.3 Proposed product sentence [Hypothesis]

> **Tack — pin your thinking down.** Capture a thought in one tap, shape it into a linked note, lay it out as a flow, and carry the open tasks into tomorrow. Everything stays on your phone.

### 5.4 The journey, made practical

The brief proposed **CAPTURE → EXPLORE → CONNECT → BUILD → EXECUTE → REFLECT**. Mapped onto what exists and what is missing:

| Stage | What the user does | Exists today | Gap |
|---|---|---|---|
| **Capture** | Drop a thought in under 3 seconds | Tile, widget, share, shortcut, (+) FAB | All routes create a *finished note and open the editor*; no unprocessed state |
| **Explore** | Re-find and browse what I have | Search (title + 90-char summary + tags), folders, tags, graph | Search does not index note bodies; folders/tags/sub-notes are three overlapping systems |
| **Connect** | Link ideas | `[[ ]]`, backlinks, unlinked mentions, graph, sub-notes | Rename breaks links; graph is O(N²) on the UI thread |
| **Build** | Shape into a spec or diagram | Templates, frontmatter, tables, Mermaid, whiteboard, spec cards | Editor and board each carry their own chrome and dialogs |
| **Execute** | Do the work | Checkboxes, daily note carry-forward | No cross-note task view, no "today" surface |
| **Reflect** | See what changed, decide what to drop | Templates (decision log, Cornell) only | No timeline, no review, no resurfacing |

The investment case: **Capture and Execute have the largest gaps and the smallest engineering cost**, because the data already exists in Markdown. Reflect is real but can wait. See `04-feature-strategy.md`.

---

## 6. Differentiation test

A feature earns its place in Tack only if it passes at least two of these:

1. **Android-native advantage** — uses an intent, widget, tile or share path other note apps treat as secondary.
2. **Note ↔ spatial link** — strengthens the connection between written and diagrammatic thinking.
3. **Local-first trust** — works offline, owns its data, exports to open formats.
4. **Phone-ergonomic** — better with one thumb than the desktop-first alternative.

Applied to the historical concepts: Sticky as a separate object fails 1–4 (it is a note with a colour). Clipboard-as-manager fails 1 (platform blocks it) and 4. Whiteboard passes 2, 3, 4. Capture ingress passes 1, 3, 4. Daily note + task carry-forward passes 3, 4.

---

## 7. Open product questions that block the redesign

| # | Question | Why it matters | Who decides |
|---|---|---|---|
| 1 | Is Tack Android-only for the next 12 months, or is desktop a real target? | Drives layout system (single-column vs 3-pane), input model (touch vs keyboard), and whether Windows scaffolding is kept | Product owner |
| 2 | Are `AGENTS.md` locked decisions open for revision as part of the redesign? (e.g. #1 grid-only, DM Sans, 8 pastels) | A table/list view or a desktop sidebar contradicts Locked Decision #1 | Product owner |
| 3 | Should the data model stay one JSON blob, or move to a database plus Markdown export? | Affects backup reliability, search, and scale | Engineering + product |
| 4 | Is "Sticky" a distinct user-facing thing worth keeping? | Determines whether it is an item type, a note colour/size, or removed | Product owner after 3–5 user conversations |
| 5 | Should the app brand use the icon's red? | Currently the identity (red mascot) and the UI (ink + pastel) disagree | Design |
