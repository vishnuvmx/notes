# 11 — Reference UI Style Analysis ("Soft Monochrome Mobile")

Source: 5 reference screenshots — *Regent* (payment app onboarding), *DailyLoop* (welcome + to-do), *Joi Planner* (App Store cards), *Design Ideas* (timestamped note with audio), *MyNote* (sticky/pinned notes).
Hex codes are visual estimates, not sampled values. They are the starting point for tokens in `lib/core/theme/`.

> Fit with Tack: this is close to Direction A ("Paper & Pin"). It confirms neutral chrome, ink primary buttons and sparing color. Adopt via tokens only (see §7) and respect the Locked Product Decisions in `AGENTS.md` (grid only, no redundant buttons, no hardcoded values).

---

## 1. Colors

| Role | Estimate | Notes |
|---|---|---|
| Canvas (screen bg) | `#F2F2F2` – `#F5F5F5` | Cool-neutral light gray; the whole screen is one soft tone |
| Surface (cards, sheets, inputs) | `#FFFFFF` | Floats above the canvas, separated by soft shadow, not borders |
| Sunken / inactive fill | `#EBEBEB` – `#EFEFEF` | Segmented control track, inactive chips, selected-day pill |
| Primary text | `#111111` – `#1A1A1A` | Near-black |
| Secondary text | `#6B6B6B` – `#8A8A8A` | Subtitles, descriptions, inactive tabs |
| Tertiary / disabled | `#B5B5B5` – `#C8C8C8` | Past dates, placeholder, faded lines (fade-out at list ends) |
| Primary action | `#111111` fill, `#FFFFFF` text | Full-width "Get started", FAB "+" |
| Brand accent (Regent) | Coral red `#EF5B5B` – `#F0605D` | Logo, "Login" link only |
| Soft accent tints | Peach `#FDE3E0`, pink `#FCE4EC`, mint/blue `#E3F0FF` | Chip/highlight backgrounds with darker same-hue text |
| Highlights (notes) | Blue underline-dash `#2F80ED` on `#E6F0FD`; red on `#FBE0E3` | Inline text highlights |
| Sticky pastels | Yellow `#FFE95C`, orange `#F9B85C`, green `#B9F08A` | Only on sticky objects |
| Dark variant (Joi) | `#0F0F10` canvas, white card | Appears for "habits" panel; dark mode is inverted surfaces |

Principles: **chrome is neutral grayscale; color lives on content objects and tiny status chips**. One accent hue per product. Tints always pair a pale background with a saturated text of the same hue.

## 2. Typography

- **Family:** clean geometric/neo-grotesque sans (Inter / SF Pro / Geist-like). Tack's `DM Sans` is a good match.
- **Editorial accent:** italic serif for personality (`Let's make progress today!`, "Today's Overview", "Design Ideas" serif-feel). Matches Tack's `Newsreader`.
- **Handwritten / mono accent (MyNote):** script for sticky text, monospace for buttons/labels ("Pin this", "Edit", timestamps `00:30`). Use mono only for metadata (Tack: `JetBrains Mono`).

| Level | Size / weight | Use |
|---|---|---|
| Display | 32–40sp, 700, tight tracking (−2%) | Marketing hero, large clock "9:41" |
| Screen title | 24–28sp, 700 | "Design Ideas", "Welcome to DailyLoop!" |
| Section head | 15–16sp, 600 | "Morning", "Workload", "Night" |
| Body / row | 14–16sp, 400–500 | Task rows, note text |
| Secondary | 12–14sp, 400, gray | Descriptions, legal text |
| Caption / meta | 11–12sp, 500, gray or mono | Dates, "1h" badges, word counts |
| Button label | 15–16sp, 600 | White on black |

Hierarchy is made with **weight and gray value**, not size alone: key phrase is bold black, continuation is the same sentence in gray ("**Quick & easy.** Make secure, fast and simple payments.").

## 3. Layout

- **Screen gutter:** 16–20dp. Content cards inset ~12–16dp from the edges.
- **Spacing rhythm:** 4/8-based; 8dp inside rows, 12–16dp between cards, 24–32dp between major blocks.
- **Alignment:** left-aligned lists and titles; onboarding is centered with a single column.
- **Density:** airy and low-density; one main idea per screen. Rows ~40–48dp tall in lists with generous whitespace.
- **Structure:** stacked rounded cards on a gray canvas (header chip row → week strip → card with segmented control → grouped checklist).
- **Bottom area:** floating pill nav (Home / Insights / Profile) with a detached circular FAB to its right; nothing glued to the screen edge.
- **Timeline pattern (Design Ideas):** left rail with mono timestamps + vertical line + dot; text blocks on the right; list fades to the background at the bottom.

## 4. Components

- **Primary button:** full-width, black fill, white text, radius ~14–16dp (not full pill), height ~52–56dp.
- **Secondary action:** plain text button, centered ("Already a user? Log in"); text link in accent color top-right ("Login").
- **FAB:** 56dp black circle, white "+" icon.
- **Cards:** white, radius 16–24dp, no border, soft diffused shadow (blur ~20, y 4–8, alpha ~0.06–0.10). Sub-cards (task block) use a pale tint and a 3dp leading accent bar.
- **Stacked/peeking cards:** layered cards with slight offset and scale to imply a deck (Regent notification, DailyLoop overview, MyNote stack).
- **Segmented control:** gray track, selected segment = black pill with white text and small leading icon; unselected = gray text.
- **Week strip:** pill container; selected day has a light gray rounded square, bold number; other days are gray.
- **Checklist rows:** square outlined checkbox (radius ~4dp), emoji as leading glyph, 14–15sp text; collapsible section header with a small caret.
- **Chips / badges:** small pills (radius 999), tinted background + same-hue text, 11–12sp ("1h", "35m", "Now", "Family", "300 Words").
- **Inline highlights:** rounded rect background tint; blue variant has a dashed outline; contextual mini-toolbar (Family | Copy | Share) as a white rounded bar with dividers.
- **Audio/player bar:** floating white pill with black circular play button, thin progress line with colored markers, mono time.
- **Icons:** thin outline, rounded caps, ~20dp, monochrome gray or black; emoji for friendly content icons; small solid brand mark.
- **Inputs/toolbars:** icon-only header buttons (search, settings) on the canvas, no boxed outline.
- **Page indicator:** 3 dots, active = black, inactive = light gray.
- **Legal footer:** 11–12sp gray with underlined links.

## 5. Overall Vibe

Minimal, calm, tactile, **soft monochrome with one warm accent**. Paper-like (grid paper, sticky notes, ring binders, pins) with a premium app-store polish. Light mode is primary; dark is a clean inversion. Playfulness is limited to emoji, a serif italic, handwritten fonts and layered cards, not color. It is not glassmorphism (only the lock-screen widgets in Joi use glass).

## 6. Do / Don't

- Do: soft shadows, rounded cards, gray-on-gray hierarchy, black primary buttons, tinted chips, floating nav.
- Do: use fade-out gradients on scroll ends instead of hard cut-offs.
- Don't: hard borders around cards, saturated backgrounds for chrome, multiple accent colors, heavy gradients, text below 12sp.

## 7. Mapping to Tack Design Tokens (proposal, no code changes made)

| Reference | Tack token |
|---|---|
| Canvas `#F2F2F2` | `bgCanvas` (already warm `#F7F6F3`; keep) |
| Card white | `bgSurface` |
| Track / inactive | `bgSunken` |
| Ink black button | `actionPrimary` / `onActionPrimary` |
| Coral accent | `accentPin` (`#D92D20`) |
| Tint chips | `TackColorPalette.softBackground` + `indexColor` |
| Card shadow | `AppSpacing.elev1(isDark)` |
| Card radius 16–24 | `radiusLg` (16) and sheet radius |
| Serif italic accent | `AppTypography.display` (Newsreader) |
| Mono metadata | `AppTypography.mono` |

Candidate additions (need your approval since they would change product decisions or add UI):

1. Floating pill bottom nav with detached capture FAB (currently a docked 5-slot bar).
2. Segmented control (`To do / Completed / Pending`) on Today's Open Tasks.
3. Week strip on Today.
4. Leading accent bar on task/peek cards (Tack cards already use a 6dp band).
5. Timestamp rail and inline highlight toolbar in Read mode (only if audio/time features are in scope; Tack currently has none).
6. Stacked "deck" visual for Inbox triage (already a card stack).

